import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
              // TODO: Przejdź do ekranu edycji
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
              Text(
                task.description!,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
          ],
        ),
      ),
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
