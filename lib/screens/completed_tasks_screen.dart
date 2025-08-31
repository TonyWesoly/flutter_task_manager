import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_task_manager/screens/task_detail_screen.dart';
import 'package:intl/intl.dart';
import '../cubit/task_cubit.dart';
import '../database/database.dart';

class CompletedTasksScreen extends StatelessWidget {
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
              return ListTile(
                leading: Checkbox(
                  value: true,
                  onChanged: (value) => _showUndoDialog(context, task),
                ),
                title: Text(
                  task.title,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                subtitle:
                    task.description != null && task.description!.isNotEmpty
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
                onTap: () {
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
}