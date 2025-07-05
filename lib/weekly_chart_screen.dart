import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'expenses_model.dart';
import 'package:intl/intl.dart';

class WeeklyChartScreen extends StatelessWidget {
  final List<Expense> expenses;

  const WeeklyChartScreen({super.key, required this.expenses});

  Map<String, double> _groupByWeekday(List<Expense> expenses) {
    Map<String, double> totals = {
      'Mon': 0,
      'Tue': 0,
      'Wed': 0,
      'Thu': 0,
      'Fri': 0,
      'Sat': 0,
      'Sun': 0,
    };

    for (var expense in expenses) {
      String day = DateFormat('EEE').format(expense.date);
      if (totals.containsKey(day)) {
        totals[day] = totals[day]! + expense.amount;
      }
    }
    return totals;
  }

  @override
  Widget build(BuildContext context) {
    final weeklyData = _groupByWeekday(expenses);
    final maxY = (weeklyData.values.isEmpty)
        ? 100
        : (weeklyData.values.reduce((a, b) => a > b ? a : b) * 1.5).ceilToDouble();

    return Scaffold(
      appBar: AppBar(
        title: Text("Weekly Expense Graph",style: TextStyle(
          color: Colors.blueAccent
        ),),
        backgroundColor: Colors.transparent,
      ),
      backgroundColor: Colors.transparent, // Graph-paper style
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: BarChart(
          BarChartData(
            maxY: maxY.toDouble(),
            alignment: BarChartAlignment.spaceAround,
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              getDrawingHorizontalLine: (value) {
                return FlLine(
                  color: Colors.grey.shade600,
                  strokeWidth: 1,
                );
              },
            ),
            borderData: FlBorderData(show: false),
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 40,
                  interval: (maxY ~/ 5).toDouble(),
                  getTitlesWidget: (value, _) => Text(
                    "₹ ${value.toInt()}",
                    style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                  ),
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, _) {
                    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                    return Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(days[value.toInt()],
                          style: TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: 12,
                              color: Colors.grey.shade600)),
                    );
                  },
                ),
              ),
              topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            barGroups: List.generate(7, (i) {
              final day = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][i];
              final amount = weeklyData[day] ?? 0;

              return BarChartGroupData(
                x: i,
                barRods: [
                  BarChartRodData(
                    toY: amount,
                    color: Colors.blue,
                    width: 20,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ],
                showingTooltipIndicators: [],
                barsSpace: 6,
              );
            }),
            barTouchData: BarTouchData(
              enabled: false,
              touchTooltipData: BarTouchTooltipData(tooltipBgColor: Colors.transparent),
            ),
          ),
          swapAnimationDuration: Duration(milliseconds: 300),
        ),
      ),
    );
  }
}
