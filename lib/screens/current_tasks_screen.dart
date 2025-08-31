import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../core/constants.dart';
import '../cubit/task_cubit.dart';
import '../database/database.dart';
import '../mixins/selection_mode_mixin.dart';
import '../widgets/empty_state_widget.dart';
import '../widgets/selection_icon.dart';
import '../widgets/task_list_tile.dart';
import 'adding_editing_task.dart';
import 'task_detail_screen.dart';

class CurrentTasksScreen extends StatefulWidget {
  final Function(bool) onSelectionModeChanged;
  final Function(Set<int>) onSelectedTasksChanged;

  const CurrentTasksScreen({
    super.key,
    required this.onSelectionModeChanged,
    required this.onSelectedTasksChanged,
  });

  @override
  State<CurrentTasksScreen> createState() => CurrentTasksScreenState();
}

class CurrentTasksScreenState extends State<CurrentTasksScreen>
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
          child: TaskDetailScreen(task: task, isFromCompletedScreen: false),
        ),
      ),
    );
  }

  void _navigateToAddTask() {
    final cubit = context.read<TasksCubit>();
    Navigator.of(context)
        .push(
          MaterialPageRoute<void>(
            builder: (context) => BlocProvider.value(
              value: cubit,
              child: const AddingEditingTask(mode: TaskMode.add),
            ),
          ),
        )
        .then((_) {
          if (!mounted) return;
          cubit.loadIncompleteTasks();
        });
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
          : Checkbox(
              value: false,
              onChanged: (_) => context.read<TasksCubit>().toggleTask(task.id),
            ),
      trailing: Text(
        DateFormat(
          AppConstants.monthDayFormat,
          AppConstants.defaultLocale,
        ).format(task.deadline),
        style: Theme.of(context).textTheme.labelSmall,
      ),
      onTap: () => _handleTaskTap(task),
      onLongPress: () => _handleTaskLongPress(task),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocBuilder<TasksCubit, TasksState>(
        builder: (context, state) {
          if (state is TasksLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is TasksLoaded) {
            if (state.tasks.isEmpty) {
              return const EmptyStateWidget(
                icon: Icons.task_alt,
                message: AppStrings.noTasksToDo,
              );
            }

            return ListView.builder(
              itemCount: state.tasks.length,
              itemBuilder: (context, index) =>
                  _buildTaskItem(state.tasks[index]),
            );
          }

          if (state is TasksError) {
            return Center(child: Text('Error: ${state.message}'));
          }

          return const Center(child: Text(AppStrings.loadingText));
        },
      ),
      floatingActionButton: isSelectionMode
          ? null
          : FloatingActionButton(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
              onPressed: _navigateToAddTask,
              child: const Icon(Icons.add),
            ),
    );
  }
}
