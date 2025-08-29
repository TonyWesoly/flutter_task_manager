import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_task_manager/screens/adding_editing_task.dart';
import 'package:flutter_task_manager/screens/task_detail_screen.dart';
import '../cubit/task_cubit.dart';

class TaskListScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Lista Zadań')),
      body: BlocBuilder<TasksCubit, TasksState>(
        builder: (context, state) {
          if (state is TasksLoading) {
            return Center(child: CircularProgressIndicator());
          } else if (state is TasksLoaded) {
            final tasks = state.tasks;
            if (tasks.isEmpty) {
              return Center(child: Text('Nie znaleziono zadań!'));
            }
            return ListView.builder(
              itemCount: tasks.length,
              itemBuilder: (context, index) {
                final todo = tasks[index];
                return ListTile(
                  leading: Checkbox(
                    value: false,
                    onChanged: (value) {
                      context.read<TasksCubit>().toggleTask(todo.id);
                    },
                  ),
                  title: Text(
                    todo.title,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  subtitle:
                      todo.description != null && todo.description!.isNotEmpty
                      ? Text(todo.description!)
                      : null,
                      onTap: () {
                        Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => BlocProvider.value(
                          value: context.read<TasksCubit>(),
                          child: TaskDetailScreen(task: todo),
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
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (context) => BlocProvider.value(
                value: context.read<TasksCubit>(),
                child: const AddingEditingTask(mode: TaskMode.add),
              ),
            ),
          ).then((_) {
            context.read<TasksCubit>().loadIncompleteTasks();
          });
        },
        child: Icon(Icons.add),
      ),
    );
  }
}
