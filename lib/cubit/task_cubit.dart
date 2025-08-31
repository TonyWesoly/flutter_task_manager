import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:drift/drift.dart';
import '../database/database.dart';
import '../services/notification_service.dart';

part 'task_states.dart';

class TasksCubit extends Cubit<TasksState> {
  final AppDatabase database;
  final NotificationService notifications;

  TasksCubit({
    required this.database,
    required this.notifications,
  }) : super(TasksInitial());

  Future<void> _loadTasksWithErrorHandling(
    Future<List<Task>> Function() loader,
  ) async {
    emit(TasksLoading());
    try {
      final tasks = await loader();
      emit(TasksLoaded(tasks));
    } catch (e) {
      emit(TasksError(e.toString()));
    }
  }

  void loadTasks() => _loadTasksWithErrorHandling(
        () => database.taskDao.getAllTasks(),
      );

  void loadIncompleteTasks() => _loadTasksWithErrorHandling(
        () => database.taskDao.getIncompleteTasks(),
      );

  void loadCompletedTasks() => _loadTasksWithErrorHandling(
        () => database.taskDao.getCompletedTasks(),
      );

  Future<void> addTask(
    String title,
    DateTime deadline, [
    String? description,
  ]) async {
    try {
      final id = await database.taskDao.insertTask(
        TasksCompanion(
          title: Value(title),
          deadline: Value(deadline),
          description: Value(description),
        ),
      );

      await _scheduleNotificationForTask(id);
      loadIncompleteTasks();
    } catch (e) {
      emit(TasksError('Failed to add task: $e'));
    }
  }

  Future<void> updateTask(Task task) async {
    try {
      await database.taskDao.updateTask(task);
      await notifications.rescheduleReminderForTask(task);
      loadIncompleteTasks();
    } catch (e) {
      emit(TasksError('Failed to update task: $e'));
    }
  }

  Future<void> toggleTask(int id) async {
    try {
      await database.taskDao.toggleTask(id);
      final task = await database.taskDao.getTaskById(id);

      if (task != null) {
        await _handleTaskNotification(task);
      }

      loadIncompleteTasks();
    } catch (e) {
      emit(TasksError('Failed to toggle task: $e'));
    }
  }

  Future<void> deleteTask(int id) async {
    try {
      await notifications.cancelReminder(id);
      await database.taskDao.deleteTask(id);
      loadIncompleteTasks();
    } catch (e) {
      emit(TasksError('Failed to delete task: $e'));
    }
  }

  Future<void> _processBatchOperation(
    List<int> ids,
    Future<void> Function(int id) operation,
    void Function() onComplete,
    String errorMessage,
  ) async {
    try {
      for (final id in ids) {
        await operation(id);
      }
      onComplete();
    } catch (e) {
      emit(TasksError('$errorMessage: $e'));
    }
  }

  Future<void> deleteMultipleTasks(List<int> ids) async {
    await _processBatchOperation(
      ids,
      (id) async {
        await notifications.cancelReminder(id);
        await database.taskDao.deleteTask(id);
      },
      loadIncompleteTasks,
      'Failed to delete tasks',
    );
  }

  Future<void> completeMultipleTasks(List<int> ids) async {
    await _processBatchOperation(
      ids,
      (id) async {
        await database.taskDao.toggleTask(id);
        await notifications.cancelReminder(id);
      },
      loadIncompleteTasks,
      'Failed to complete tasks',
    );
  }

  Future<void> restoreMultipleTasks(List<int> ids) async {
    await _processBatchOperation(
      ids,
      (id) async {
        await database.taskDao.toggleTask(id);
        await _scheduleNotificationForTask(id);
      },
      loadCompletedTasks,
      'Failed to restore tasks',
    );
  }

  Future<void> deleteMultipleCompletedTasks(List<int> ids) async {
    await _processBatchOperation(
      ids,
      (id) => database.taskDao.deleteTask(id),
      loadCompletedTasks,
      'Failed to delete tasks',
    );
  }

  void loadStatistics() => loadWeekStatistics(0);

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

  Future<void> _scheduleNotificationForTask(int id) async {
    final task = await database.taskDao.getTaskById(id);
    if (task != null) {
      await notifications.scheduleReminderForTask(task);
    }
  }

  Future<void> _handleTaskNotification(Task task) async {
    if (task.completedAt != null) {
      await notifications.cancelReminder(task.id);
    } else {
      await notifications.scheduleReminderForTask(task);
    }
  }
}