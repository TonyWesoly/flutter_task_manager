import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../core/constants.dart';
import '../cubit/task_cubit.dart';
import '../database/database.dart';
import '../widgets/confirmation_dialog.dart';
import 'adding_editing_task.dart';

class TaskDetailScreen extends StatelessWidget {
  final Task task;
  final bool isFromCompletedScreen;

  const TaskDetailScreen({
    super.key,
    required this.task,
    this.isFromCompletedScreen = false,
  });

  bool get _isCompleted => task.completedAt != null;

  void _navigateToEdit(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => BlocProvider.value(
          value: context.read<TasksCubit>(),
          child: AddingEditingTask(mode: TaskMode.edit, task: task),
        ),
      ),
    );
  }

  void _handleDelete(BuildContext context) {
    ConfirmationDialog.show(
      context: context,
      title: AppStrings.deleteTaskTitle,
      content: 'Zadanie "${task.title}" zostanie trwale usunięte.',
      confirmText: AppStrings.deleteButton,
      confirmTextColor: Theme.of(context).colorScheme.error,
      onConfirm: () async {
        await context.read<TasksCubit>().deleteTask(task.id);
        if (!context.mounted) return;
        Navigator.of(context).pop();
        
        final cubit = context.read<TasksCubit>();
        if (isFromCompletedScreen) {
          cubit.loadCompletedTasks();
        } else {
          cubit.loadIncompleteTasks();
        }
      },
    );
  }

  void _handleRestore(BuildContext context) {
    ConfirmationDialog.show(
      context: context,
      title: AppStrings.restoreTaskTitle,
      content: 'Zadanie "${task.title}" zostanie oznaczone jako nieukończone.',
      confirmText: AppStrings.restoreButton,
      onConfirm: () async {
        await context.read<TasksCubit>().toggleTask(task.id);
        if (!context.mounted) return;
        Navigator.of(context).pop();
        
        if (isFromCompletedScreen) {
          context.read<TasksCubit>().loadCompletedTasks();
        }
      },
    );
  }

  void _handleComplete(BuildContext context) async {
    await context.read<TasksCubit>().toggleTask(task.id);
    if (!context.mounted) return;
    Navigator.of(context).pop();
  }

  Widget _buildInfoRow({
    required BuildContext context,
    required IconData icon,
    required Widget content,
  }) {
    return Row(
      spacing: AppConstants.spacingDefault,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        IconTheme(
          data: IconThemeData(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          child: Icon(icon),
        ),
        Expanded(child: content),
      ],
    );
  }

  Widget _buildDateInfo(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${AppStrings.deadlinePrefix}${DateFormat(AppConstants.dateFormat).format(task.deadline)}',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        if (task.completedAt != null)
          Text(
            '${AppStrings.completedPrefix}${DateFormat(AppConstants.dateTimeFormat).format(task.completedAt!)}',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          if (!_isCompleted)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => _navigateToEdit(context),
            ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () => _handleDelete(context),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingDefault),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: AppConstants.spacingDefault,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: AppConstants.spacingHuge),
              child: Text(
                task.title,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  decoration: _isCompleted ? TextDecoration.lineThrough : null,
                  decorationColor: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            _buildInfoRow(
              context: context,
              icon: Icons.calendar_month,
              content: _buildDateInfo(context),
            ),
            if (task.description != null && task.description!.isNotEmpty)
              _buildInfoRow(
                context: context,
                icon: Symbols.description,
                content: Text(
                  task.description!,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _isCompleted 
            ? _handleRestore(context) 
            : _handleComplete(context),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        child: Icon(_isCompleted ? Icons.undo : Icons.check),
      ),
    );
  }
}