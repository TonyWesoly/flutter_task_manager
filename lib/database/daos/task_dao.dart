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
  Future<Task?> getTaskById(int id) => (select(tasks)..where((t) => t.id.equals(id))).getSingleOrNull();

  // UPDATE - Update a task
  Future<bool> updateTask(Task task) => update(tasks).replace(task);

  // DELETE - Delete a task
  Future<int> deleteTask(int id) => (delete(tasks)..where((t) => t.id.equals(id))).go();

  // READ - Get tasks with filters
  Future<List<Task>> getIncompleteTasks() {
    return (select(tasks)
      ..where((t) => t.completedAt.isNull())
      ..orderBy([(t) => OrderingTerm(expression: t.deadline, mode: OrderingMode.asc)]))
        .get();
  }
}