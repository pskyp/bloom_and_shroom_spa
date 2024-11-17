import 'package:bloom_and_shroom_spa/models.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class RealTimeGraph extends StatelessWidget {
  final List<TemperatureData> data;

  const RealTimeGraph({Key? key, required this.data}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    List<FlSpot> spots = data
        .map((d) => FlSpot(
              d.timestamp.millisecondsSinceEpoch.toDouble(),
              d.temperature,
            ))
        .toList();

    if (spots.isEmpty) {
      spots.add(FlSpot(0, 0));
    }

    double minX = data.first.timestamp.millisecondsSinceEpoch.toDouble();
    double maxX = data.last.timestamp.millisecondsSinceEpoch.toDouble();
    double minY =
        data.map((d) => d.temperature).reduce((a, b) => a < b ? a : b) - 0.5;
    double maxY =
        data.map((d) => d.temperature).reduce((a, b) => a > b ? a : b) + 0.5;

    return LineChart(
      LineChartData(
        minX: minX,
        maxX: maxX,
        minY: minY,
        maxY: maxY,
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 22,
              getTitlesWidget: (value, meta) {
                DateTime time =
                    DateTime.fromMillisecondsSinceEpoch(value.toInt());
                return Text(
                  '${time.hour}:${time.minute.toString().padLeft(2, '0')}',
                  style: TextStyle(fontSize: 10),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toStringAsFixed(1),
                  style: TextStyle(fontSize: 10),
                );
              },
            ),
          ),
          topTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false), // Hide top values
          ),
          rightTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false), // Hide right values
          ),
        ),
        gridData: FlGridData(show: true),
        borderData: FlBorderData(show: true),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            barWidth: 2,
            dotData: FlDotData(show: false),
          ),
        ],
      ),
    );
  }
}
class HistoricalGraph extends StatelessWidget {
  final List<TemperatureData> data;

  const HistoricalGraph({Key? key, required this.data}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    List<FlSpot> spots = data
        .map((d) => FlSpot(
              d.timestamp.millisecondsSinceEpoch.toDouble(),
              d.temperature,
            ))
        .toList();

    if (spots.isEmpty) {
      spots.add(FlSpot(0, 0));
    }

    double minX = data.first.timestamp.millisecondsSinceEpoch.toDouble();
    double maxX = data.last.timestamp.millisecondsSinceEpoch.toDouble();
    double minY =
        data.map((d) => d.temperature).reduce((a, b) => a < b ? a : b) - 0.5;
    double maxY =
        data.map((d) => d.temperature).reduce((a, b) => a > b ? a : b) + 0.5;

    return LineChart(
      LineChartData(
        minX: minX,
        maxX: maxX,
        minY: minY,
        maxY: maxY,
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 22,
              getTitlesWidget: (value, meta) {
                DateTime time =
                    DateTime.fromMillisecondsSinceEpoch(value.toInt());
                return Text(
                  '${time.hour}:${time.minute.toString().padLeft(2, '0')}',
                  style: TextStyle(fontSize: 10),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toStringAsFixed(1),
                  style: TextStyle(fontSize: 10),
                );
              },
            ),
          ),
          topTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false), // Hide top values
          ),
          rightTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false), // Hide right values
          ),
        ),
        gridData: FlGridData(show: true),
        borderData: FlBorderData(show: true),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            barWidth: 2,
            dotData: FlDotData(show: false),
          ),
        ],
      ),
    );
  }
}