import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class StatCard extends StatefulWidget {
  final String title;
  final String value;
  final double growth;
  final List<double>? chartData;
  final Color? color;
  final IconData icon;

  const StatCard({
    Key? key,
    required this.title,
    required this.value,
    required this.growth,
    this.chartData,
    this.color,
    required this.icon,
  }) : super(key: key);

  @override
  State<StatCard> createState() => _StatCardState();
}

class _StatCardState extends State<StatCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmallScreen = constraints.maxWidth < 600;
        final cardPadding = isSmallScreen ? 16.0 : 24.0;
        final titleSize = isSmallScreen ? 14.0 : 16.0;
        final valueSize = isSmallScreen ? 20.0 : 24.0;
        
        return Container(
          padding: EdgeInsets.all(cardPadding),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A27),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(widget.icon, color: Colors.teal[400]),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.title,
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: titleSize,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              FadeTransition(
                opacity: _animation,
                child: Text(
                  widget.value,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: valueSize,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (widget.chartData != null && widget.chartData!.isNotEmpty) ...[
                const SizedBox(height: 20),
                SizedBox(
                  height: isSmallScreen ? 40 : 50,
                  child: FadeTransition(
                    opacity: _animation,
                    child: _buildChart(),
                  ),
                ),
              ],
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    widget.growth >= 0 ? Icons.arrow_upward : Icons.arrow_downward,
                    color: widget.growth >= 0 ? Colors.green : Colors.red,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${widget.growth.abs()}%',
                    style: TextStyle(
                      color: widget.growth >= 0 ? Colors.green : Colors.red,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildChart() {
    if (widget.chartData == null || widget.chartData!.isEmpty) {
      return const SizedBox.shrink();
    }

    final data = widget.chartData!;
    final maxY = data.reduce((a, b) => a > b ? a : b);
    final minY = data.reduce((a, b) => a < b ? a : b);
    final yMargin = (maxY - minY) * 0.2;

    return LineChart(
      LineChartData(
        gridData: FlGridData(show: false),
        titlesData: FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: List.generate(
              data.length,
              (index) => FlSpot(index.toDouble(), data[index]),
            ),
            isCurved: true,
            color: widget.color ?? Colors.teal[400],
            barWidth: 2,
            isStrokeCapRound: true,
            dotData: FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: (widget.color ?? Colors.teal[400])?.withOpacity(0.1),
            ),
          ),
        ],
        minX: 0,
        maxX: (data.length - 1).toDouble(),
        minY: minY - yMargin,
        maxY: maxY + yMargin,
      ),
    );
  }
} 