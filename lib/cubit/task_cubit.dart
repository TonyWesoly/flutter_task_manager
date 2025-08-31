import 'package:bloc/bloc.dart';
import 'package:drift/drift.dart';
import '../database/database.dart';
import '../services/notification_service.dart';

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
  final NotificationService notifications;

  TasksCubit({required this.database, required this.notifications})
      : super(TasksInitial());

  void loadTasks() async {
    emit(TasksLoading());
    try {
      final tasks = await database.taskDao.getAllTasks();
      emit(TasksLoaded(tasks));
    } catch (e) {
      emit(TasksError(e.toString()));
    }
  }

  void addTask(String title, DateTime deadline) async {
    try {
      final id = await database.taskDao.insertTask(
        TasksCompanion(title: Value(title), deadline: Value(deadline)),
      );

      final task = await database.taskDao.getTaskById(id);
      if (task != null) {
        await notifications.scheduleReminderForTask(task);
      }

      loadIncompleteTasks();
    } catch (e) {
      emit(TasksError('Failed to update task: ${e.toString()}'));
    }
  }

  Future<void> toggleTask(int id) async {
    try {
      await database.taskDao.toggleTask(id);
      final task = await database.taskDao.getTaskById(id);

      if (task != null) {
        if (task.completedAt != null) {
          await notifications.cancelReminder(id);
        } else {
          await notifications.scheduleReminderForTask(task);
        }
      }

      loadIncompleteTasks();
    } catch (e) {
      emit(TasksError('Failed to toggle task: ${e.toString()}'));
    }
  }

  Future<void> deleteTask(int id) async {
    try {
      await notifications.cancelReminder(id);
      await database.taskDao.deleteTask(id);
      loadIncompleteTasks();
    } catch (e) {
      emit(TasksError('Failed to delete task: ${e.toString()}'));
    }
  }

  void loadIncompleteTasks() async {
    emit(TasksLoading());
    try {
      final tasks = await database.taskDao.getIncompleteTasks();
      emit(TasksLoaded(tasks));
    } catch (e) {
      emit(TasksError(e.toString()));
    }
  }

  Future<void> updateTask(Task task) async {
    try {
      await database.taskDao.updateTask(task);
      await notifications.rescheduleReminderForTask(task);
      loadIncompleteTasks();
    } catch (e) {
      emit(TasksError('Failed to update task: ${e.toString()}'));
    }
  }
}