import 'package:drift/drift.dart';
import '../database.dart';
import '../tables/tasks_table.dart';

part 'task_dao.g.dart';

@DriftAccessor(tables: [Tasks])
class TaskDao extends DatabaseAccessor<AppDatabase> with _$TaskDaoMixin {
  TaskDao(AppDatabase db) : super(db);

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

  Future<Map<DateTime, int>> getCompletionStatistics() async {
    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day);
    final sevenDaysAgo = startOfToday.subtract(const Duration(days: 6));

    final completedTasks = await (select(tasks)
      ..where((t) => t.completedAt.isNotNull() & 
                     t.completedAt.isBiggerOrEqualValue(sevenDaysAgo)))
        .get();

    final Map<DateTime, int> statistics = {};
    
    for (int i = 0; i < 7; i++) {
      final date = startOfToday.subtract(Duration(days: 6 - i));
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
}