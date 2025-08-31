import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/constants.dart';

class WeekNavigationCard extends StatelessWidget {
  final int weekOffset;
  final Function(int) onWeekChanged;

  const WeekNavigationCard({
    super.key,
    required this.weekOffset,
    required this.onWeekChanged,
  });

  String _getWeekRangeText() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final weekday = today.weekday;
    final mondayOfCurrentWeek = today.subtract(Duration(days: weekday - 1));
    final mondayOfTargetWeek = mondayOfCurrentWeek.add(Duration(days: weekOffset * 7));
    final sundayOfTargetWeek = mondayOfTargetWeek.add(const Duration(days: 6));

    switch (weekOffset) {
      case 0:
        return AppStrings.currentWeek;
      case -1:
        return AppStrings.previousWeek;
      case 1:
        return AppStrings.nextWeek;
      default:
        final formatter = DateFormat(AppConstants.monthYearFormat, AppConstants.defaultLocale);
        return '${formatter.format(mondayOfTargetWeek)} - ${formatter.format(sundayOfTargetWeek)}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppConstants.paddingSmall,
          vertical: 4.0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left),
              onPressed: () => onWeekChanged(-1),
            ),
            Text(
              _getWeekRangeText(),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right),
              onPressed: weekOffset < 0 ? () => onWeekChanged(1) : null,
            ),
          ],
        ),
      ),
    );
  }
}