import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../core/constants.dart';

class StatisticsChart extends StatelessWidget {
  final Map<DateTime, int> statistics;

  const StatisticsChart({
    super.key,
    required this.statistics,
  });

  @override
  Widget build(BuildContext context) {
    final sortedDates = statistics.keys.toList()..sort();
    final chartData = _prepareChartData(sortedDates);

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingDefault),
        child: BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceAround,
            maxY: chartData.maxValue.toDouble(),
            minY: 0,
            barTouchData: _buildBarTouchData(sortedDates),
            titlesData: _buildTitlesData(context, sortedDates, chartData.maxDay, chartData.maxDayValue),
            borderData: _buildBorderData(context),
            barGroups: _buildBarGroups(context, sortedDates, chartData),
            gridData: _buildGridData(context),
          ),
        ),
      ),
    );
  }

  _ChartData _prepareChartData(List<DateTime> sortedDates) {
    int maxDayValue = 0;
    DateTime? maxDay;

    for (final entry in statistics.entries) {
      if (entry.value > maxDayValue) {
        maxDayValue = entry.value;
        maxDay = entry.key;
      }
    }

    int maxValue = statistics.values.fold(0, (max, value) => value > max ? value : max);
    maxValue = maxValue == 0 ? 5 : maxValue + 2;

    return _ChartData(
      maxDay: maxDay,
      maxDayValue: maxDayValue,
      maxValue: maxValue,
    );
  }

  BarTouchData _buildBarTouchData(List<DateTime> sortedDates) {
    return BarTouchData(
      touchTooltipData: BarTouchTooltipData(
        getTooltipItem: (group, groupIndex, rod, rodIndex) {
          final date = sortedDates[group.x.toInt()];
          final count = rod.toY.toInt();
          return BarTooltipItem(
            '${DateFormat(AppConstants.shortDateFormat).format(date)}\n',
            const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
            children: [
              TextSpan(
                text: '$count ${count == 1 ? 'zadanie' : 'zadań'}',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  FlTitlesData _buildTitlesData(
    BuildContext context,
    List<DateTime> sortedDates,
    DateTime? maxDay,
    int maxDayValue,
  ) {
    return FlTitlesData(
      show: true,
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          getTitlesWidget: (value, meta) => _buildBottomTitle(
            context,
            value.toInt(),
            sortedDates,
            maxDay,
            maxDayValue,
          ),
        ),
      ),
      leftTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          interval: 1,
          getTitlesWidget: (value, meta) => _buildLeftTitle(value),
        ),
      ),
      rightTitles: const AxisTitles(
        sideTitles: SideTitles(showTitles: false),
      ),
      topTitles: const AxisTitles(
        sideTitles: SideTitles(showTitles: false),
      ),
    );
  }

  Widget _buildBottomTitle(
    BuildContext context,
    int index,
    List<DateTime> sortedDates,
    DateTime? maxDay,
    int maxDayValue,
  ) {
    if (index < 0 || index >= sortedDates.length) {
      return const Text('');
    }

    final date = sortedDates[index];
    final isToday = DateFormat('yyyy-MM-dd').format(date) ==
        DateFormat('yyyy-MM-dd').format(DateTime.now());

    final dayName = isToday
        ? AppStrings.todayLabel
        : AppConstants.weekDayNames[date.weekday - 1];

    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Text(
        dayName,
        style: TextStyle(
          fontSize: 12,
          fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
          color: date == maxDay && maxDayValue > 0
              ? Theme.of(context).colorScheme.primary
              : null,
        ),
      ),
    );
  }

  Widget _buildLeftTitle(double value) {
    if (value == value.toInt()) {
      return Text(
        value.toInt().toString(),
        style: const TextStyle(fontSize: 12),
      );
    }
    return const Text('');
  }

  FlBorderData _buildBorderData(BuildContext context) {
    return FlBorderData(
      show: true,
      border: Border(
        bottom: BorderSide(
          color: Theme.of(context).dividerColor,
          width: 1,
        ),
        left: BorderSide(
          color: Theme.of(context).dividerColor,
          width: 1,
        ),
      ),
    );
  }

  List<BarChartGroupData> _buildBarGroups(
    BuildContext context,
    List<DateTime> sortedDates,
    _ChartData chartData,
  ) {
    return List.generate(
      sortedDates.length,
      (index) {
        final date = sortedDates[index];
        final count = statistics[date] ?? 0;
        final isMaxDay = date == chartData.maxDay && chartData.maxDayValue > 0;
        final isToday = DateFormat('yyyy-MM-dd').format(date) ==
            DateFormat('yyyy-MM-dd').format(DateTime.now());

        return BarChartGroupData(
          x: index,
          barRods: [
            BarChartRodData(
              toY: count.toDouble(),
              color: _getBarColor(context, isMaxDay, isToday),
              width: 20,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(4),
              ),
            ),
          ],
        );
      },
    );
  }

  Color _getBarColor(BuildContext context, bool isMaxDay, bool isToday) {
    final primaryColor = Theme.of(context).colorScheme.primary;

    if (isMaxDay) {
      return primaryColor;
    }
    if (isToday) {
      return primaryColor.withValues(alpha: AppConstants.chartOpacityHigh);
    }
    return primaryColor.withValues(alpha: AppConstants.chartOpacityMedium);
  }

  FlGridData _buildGridData(BuildContext context) {
    return FlGridData(
      show: true,
      drawVerticalLine: false,
      horizontalInterval: 1,
      getDrawingHorizontalLine: (value) {
        return FlLine(
          color: Theme.of(context).dividerColor.withValues(alpha: AppConstants.chartOpacityLow),
          strokeWidth: 1,
          dashArray: [5, 5],
        );
      },
    );
  }
}

class _ChartData {
  final DateTime? maxDay;
  final int maxDayValue;
  final int maxValue;

  _ChartData({
    required this.maxDay,
    required this.maxDayValue,
    required this.maxValue,
  });
}