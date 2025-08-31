import 'package:flutter/material.dart';
import '../core/constants.dart';
import '../database/database.dart';

class TaskListTile extends StatelessWidget {
  final Task task;
  final bool isSelected;
  final Widget leading;
  final Widget? trailing;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const TaskListTile({
    super.key,
    required this.task,
    required this.isSelected,
    required this.leading,
    this.trailing,
    this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      tileColor: isSelected
          ? Theme.of(context)
              .colorScheme
              .primaryContainer
              .withValues(alpha: AppConstants.selectionOpacity)
          : null,
      leading: leading,
      title: Text(
        task.title,
        style: Theme.of(context).textTheme.bodyLarge,
      ),
      subtitle: _buildSubtitle(context),
      trailing: trailing,
      onTap: onTap,
      onLongPress: onLongPress,
    );
  }

  Widget? _buildSubtitle(BuildContext context) {
    if (task.description != null && task.description!.isNotEmpty) {
      return Text(
        task.description!,
        style: Theme.of(context).textTheme.bodyMedium!.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
      );
    }
    return null;
  }
}