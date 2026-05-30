import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class DonutData {
  final String label;
  final double value;
  final Color color;

  DonutData({required this.label, required this.value, required this.color});
}

class DonutChart extends StatelessWidget {
  final List<DonutData> data;
  final double radius;

  const DonutChart({super.key, required this.data, this.radius = 60});

  @override
  Widget build(BuildContext context) {
    final total = data.fold(0.0, (sum, item) => sum + item.value);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: radius * 3,
          child: PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: radius * 0.5,
              sections: data.map((e) {
                final percent = (e.value / total) * 100;

                return PieChartSectionData(
                  value: e.value,
                  color: e.color,
                  title: "${percent.toStringAsFixed(1)}%",
                  radius: radius,
                  titleStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                );
              }).toList(),
            ),
          ),
        ),

        const SizedBox(height: 10),

        // Leyenda
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          spacing: 10,
          children: data.map((e) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 10, height: 10, color: e.color),
                const SizedBox(width: 5),
                Text(e.label),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }
}
