import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_task_manager/screens/adding_editing_task.dart';
import 'package:intl/intl.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../cubit/task_cubit.dart';
import '../database/database.dart';

class TaskDetailScreen extends StatelessWidget {
  final Task task;
  final bool isFromCompletedScreen;

  const TaskDetailScreen({
    super.key, 
    required this.task,
    this.isFromCompletedScreen = false,
  });

  @override
  Widget build(BuildContext context) {
    final bool isCompleted = task.completedAt != null;
    
    return Scaffold(
      appBar: AppBar(
        actions: [
          if (!isCompleted)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => BlocProvider.value(
                      value: context.read<TasksCubit>(),
                      child: AddingEditingTask(mode: TaskMode.edit, task: task),
                    ),
                  ),
                );
              },
            ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () {
              _showDeleteDialog(context);
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 16.0,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 38.0),
              child: Text(
                task.title,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  decoration: isCompleted ? TextDecoration.lineThrough : null,
                  decorationColor: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            Row(
              spacing: 16.0,
              children: [
                IconTheme(
                  data: IconThemeData(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  child: const Icon(Icons.calendar_month),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Termin: ${DateFormat('dd-MM-yyyy').format(task.deadline)}',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    if (task.completedAt != null)
                      Text(
                        'Ukończono: ${DateFormat('dd-MM-yyyy HH:mm').format(task.completedAt!)}',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                  ],
                ),
              ],
            ),

            if (task.description != null && task.description!.isNotEmpty)
              Row(
                spacing: 16.0,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  IconTheme(
                    data: IconThemeData(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    child: const Icon(Symbols.description),
                  ),
                  Expanded(
                    child: Text(
                      task.description!,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (isCompleted) {
            _showUndoDialog(context);
          } else {
            context.read<TasksCubit>().toggleTask(task.id).then((_) {
              if (!context.mounted) return;
              Navigator.of(context).pop();
            });
          }
        },
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        child: Icon(isCompleted ? Icons.undo : Icons.check),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Usunąć to zadanie?'),
          content: Text('Zadanie "${task.title}" zostanie trwale usunięte.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Anuluj'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                
                context.read<TasksCubit>().deleteTask(task.id).then((_) {
                  if (!context.mounted) return;
                  Navigator.of(context).pop();
                  
                  if (isFromCompletedScreen) {
                    context.read<TasksCubit>().loadCompletedTasks();
                  } else {
                    context.read<TasksCubit>().loadIncompleteTasks();
                  }
                });
              },
              child: Text(
                'Usuń',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showUndoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Przywrócić zadanie?'),
          content: Text('Zadanie "${task.title}" zostanie oznaczone jako nieukończone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Anuluj'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                
                context.read<TasksCubit>().toggleTask(task.id).then((_) {
                  if (!context.mounted) return;
                  Navigator.of(context).pop();
                  
                  if (isFromCompletedScreen) {
                    context.read<TasksCubit>().loadCompletedTasks();
                  }
                });
              },
              child: const Text('Przywróć'),
            ),
          ],
        );
      },
    );
  }
}