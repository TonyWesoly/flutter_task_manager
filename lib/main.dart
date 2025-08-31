import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'screens/home_screen.dart';
import 'cubit/task_cubit.dart';
import 'database/database.dart';
import 'services/notification_service.dart';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Polish locale for date formatting
  await initializeDateFormatting('pl', null);

  final db = AppDatabase();

  await NotificationService().init(
    db: db,
    navigatorKey: rootNavigatorKey,
    forceTestMode: true,
  );

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
          useMaterial3: true,
        ),
        home: const HomeScreen(),
      ),
    );
  }
}