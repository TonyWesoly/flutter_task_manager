part of 'task_cubit.dart';

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