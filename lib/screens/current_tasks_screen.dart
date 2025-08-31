import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_task_manager/screens/adding_editing_task.dart';
import 'package:flutter_task_manager/screens/task_detail_screen.dart';
import '../cubit/task_cubit.dart';
import 'package:intl/intl.dart';

class CurrentTasksScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocBuilder<TasksCubit, TasksState>(
        builder: (context, state) {
          if (state is TasksLoading) {
            return Center(child: CircularProgressIndicator());
          } else if (state is TasksLoaded) {
            final tasks = state.tasks;
            if (tasks.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.task_alt,
                      size: 64,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Brak zadań do wykonania!',
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
                    value: false,
                    onChanged: (value) {
                      context.read<TasksCubit>().toggleTask(task.id);
                    },
                  ),
                  title: Text(
                    task.title,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  subtitle:
                      task.description != null && task.description!.isNotEmpty
                      ? Text(
                          task.description!,
                          style: Theme.of(context).textTheme.bodyMedium!
                              .copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                        )
                      : null,
                  trailing: Text(
                    DateFormat('d MMMM', 'pl_PL').format(task.deadline),
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => BlocProvider.value(
                          value: context.read<TasksCubit>(),
                          child: TaskDetailScreen(
                            task: task,
                            isFromCompletedScreen:
                                false,
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            );
          } else if (state is TasksError) {
            return Center(child: Text('Error: ${state.message}'));
          }
          return Center(child: Text('Ładowanie...'));
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        onPressed: () {
          Navigator.of(context)
              .push(
                MaterialPageRoute<void>(
                  builder: (context) => BlocProvider.value(
                    value: context.read<TasksCubit>(),
                    child: const AddingEditingTask(mode: TaskMode.add),
                  ),
                ),
              )
              .then((_) {
                context.read<TasksCubit>().loadIncompleteTasks();
              });
        },
        child: Icon(Icons.add),
      ),
    );
  }
}
