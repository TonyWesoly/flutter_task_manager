import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../core/constants.dart';
import '../cubit/task_cubit.dart';
import '../widgets/confirmation_dialog.dart';
import 'completed_tasks_screen.dart';
import 'current_tasks_screen.dart';
import 'statistics_screen.dart';

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
  
  static const List<String> _titles = [
    AppStrings.currentTasksTitle,
    AppStrings.completedTasksTitle,
    AppStrings.statisticsTitle,
  ];

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
      const StatisticsScreen(),
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

    switch (_currentIndex) {
      case 0:
        _currentTasksKey.currentState?.exitSelectionMode();
        break;
      case 1:
        _completedTasksKey.currentState?.exitSelectionMode();
        break;
    }
  }

  void _onTabTapped(int index) {
    if (_isSelectionMode) {
      _exitSelectionMode();
    }

    setState(() {
      _currentIndex = index;
    });

    _loadDataForTab(index);
  }

  void _loadDataForTab(int index) {
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
    ConfirmationDialog.show(
      context: context,
      title: AppStrings.deleteMultipleTasksTitle,
      content: 'Zostanie usuniętych ${_selectedTaskIds.length} zadań.',
      confirmText: AppStrings.deleteButton,
      confirmTextColor: Theme.of(context).colorScheme.error,
      onConfirm: () {
        final cubit = context.read<TasksCubit>();
        if (_currentIndex == 0) {
          cubit.deleteMultipleTasks(_selectedTaskIds.toList());
        } else {
          cubit.deleteMultipleCompletedTasks(_selectedTaskIds.toList());
        }
        _exitSelectionMode();
      },
    );
  }

PreferredSizeWidget _buildSelectionAppBar() {
  return AppBar(
    title: Text('${AppStrings.selectedCount}${_selectedTaskIds.length}'),
    leading: IconButton(
      icon: const Icon(Icons.close),
      onPressed: _exitSelectionMode,
    ),
  );
}

PreferredSizeWidget _buildNormalAppBar() {
  return AppBar(
    title: Text(_titles[_currentIndex]),
  );
}

  Widget _buildSelectionBottomBar() {
    return BottomAppBar(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          if (_currentIndex == 0)
            IconButton(
              icon: const Icon(Icons.check_circle_outline),
              onPressed: _selectedTaskIds.isEmpty ? null : _handleCompleteSelected,
              tooltip: AppStrings.markAsCompleteTooltip,
            )
          else if (_currentIndex == 1)
            IconButton(
              icon: const Icon(Icons.undo),
              onPressed: _selectedTaskIds.isEmpty ? null : _handleRestoreSelected,
              tooltip: AppStrings.restoreTooltip,
            ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: _selectedTaskIds.isEmpty ? null : _handleDeleteSelected,
            tooltip: AppStrings.deleteTooltip,
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationBar() {
    return NavigationBar(
      destinations: const [
        NavigationDestination(
          icon: Icon(Symbols.view_list),
          selectedIcon: Icon(Symbols.view_list, fill: 1),
          label: 'Obecne',
        ),
        NavigationDestination(
          icon: Icon(Symbols.check_box),
          selectedIcon: Icon(Symbols.check_box, fill: 1),
          label: 'Wykonane',
        ),
        NavigationDestination(
          icon: Icon(Symbols.insert_chart),
          selectedIcon: Icon(Symbols.insert_chart, fill: 1),
          label: 'Statystyki',
        ),
      ],
      selectedIndex: _currentIndex,
      onDestinationSelected: _onTabTapped,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _isSelectionMode ? _buildSelectionAppBar() : _buildNormalAppBar(),
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: _isSelectionMode 
          ? _buildSelectionBottomBar() 
          : _buildNavigationBar(),
    );
  }
}