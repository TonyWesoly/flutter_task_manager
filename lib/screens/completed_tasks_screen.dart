import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../core/constants.dart';
import '../cubit/task_cubit.dart';
import '../database/database.dart';
import '../mixins/selection_mode_mixin.dart';
import '../widgets/confirmation_dialog.dart';
import '../widgets/empty_state_widget.dart';
import '../widgets/selection_icon.dart';
import '../widgets/task_list_tile.dart';
import 'task_detail_screen.dart';

class CompletedTasksScreen extends StatefulWidget {
  final Function(bool) onSelectionModeChanged;
  final Function(Set<int>) onSelectedTasksChanged;

  const CompletedTasksScreen({
    super.key,
    required this.onSelectionModeChanged,
    required this.onSelectedTasksChanged,
  });

  @override
  State<CompletedTasksScreen> createState() => CompletedTasksScreenState();
}

class CompletedTasksScreenState extends State<CompletedTasksScreen>
    with SelectionModeMixin {
  void _handleTaskTap(Task task) {
    if (isSelectionMode) {
      toggleSelection(
        task.id,
        onSelectedIdsChanged: widget.onSelectedTasksChanged,
      );
    } else {
      _navigateToTaskDetail(task);
    }
  }

  void _handleTaskLongPress(Task task) {
    if (!isSelectionMode) {
      enterSelectionMode(
        task.id,
        onSelectionModeChanged: widget.onSelectionModeChanged,
        onSelectedIdsChanged: widget.onSelectedTasksChanged,
      );
    }
  }

  void _navigateToTaskDetail(Task task) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => BlocProvider.value(
          value: context.read<TasksCubit>(),
          child: TaskDetailScreen(task: task, isFromCompletedScreen: true),
        ),
      ),
    );
  }

  void _showUndoDialog(Task task) {
    ConfirmationDialog.show(
      context: context,
      title: AppStrings.restoreTaskTitle,
      content: 'Czy chcesz oznaczyć "${task.title}" jako nieukończone?',
      confirmText: AppStrings.restoreButton,
      onConfirm: () async {
        final cubit = context.read<TasksCubit>();
        await cubit.toggleTask(task.id);
        if (!mounted) return;
        cubit.loadCompletedTasks();
      },
    );
  }

  Widget _buildTaskItem(Task task) {
    final isSelected = selectedIds.contains(task.id);

    return TaskListTile(
      task: task,
      isSelected: isSelected,
      leading: isSelectionMode
          ? SelectionIcon(
              isSelected: isSelected,
              onPressed: () => toggleSelection(
                task.id,
                onSelectedIdsChanged: widget.onSelectedTasksChanged,
              ),
            )
          : Checkbox(value: true, onChanged: (_) => _showUndoDialog(task)),
      trailing: Text(
        '${AppStrings.completedPrefix}${DateFormat(AppConstants.monthDayFormat, AppConstants.defaultLocale).format(task.completedAt!)}',
        style: Theme.of(context).textTheme.labelSmall,
      ),
      onTap: () => _handleTaskTap(task),
      onLongPress: () => _handleTaskLongPress(task),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TasksCubit, TasksState>(
      builder: (context, state) {
        if (state is TasksLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is TasksLoaded) {
          if (state.tasks.isEmpty) {
            return const EmptyStateWidget(
              icon: Icons.check_circle_outline,
              message: AppStrings.noCompletedTasks,
            );
          }

          return ListView.builder(
            itemCount: state.tasks.length,
            itemBuilder: (context, index) => _buildTaskItem(state.tasks[index]),
          );
        }

        if (state is TasksError) {
          return Center(child: Text('Błąd: ${state.message}'));
        }

        return const Center(child: Text(AppStrings.loadingText));
      },
    );
  }
}
