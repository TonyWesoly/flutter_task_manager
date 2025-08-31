// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'current_tasks_screen.dart';
import 'completed_tasks_screen.dart';
import 'statistics_screen.dart';
import '../cubit/task_cubit.dart';
import 'package:material_symbols_icons/symbols.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    CurrentTasksScreen(),
    CompletedTasksScreen(),
    StatisticsScreen(),
  ];

  final List<String> _titles = [
    'Obecne zadania',
    'Wykonane zadania',
    'Statystyki',
  ];

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });

    // Załaduj odpowiednie dane dla każdej zakładki
    final cubit = context.read<TasksCubit>();
    switch (index) {
      case 0:
        cubit.loadIncompleteTasks();
        break;
      case 1:
        cubit.loadCompletedTasks();
        break;
      case 2:
        cubit.loadStatistics();
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_currentIndex]),
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
        backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Symbols.view_list,),
            activeIcon: Icon(Symbols.view_list,fill: 1,),
            label: 'Obecne',
          ),
          BottomNavigationBarItem(
            icon: Icon(Symbols.check_box),
            activeIcon: Icon(Symbols.check_box,fill: 1,),
            label: 'Wykonane',
          ),
          BottomNavigationBarItem(
            icon: Icon(Symbols.insert_chart),
            activeIcon: Icon(Symbols.insert_chart,fill: 1,),
            label: 'Statystyki',
          ),
        ],
      ),
    );
  }
}