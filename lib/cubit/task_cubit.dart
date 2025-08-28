import 'package:bloc/bloc.dart';
import 'package:drift/drift.dart';
import '../database/database.dart';

abstract class TasksState {}

class TasksInitial extends TasksState {}

class TasksLoading extends TasksState {}

class TasksLoaded extends TasksState {
  final List<Task> tasks;
  TasksLoaded(this.tasks);
}

class TasksError extends TasksState {
  final String message;
  TasksError(this.message);
}

class TasksCubit extends Cubit<TasksState> {
  final AppDatabase database;
  TasksCubit({required this.database}) : super(TasksInitial());

  void loadTasks() async {
    emit(TasksLoading());
    try {
      final tasks = await database.taskDao.getAllTasks();
      emit(TasksLoaded(tasks));
    } catch (e) {
      emit(TasksError(e.toString()));
    }
  }

  void addTask(String title,DateTime deadline) async {
    try{
      await database.taskDao.insertTask(
        TasksCompanion(
          title: Value(title),
          deadline: Value(deadline),
        )
      );
      loadTasks();
    } catch (e){
      emit(TasksError('Failed to update task: ${e.toString()}'));
    }
  }

  void toggleTask(int id) async {
    try {
      await database.taskDao.toggleTask(id);
      loadTasks();
    } catch (e){
      emit(TasksError('Failed to toggle task: ${e.toString()}'));
    }
  }

  void deleteTask(int id) async{
    try{
      await database.taskDao.deleteTask(id);
      loadTasks();
    } catch(e){
      emit(TasksError('Failed to delete task: ${e.toString()}'));
    }
  }
}