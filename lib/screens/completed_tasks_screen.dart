import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_task_manager/screens/task_detail_screen.dart';
import 'package:intl/intl.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../cubit/task_cubit.dart';
import '../database/database.dart';

class CompletedTasksScreen extends StatefulWidget {
  final Function(bool) onSelectionModeChanged;
  final Function(Set<int>) onSelectedTasksChanged;

  const CompletedTasksScreen({
    Key? key,
    required this.onSelectionModeChanged,
    required this.onSelectedTasksChanged,
  }) : super(key: key);

  @override
  State<CompletedTasksScreen> createState() => CompletedTasksScreenState();
}

class CompletedTasksScreenState extends State<CompletedTasksScreen> {
  bool _isSelectionMode = false;
  Set<int> _selectedTaskIds = {};

  void _enterSelectionMode(int firstTaskId) {
    setState(() {
      _isSelectionMode = true;
      _selectedTaskIds = {firstTaskId};
    });
    widget.onSelectionModeChanged(true);
    widget.onSelectedTasksChanged(_selectedTaskIds);
  }

  void exitSelectionMode() {
    setState(() {
      _isSelectionMode = false;
      _selectedTaskIds.clear();
    });
  }

  void _toggleTaskSelection(int taskId) {
    setState(() {
      if (_selectedTaskIds.contains(taskId)) {
        _selectedTaskIds.remove(taskId);
      } else {
        _selectedTaskIds.add(taskId);
      }
    });
    widget.onSelectedTasksChanged(_selectedTaskIds);
  }

  void _showUndoDialog(BuildContext context, Task task) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Przywrócić zadanie?'),
          content: Text(
            'Czy chcesz oznaczyć "${task.title}" jako nieukończone?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Anuluj'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                context.read<TasksCubit>().toggleTask(task.id).then((_) {
                  context.read<TasksCubit>().loadCompletedTasks();
                });
              },
              child: const Text('Przywróć'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TasksCubit, TasksState>(
      builder: (context, state) {
        if (state is TasksLoading) {
          return const Center(child: CircularProgressIndicator());
        } else if (state is TasksLoaded) {
          final tasks = state.tasks;
          if (tasks.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    size: 64,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Brak wykonanych zadań',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: tasks.length,
            itemBuilder: (context, index) {
              final task = tasks[index];
              final isSelected = _selectedTaskIds.contains(task.id);
              
              return ListTile(
                tileColor: isSelected 
                    ? Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3)
                    : null,
                leading: _isSelectionMode
                    ? IconButton(
                        icon: isSelected
                              ? Icon(
                                Symbols.check_circle,
                                  color: Theme.of(context).colorScheme.primary,
                                  fill: 1.0,
                                )
                              : Icon(
                                Symbols.circle,
                                ),
                        onPressed: () => _toggleTaskSelection(task.id),
                        padding: EdgeInsets.zero,
                      )
                    : Checkbox(
                        value: true,
                        onChanged: (value) => _showUndoDialog(context, task),
                      ),
                title: Text(
                  task.title,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                subtitle: task.description != null && task.description!.isNotEmpty
                    ? Text(
                        task.description!,
                        style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      )
                    : null,
                trailing: Text(
                  'Ukończono: ${DateFormat('d MMMM', 'pl_PL').format(task.completedAt!)}',
                  style: Theme.of(context).textTheme.labelSmall,
                ),
                onLongPress: () {
                  if (!_isSelectionMode) {
                    _enterSelectionMode(task.id);
                  }
                },
                onTap: () {
                  if (_isSelectionMode) {
                    _toggleTaskSelection(task.id);
                  } else {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => BlocProvider.value(
                          value: context.read<TasksCubit>(),
                          child: TaskDetailScreen(
                            task: task,
                            isFromCompletedScreen: true,
                          ),
                        ),
                      ),
                    );
                  }
                },
              );
            },
          );
        } else if (state is TasksError) {
          return Center(child: Text('Błąd: ${state.message}'));
        }
        return const Center(child: Text('Ładowanie...'));
      },
    );
  }
}