class TemperatureData {
  final double temperature;
  final DateTime timestamp;

  TemperatureData({required this.temperature, required this.timestamp});

  factory TemperatureData.fromJson(Map<String, dynamic> json) {
    return TemperatureData(
      temperature: json['temperature'],
      timestamp: DateTime.parse(json['timestamp']),
    );
  }
}