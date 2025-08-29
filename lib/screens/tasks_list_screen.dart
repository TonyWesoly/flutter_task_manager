import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_task_manager/screens/adding_task.dart';
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
                  title: Text(todo.title,style: Theme.of(context).textTheme.bodyLarge,),
                  subtitle:
                      todo.description != null && todo.description!.isNotEmpty
                      ? Text(todo.description!)
                      : null,
                  leading: Checkbox(
                    value: todo.completedAt != null,
                    onChanged: (value) {
                      context.read<TasksCubit>().toggleTask(todo.id);
                    },
                  ),
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
        backgroundColor: Theme.of(context).colorScheme.primary, // Kolor tła
        foregroundColor: Theme.of(context).colorScheme.onPrimary, // Kolor ikony
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (context) => BlocProvider.value(
                // Dodaj BlocProvider.value
                value: context.read<TasksCubit>(), // Przekaż istniejący cubit
                child: const AddingTask(),
              ),
            ),
          );
        },
        child: Icon(Icons.add),
      ),
    );
  }
}
