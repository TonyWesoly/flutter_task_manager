import 'package:flutter_bloc/flutter_bloc.dart';
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

class StatisticsLoaded extends TasksState {
  final Map<DateTime, int> statistics;
  final int weekOffset;
  final int totalCompleted;
  
  StatisticsLoaded({
    required this.statistics,
    required this.weekOffset,
    required this.totalCompleted,
  });
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

  void addTask(String title, DateTime deadline, [String? description]) async {
    try {
      final id = await database.taskDao.insertTask(
        TasksCompanion(
          title: Value(title),
          deadline: Value(deadline),
          description: Value(description),
        ),
      );

      final task = await database.taskDao.getTaskById(id);
      if (task != null) {
        await notifications.scheduleReminderForTask(task);
      }

      loadIncompleteTasks();
    } catch (e) {
      emit(TasksError('Failed to add task: ${e.toString()}'));
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

  Future<void> deleteMultipleTasks(List<int> ids) async {
    try {
      for (final id in ids) {
        await notifications.cancelReminder(id);
        await database.taskDao.deleteTask(id);
      }
      loadIncompleteTasks();
    } catch (e) {
      emit(TasksError('Failed to delete tasks: ${e.toString()}'));
    }
  }

  Future<void> completeMultipleTasks(List<int> ids) async {
    try {
      for (final id in ids) {
        await database.taskDao.toggleTask(id);
        await notifications.cancelReminder(id);
      }
      loadIncompleteTasks();
    } catch (e) {
      emit(TasksError('Failed to complete tasks: ${e.toString()}'));
    }
  }

  Future<void> restoreMultipleTasks(List<int> ids) async {
    try {
      for (final id in ids) {
        await database.taskDao.toggleTask(id);
        final task = await database.taskDao.getTaskById(id);
        if (task != null) {
          await notifications.scheduleReminderForTask(task);
        }
      }
      loadCompletedTasks();
    } catch (e) {
      emit(TasksError('Failed to restore tasks: ${e.toString()}'));
    }
  }

  Future<void> deleteMultipleCompletedTasks(List<int> ids) async {
    try {
      for (final id in ids) {
        await database.taskDao.deleteTask(id);
      }
      loadCompletedTasks();
    } catch (e) {
      emit(TasksError('Failed to delete tasks: ${e.toString()}'));
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

  void loadCompletedTasks() async {
    emit(TasksLoading());
    try {
      final tasks = await database.taskDao.getCompletedTasks();
      emit(TasksLoaded(tasks));
    } catch (e) {
      emit(TasksError(e.toString()));
    }
  }

  void loadStatistics() async {
    loadWeekStatistics(0);
  }

  void loadWeekStatistics(int weekOffset) async {
    emit(TasksLoading());
    try {
      final stats = await database.taskDao.getWeekStatistics(weekOffset);
      final total = await database.taskDao.getTotalCompletedTasks();
      emit(StatisticsLoaded(
        statistics: stats,
        weekOffset: weekOffset,
        totalCompleted: total,
      ));
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