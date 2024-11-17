// main.dart

import 'package:bloom_and_shroom_spa/models.dart';
import 'package:bloom_and_shroom_spa/realtime_graph.dart';
import 'package:bloom_and_shroom_spa/service.dart';
import 'package:flutter/material.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_browser_client.dart';
import 'dart:async';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bloom & Shroom',
      theme: ThemeData(primarySwatch: Colors.green),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  MyHomePageState createState() => MyHomePageState();
}

class MyHomePageState extends State<MyHomePage> {
  final String broker = '192.168.0.192'; // Replace with your broker's IP
  final String clientId = 'flutter_client';
  final String temperatureTopic = 'sensor/temperature';
  final String ledControlTopic = 'control/led';
  final String takePhotoTopic = 'control/takephoto';
  final String photoUrlTopic = 'photos/latest';

  MqttBrowserClient? client;
  String temperature = 'Loading...';
  bool ledOn = false;
  String? latestPhotoUrl;

  List<TemperatureData> lastMinuteData = [];
  List<TemperatureData> lastHourData = [];
  List<TemperatureData> aggregatedHourData = [];

  final ApiService apiService = ApiService(
      baseUrl: 'http://192.168.0.192:8000'); // Replace with your FastAPI URL

  Timer? aggregationTimer;

  bool isLoading = true;
  String? errorMessage;
  Timer? oneMinuteUpdateTimer;
  Timer? fiveMinuteUpdateTimer;
 @override
  void initState() {
    super.initState();
    fetchInitialData();
    connectToBroker();

    // Timer to update last minute data every minute
    oneMinuteUpdateTimer = Timer.periodic(Duration(minutes: 1), (timer) async {
      try {
        List<TemperatureData> minuteData =
            await apiService.fetchLastMinuteData();
        setState(() {
          lastMinuteData = minuteData;
        });
      } catch (e) {
        debugPrint('Error updating last minute data: $e');
      }
    });
Future<void> fetchAllData() async {
    try {
      final minuteData = await apiService.fetchLastMinuteData();
      final hourData = await apiService.fetchLastHourData();
      setState(() {
        lastMinuteData = minuteData;
        lastHourData = hourData;
      });
    } catch (e) {
      debugPrint('Error fetching data: $e');
    }
  }
    // Timer to update last hour data every 5 minutes
    fiveMinuteUpdateTimer = Timer.periodic(Duration(minutes: 5), (timer) async {
      try {
        List<TemperatureData> hourData = await apiService.fetchLastHourData();
        setState(() {
          lastHourData = hourData;
          aggregateLastHourData();
        });
      } catch (e) {
        debugPrint('Error updating last hour data: $e');
      }
    });
  }
  @override
  void dispose() {
    aggregationTimer?.cancel();
    oneMinuteUpdateTimer?.cancel();
    fiveMinuteUpdateTimer?.cancel();
    client?.disconnect();
    super.dispose();
  }

  Future<void> fetchInitialData() async {
    try {
      List<TemperatureData> minuteData = await apiService.fetchLastMinuteData();
      List<TemperatureData> hourData = await apiService.fetchLastHourData();
      setState(() {
        lastMinuteData = minuteData;
        lastHourData = hourData;
        aggregateLastHourData(); // Initial aggregation
        isLoading = false;
      });
    } catch (e) {
      debugPrint('Error fetching initial data: $e');
      setState(() {
        errorMessage = 'Failed to load temperature data.';
        isLoading = false;
      });
    }
  }

   Future<void> connectToBroker() async {
    client = MqttBrowserClient('ws://$broker', clientId);
    client!.port = 8080; // Ensure this matches your WebSocket port
    client!.logging(on: true);
    client!.setProtocolV311();
    client!.keepAlivePeriod = 20;
    client!.onDisconnected = onDisconnected;

    client!.onConnected = onConnected;
    client!.onSubscribed = onSubscribed;

    final connMess = MqttConnectMessage()
        .withClientIdentifier(clientId)
        .startClean()
        .withWillQos(MqttQos.atMostOnce);
    client!.connectionMessage = connMess;

    try {
      await client!.connect();
    } catch (e) {
      debugPrint('Error connecting to broker: $e');
      client!.disconnect();
    }

    if (client!.connectionStatus!.state == MqttConnectionState.connected) {
      debugPrint('Connected to MQTT broker');

      // Subscribe to necessary topics
      client!.subscribe(temperatureTopic, MqttQos.atMostOnce);
      client!.subscribe(photoUrlTopic, MqttQos.atMostOnce);

      client!.updates!.listen((List<MqttReceivedMessage<MqttMessage>> c) {
        final MqttPublishMessage message = c[0].payload as MqttPublishMessage;
        final payload =
            MqttPublishPayload.bytesToStringAsString(message.payload.message);
        final topic = c[0].topic;

        if (topic == temperatureTopic) {
          setState(() {
            temperature = payload;
          });
        } else if (topic == photoUrlTopic) {
          setState(() {
            latestPhotoUrl = payload;
          });
        }
      });
    } else {
      debugPrint('Failed to connect to MQTT broker');
    }
  }

