import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class PieChartWidget extends StatelessWidget {
  final List<double> data;
  final List<String> labels;
  final String title;

  const PieChartWidget({
    Key? key,
    required this.data,
    required this.labels,
    required this.title,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final List<Color> colors = [
      Colors.blue.shade400,
      Colors.green.shade400,
      Colors.orange.shade400,
      Colors.purple.shade400,
      Colors.red.shade400,
      Colors.teal.shade400,
      Colors.pink.shade400,
      Colors.indigo.shade400,
    ];

    return AspectRatio(
      aspectRatio: 1.3,
      child: PieChart(
        PieChartData(
          sectionsSpace: 2,
          centerSpaceRadius: 40,
          sections: List.generate(data.length, (index) {
            final value = data[index];
            final total = data.reduce((a, b) => a + b);
            final percentage = (value / total * 100).toStringAsFixed(1);
            
            return PieChartSectionData(
              color: colors[index % colors.length],
              value: value,
              title: '$percentage%',
              radius: 80,
              titleStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                shadows: [
                  Shadow(
                    color: Colors.black26,
                    blurRadius: 2,
                  ),
                ],
              ),
              badgeWidget: _Badge(
                label: labels[index],
                color: colors[index % colors.length],
                size: 32,
              ),
              badgePositionPercentageOffset: 1.2,
            );
          }),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  final double size;

  const _Badge({
    required this.label,
    required this.color,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: PieChart.defaultDuration,
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 3,
            offset: const Offset(1, 1),
          ),
        ],
      ),
      padding: EdgeInsets.all(size * 0.15),
      child: Center(
        child: FittedBox(
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 10,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
} 