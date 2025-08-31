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
  bool _isSelectionMode = false;
  Set<int> _selectedTaskIds = {};
  final GlobalKey<CurrentTasksScreenState> _currentTasksKey = GlobalKey();
  final GlobalKey<CompletedTasksScreenState> _completedTasksKey = GlobalKey();

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      CurrentTasksScreen(
        key: _currentTasksKey,
        onSelectionModeChanged: _handleSelectionModeChanged,
        onSelectedTasksChanged: _handleSelectedTasksChanged,
      ),
      CompletedTasksScreen(
        key: _completedTasksKey,
        onSelectionModeChanged: _handleSelectionModeChanged,
        onSelectedTasksChanged: _handleSelectedTasksChanged,
      ),
      StatisticsScreen(),
    ];
  }

  void _handleSelectionModeChanged(bool isSelectionMode) {
    setState(() {
      _isSelectionMode = isSelectionMode;
      if (!isSelectionMode) {
        _selectedTaskIds.clear();
      }
    });
  }

  void _handleSelectedTasksChanged(Set<int> selectedIds) {
    setState(() {
      _selectedTaskIds = selectedIds;
    });
  }

  void _exitSelectionMode() {
    setState(() {
      _isSelectionMode = false;
      _selectedTaskIds.clear();
    });
    
    if (_currentIndex == 0) {
      _currentTasksKey.currentState?.exitSelectionMode();
    } else if (_currentIndex == 1) {
      _completedTasksKey.currentState?.exitSelectionMode();
    }
  }

  final List<String> _titles = [
    'Obecne zadania',
    'Wykonane zadania',
    'Statystyki',
  ];

  void _onTabTapped(int index) {
    if (_isSelectionMode) {
      _exitSelectionMode();
    }
    
    setState(() {
      _currentIndex = index;
    });

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

  void _handleCompleteSelected() {
    context.read<TasksCubit>().completeMultipleTasks(_selectedTaskIds.toList());
    _exitSelectionMode();
  }

  void _handleRestoreSelected() {
    context.read<TasksCubit>().restoreMultipleTasks(_selectedTaskIds.toList());
    _exitSelectionMode();
  }

  void _handleDeleteSelected() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Usunąć zaznaczone zadania?'),
        content: Text('Zostanie usuniętych ${_selectedTaskIds.length} zadań.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Anuluj'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              if (_currentIndex == 0) {
                context.read<TasksCubit>().deleteMultipleTasks(_selectedTaskIds.toList());
              } else {
                context.read<TasksCubit>().deleteMultipleCompletedTasks(_selectedTaskIds.toList());
              }
              _exitSelectionMode();
            },
            child: Text(
              'Usuń',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isSelectionMode 
            ? 'Zaznaczono: ${_selectedTaskIds.length}'
            : _titles[_currentIndex]),
        leading: _isSelectionMode
            ? IconButton(
                icon: const Icon(Icons.close),
                onPressed: _exitSelectionMode,
              )
            : null,
      ),
      body: Stack(
        children: [
          IndexedStack(
            index: _currentIndex,
            children: _screens,
          ),
        ],
      ),
      bottomNavigationBar: _isSelectionMode
          ? BottomAppBar(
              height: 64,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  if (_currentIndex == 0) ...[
                    IconButton(
                      icon: const Icon(Icons.check_circle_outline),
                      onPressed: _selectedTaskIds.isEmpty ? null : _handleCompleteSelected,
                      tooltip: 'Oznacz jako wykonane',
                    ),
                  ] else if (_currentIndex == 1) ...[
                    IconButton(
                      icon: const Icon(Icons.undo),
                      onPressed: _selectedTaskIds.isEmpty ? null : _handleRestoreSelected,
                      tooltip: 'Przywróć',
                    ),
                  ],
                  IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: _selectedTaskIds.isEmpty ? null : _handleDeleteSelected,
                    tooltip: 'Usuń',
                  ),
                ],
              ),
            )
          : AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: _isSelectionMode ? 0 : null,
              child: BottomNavigationBar(
                currentIndex: _currentIndex,
                onTap: _onTabTapped,
                backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
                items: const [
                  BottomNavigationBarItem(
                    icon: Icon(Symbols.view_list),
                    activeIcon: Icon(Symbols.view_list, fill: 1),
                    label: 'Obecne',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Symbols.check_box),
                    activeIcon: Icon(Symbols.check_box, fill: 1),
                    label: 'Wykonane',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Symbols.insert_chart),
                    activeIcon: Icon(Symbols.insert_chart, fill: 1),
                    label: 'Statystyki',
                  ),
                ],
              ),
            ),
    );
  }
}