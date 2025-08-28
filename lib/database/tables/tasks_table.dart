import 'package:drift/drift.dart';

class Tasks extends Table {
  IntColumn get id => integer().autoIncrement()();
  
  // Title - NOT NULL by default
  TextColumn get title => text()();

  // Description - can be NULL
  TextColumn get description => text().nullable()();

  // Deadline - NOT NULL
  DateTimeColumn get deadline => dateTime()();

  // Creation date - NOT NULL
  @JsonKey('created_at')
  DateTimeColumn get createdAt => dateTime()
    .withDefault(Constant(DateTime.now()))();

  // Completion date - may be NULL
  @JsonKey('completed_at')
  DateTimeColumn get completedAt => dateTime().nullable()();
}