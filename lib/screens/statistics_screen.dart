import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../cubit/task_cubit.dart';

class StatisticsScreen extends StatefulWidget {
  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  int _currentWeekOffset = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TasksCubit>().loadWeekStatistics(_currentWeekOffset);
    });
  }

  void _changeWeek(int delta) {
    setState(() {
      _currentWeekOffset += delta;
    });
    context.read<TasksCubit>().loadWeekStatistics(_currentWeekOffset);
  }

  String _getWeekRangeText(int weekOffset) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final weekday = today.weekday;
    final mondayOfCurrentWeek = today.subtract(Duration(days: weekday - 1));
    final mondayOfTargetWeek = mondayOfCurrentWeek.add(Duration(days: weekOffset * 7));
    final sundayOfTargetWeek = mondayOfTargetWeek.add(const Duration(days: 6));
    
    if (weekOffset == 0) {
      return 'Ten tydzień';
    } else if (weekOffset == -1) {
      return 'Poprzedni tydzień';
    } else if (weekOffset == 1) {
      return 'Następny tydzień';
    } else {
      final formatter = DateFormat('d MMM', 'pl_PL');
      return '${formatter.format(mondayOfTargetWeek)} - ${formatter.format(sundayOfTargetWeek)}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TasksCubit, TasksState>(
      builder: (context, state) {
        if (state is TasksLoading) {
          return const Center(child: CircularProgressIndicator());
        } else if (state is StatisticsLoaded) {
          final statistics = state.statistics;
          final sortedDates = statistics.keys.toList()..sort();
          
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
          
          int weekTotal = statistics.values.fold(0, (sum, value) => sum + value);
          
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              Icon(
                                Icons.task_alt,
                                color: Theme.of(context).colorScheme.primary,
                                size: 32,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '${state.totalCompleted}',
                                style: Theme.of(context).textTheme.headlineMedium,
                              ),
                              Text(
                                'Wykonanych ogólnie',
                                style: Theme.of(context).textTheme.bodySmall,
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              Icon(
                                Icons.calendar_view_week,
                                color: Theme.of(context).colorScheme.secondary,
                                size: 32,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '$weekTotal',
                                style: Theme.of(context).textTheme.headlineMedium,
                              ),
                              Text(
                                'W tym tygodniu',
                                style: Theme.of(context).textTheme.bodySmall,
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                
                Card(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.chevron_left),
                          onPressed: () => _changeWeek(-1),
                        ),
                        Text(
                          _getWeekRangeText(_currentWeekOffset),
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        IconButton(
                          icon: const Icon(Icons.chevron_right),
                          onPressed: _currentWeekOffset < 0 
                              ? () => _changeWeek(1)
                              : null,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                
                Expanded(
                  child: Card(
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: BarChart(
                        BarChartData(
                          alignment: BarChartAlignment.spaceAround,
                          maxY: maxValue.toDouble(),
                          minY: 0,
                          barTouchData: BarTouchData(
                            touchTooltipData: BarTouchTooltipData(
                              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                                final date = sortedDates[group.x.toInt()];
                                final count = rod.toY.toInt();
                                return BarTooltipItem(
                                  '${DateFormat('dd.MM').format(date)}\n',
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
                          ),
                          titlesData: FlTitlesData(
                            show: true,
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (value, meta) {
                                  final index = value.toInt();
                                  if (index >= 0 && index < sortedDates.length) {
                                    final date = sortedDates[index];
                                    final isToday = DateFormat('yyyy-MM-dd').format(date) == 
                                                   DateFormat('yyyy-MM-dd').format(DateTime.now());
                                    
                                    final dayNames = ['Pon', 'Wt', 'Śr', 'Czw', 'Pt', 'Sob', 'Nd'];
                                    final dayName = dayNames[date.weekday - 1];
                                    
                                    return Padding(
                                      padding: const EdgeInsets.only(top: 8.0),
                                      child: Text(
                                        isToday ? 'Dziś' : dayName,
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
                                  return const Text('');
                                },
                              ),
                            ),
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                interval: 1,
                                getTitlesWidget: (value, meta) {
                                  if (value == value.toInt()) {
                                    return Text(
                                      value.toInt().toString(),
                                      style: const TextStyle(fontSize: 12),
                                    );
                                  }
                                  return const Text('');
                                },
                              ),
                            ),
                            rightTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            topTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                          ),
                          borderData: FlBorderData(
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
                          ),
                          barGroups: List.generate(
                            sortedDates.length,
                            (index) {
                              final date = sortedDates[index];
                              final count = statistics[date] ?? 0;
                              final isMaxDay = date == maxDay && maxDayValue > 0;
                              final isToday = DateFormat('yyyy-MM-dd').format(date) == 
                                             DateFormat('yyyy-MM-dd').format(DateTime.now());
                              
                              return BarChartGroupData(
                                x: index,
                                barRods: [
                                  BarChartRodData(
                                    toY: count.toDouble(),
                                    color: isMaxDay
                                        ? Theme.of(context).colorScheme.primary
                                        : isToday && _currentWeekOffset == 0
                                            ? Theme.of(context).colorScheme.primary.withOpacity(0.8)
                                            : Theme.of(context).colorScheme.primary.withOpacity(0.5),
                                    width: 20,
                                    borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(4),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                          gridData: FlGridData(
                            show: true,
                            drawVerticalLine: false,
                            horizontalInterval: 1,
                            getDrawingHorizontalLine: (value) {
                              return FlLine(
                                color: Theme.of(context).dividerColor.withOpacity(0.3),
                                strokeWidth: 1,
                                dashArray: [5, 5],
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        } else if (state is TasksError) {
          return Center(child: Text('Błąd: ${state.message}'));
        }
        return const Center(child: Text('Ładowanie statystyk...'));
      },
    );
  }
}