  void onConnected() {
    debugPrint('Connected callback');
  }

  void onSubscribed(String topic) {
    debugPrint('Subscribed to $topic');
  }

  void onDisconnected() {
    debugPrint('Disconnected from MQTT broker');
    setState(() {
      errorMessage = 'Disconnected from MQTT broker.';
    });
  }

  void toggleLed() {
    if (client != null &&
        client!.connectionStatus!.state == MqttConnectionState.connected) {
      final payload = ledOn ? 'off' : 'on';
      client!.publishMessage(
        ledControlTopic,
        MqttQos.atMostOnce,
        MqttClientPayloadBuilder().addString(payload).payload!,
      );
      setState(() {
        ledOn = !ledOn;
      });
    }
  }

  void requestPhoto() {
    if (client != null &&
        client!.connectionStatus!.state == MqttConnectionState.connected) {
      client!.publishMessage(
        takePhotoTopic,
        MqttQos.atMostOnce,
        MqttClientPayloadBuilder().addString('takephoto').payload!,
      );
      debugPrint('Published takephoto command');
    }
  }

  void aggregateLastHourData() {
    if (lastHourData.isEmpty) return;

    // Sort data by timestamp
    lastHourData.sort((a, b) => a.timestamp.compareTo(b.timestamp));

    // Aggregate into 5-minute intervals
    Map<DateTime, List<double>> intervals = {};

    for (var data in lastHourData) {
      DateTime intervalStart = DateTime(
        data.timestamp.year,
        data.timestamp.month,
        data.timestamp.day,
        data.timestamp.hour,
        (data.timestamp.minute ~/ 5) * 5,
      ).toUtc();

      if (!intervals.containsKey(intervalStart)) {
        intervals[intervalStart] = [];
      }
      intervals[intervalStart]!.add(data.temperature);
    }

    List<TemperatureData> newAggregatedData = [];

    intervals.forEach((key, value) {
      double avgTemp = value.reduce((a, b) => a + b) / value.length;
      newAggregatedData.add(TemperatureData(
        temperature: avgTemp,
        timestamp: key,
      ));
    });

    // Sort aggregated data
    newAggregatedData.sort((a, b) => a.timestamp.compareTo(b.timestamp));

    setState(() {
      aggregatedHourData = newAggregatedData;
    });
  }

  Widget buildPhotoSection() {
    if (latestPhotoUrl != null) {
      return Column(
        children: [
          Image.network(
            latestPhotoUrl!,
            height: 200,
            width: 200,
            fit: BoxFit.cover,
          ),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: () {
              // Handle download if needed
              // For example, open the URL in a browser
            },
            child: const Text('Download Photo'),
          ),
        ],
      );
    } else {
      return const Text('No photo available');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bloom & Shroom Dashboard')),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : errorMessage != null
              ? Center(child: Text(errorMessage!))
              : SingleChildScrollView(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 20),
                          const Text(
                            'Current Temperature:',
                            style: TextStyle(fontSize: 20),
                          ),
                          Text(
                            temperature,
                            style: const TextStyle(
                                fontSize: 32, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton(
                            onPressed: toggleLed,
                            child: Text(ledOn ? 'Turn LED Off' : 'Turn LED On'),
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton(
                            onPressed: requestPhoto,
                            child: const Text('Take Photo'),
                          ),
                          const SizedBox(height: 20),
                          buildPhotoSection(),
                          const SizedBox(height: 40),
                          const Text(
                            'Temperature - Last Minute',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          SizedBox(
                            height: 200,
                            child: RealTimeGraph(data: lastMinuteData),
                          ),
                          const SizedBox(height: 40),
                          const Text(
                            'Temperature - Last Hour (5-Minute Intervals)',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          SizedBox(
                            height: 200,
                            child: HistoricalGraph(data: aggregatedHourData),
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                ),
    );
  }
}
