import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_task_manager/screens/adding_editing_task.dart';
import 'package:intl/intl.dart';
import '../cubit/task_cubit.dart';
import '../database/database.dart';

class TaskDetailScreen extends StatelessWidget {
  final Task task;

  const TaskDetailScreen({super.key, required this.task});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
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
                style: Theme.of(context).textTheme.headlineMedium,
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
                  children: [
                    Text(
                      DateFormat('dd-MM-yyyy').format(task.deadline),
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    if (task.completedAt != null)
                      Text(
                        'Ukończono: ${DateFormat('dd-MM-yyyy').format(task.completedAt!)}',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                  ],
                ),
              ],
            ),

            if (task.description != null && task.description!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: Text(
                  task.description!,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
          ],
        ),
      ),
      floatingActionButton: task.completedAt == null
          ? FloatingActionButton(
              onPressed: () {
                context.read<TasksCubit>().toggleTask(task.id).then((_) {
                  Navigator.of(context).pop();
                });
              },
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
              child: const Icon(Icons.check),
            )
          : null,
    );
  }

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Usunąć to zadanie?'),
          // content: const Text('Usunąć to zadanie?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Anuluj'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                context.read<TasksCubit>().deleteTask(task.id).then((_) {
                  Navigator.of(context).pop();
                });
              },
              child: const Text('Usuń'),
            ),
          ],
        );
      },
    );
  }
}
