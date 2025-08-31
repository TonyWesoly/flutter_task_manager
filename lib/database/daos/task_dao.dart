import 'package:drift/drift.dart';
import '../database.dart';
import '../tables/tasks_table.dart';

part 'task_dao.g.dart';

@DriftAccessor(tables: [Tasks])
class TaskDao extends DatabaseAccessor<AppDatabase> with _$TaskDaoMixin {
  TaskDao(super.db);

  // CREATE - Add a new task
  Future<int> insertTask(TasksCompanion task) => into(tasks).insert(task);

  // READ - Get all tasks
  Future<List<Task>> getAllTasks() => select(tasks).get();

  // READ - Get a task by ID
  Future<Task?> getTaskById(int id) => 
      (select(tasks)..where((t) => t.id.equals(id))).getSingleOrNull();

  // UPDATE - Update a task
  Future<bool> updateTask(Task task) => update(tasks).replace(task);

  //UPDATE - Toggle task
  Future<void> toggleTask(int id) async {
    final task = await getTaskById(id);

    if (task == null) return;
    final newCompletedAt = task.completedAt == null ? DateTime.now() : null;

    await (update(tasks)..where((t) => t.id.equals(id))).write(
      TasksCompanion(
        completedAt: Value(newCompletedAt),
      ),
    );
  }

  // DELETE - Delete a task
  Future<int> deleteTask(int id) => 
      (delete(tasks)..where((t) => t.id.equals(id))).go();

  // READ - Get tasks with filters
  Future<List<Task>> getIncompleteTasks() {
    return (select(tasks)
      ..where((t) => t.completedAt.isNull())
      ..orderBy([(t) => OrderingTerm(expression: t.deadline, mode: OrderingMode.asc)]))
        .get();
  }

  Future<List<Task>> getCompletedTasks() {
    return (select(tasks)
      ..where((t) => t.completedAt.isNotNull())
      ..orderBy([(t) => OrderingTerm(expression: t.completedAt, mode: OrderingMode.desc)]))
        .get();
  }

  Future<Map<DateTime, int>> getWeekStatistics(int weekOffset) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    final weekday = today.weekday;
    final mondayOfCurrentWeek = today.subtract(Duration(days: weekday - 1));
    
    final mondayOfTargetWeek = mondayOfCurrentWeek.add(Duration(days: weekOffset * 7));
    final sundayOfTargetWeek = mondayOfTargetWeek.add(const Duration(days: 6));
    
    final completedTasks = await (select(tasks)
      ..where((t) => t.completedAt.isNotNull() & 
                     t.completedAt.isBiggerOrEqualValue(mondayOfTargetWeek) &
                     t.completedAt.isSmallerOrEqualValue(sundayOfTargetWeek.add(const Duration(days: 1)))))
        .get();

    final Map<DateTime, int> statistics = {};
    
    for (int i = 0; i < 7; i++) {
      final date = mondayOfTargetWeek.add(Duration(days: i));
      statistics[date] = 0;
    }

    for (final task in completedTasks) {
      if (task.completedAt != null) {
        final taskDate = DateTime(
          task.completedAt!.year,
          task.completedAt!.month,
          task.completedAt!.day,
        );
        
        if (statistics.containsKey(taskDate)) {
          statistics[taskDate] = statistics[taskDate]! + 1;
        }
      }
    }

    return statistics;
  }

  Future<int> getTotalCompletedTasks() async {
    final completedTasks = await (select(tasks)
      ..where((t) => t.completedAt.isNotNull()))
        .get();
    return completedTasks.length;
  }

  Future<Map<DateTime, int>> getCompletionStatistics() async {
    return getWeekStatistics(0);
  }
}