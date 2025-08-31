import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../core/constants.dart';
import '../cubit/task_cubit.dart';
import '../widgets/statistics_chart.dart';
import '../widgets/statistics_summary_card.dart';
import '../widgets/week_navigation_card.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  int _currentWeekOffset = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadStatistics();
    });
  }

  void _loadStatistics() {
    context.read<TasksCubit>().loadWeekStatistics(_currentWeekOffset);
  }

  void _changeWeek(int delta) {
    setState(() {
      _currentWeekOffset += delta;
    });
    _loadStatistics();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TasksCubit, TasksState>(
      builder: (context, state) {
        if (state is TasksLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is StatisticsLoaded) {
          return _StatisticsView(
            state: state,
            currentWeekOffset: _currentWeekOffset,
            onWeekChanged: _changeWeek,
          );
        }

        if (state is TasksError) {
          return Center(child: Text('Błąd: ${state.message}'));
        }

        return const Center(child: Text(AppStrings.loadingStatistics));
      },
    );
  }
}

class _StatisticsView extends StatelessWidget {
  final StatisticsLoaded state;
  final int currentWeekOffset;
  final Function(int) onWeekChanged;

  const _StatisticsView({
    required this.state,
    required this.currentWeekOffset,
    required this.onWeekChanged,
  });

  @override
  Widget build(BuildContext context) {
    final weekTotal = state.statistics.values.fold(0, (sum, value) => sum + value);

    return Padding(
      padding: const EdgeInsets.all(AppConstants.paddingDefault),
      child: Column(
        children: [
          _buildSummaryCards(context, weekTotal),
          const SizedBox(height: AppConstants.spacingLarge),
          WeekNavigationCard(
            weekOffset: currentWeekOffset,
            onWeekChanged: onWeekChanged,
          ),
          const SizedBox(height: AppConstants.spacingDefault),
          Expanded(
            child: StatisticsChart(statistics: state.statistics),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards(BuildContext context, int weekTotal) {
    return Row(
      children: [
        Expanded(
          child: StatisticsSummaryCard(
            icon: Icons.task_alt,
            value: state.totalCompleted.toString(),
            label: AppStrings.totalCompleted,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(width: AppConstants.spacingDefault),
        Expanded(
          child: StatisticsSummaryCard(
            icon: Icons.calendar_view_week,
            value: weekTotal.toString(),
            label: AppStrings.weekTotal,
            color: Theme.of(context).colorScheme.secondary,
          ),
        ),
      ],
    );
  }
}