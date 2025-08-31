import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'screens/tasks_list_screen.dart';
import 'cubit/task_cubit.dart';
import 'database/database.dart';
import 'services/notification_service.dart';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final db = AppDatabase();

  // For testing purposes, you can force test mode (1 min notification after setting task).
  await NotificationService().init(
    db: db,
    navigatorKey: rootNavigatorKey,
    forceTestMode: false,
  );

  // Plan missing reminders at the start
  await NotificationService().scheduleMissingRemindersForIncompleteTasks();

  runApp(MyApp(database: db));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, required this.database});

  final AppDatabase database;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => TasksCubit(
            database: database,
            notifications: NotificationService(),
          )..loadIncompleteTasks(),
        ),
      ],
      child: MaterialApp(
        navigatorKey: rootNavigatorKey,
        title: 'Todo App',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        ),
        home: TaskListScreen(),
      ),
    );
  }
}