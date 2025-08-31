import 'package:flutter/material.dart';

mixin SelectionModeMixin<T extends StatefulWidget> on State<T> {
  bool _isSelectionMode = false;
  final Set<int> _selectedIds = {};

  bool get isSelectionMode => _isSelectionMode;
  Set<int> get selectedIds => _selectedIds;

  void enterSelectionMode(int firstId, {
    required Function(bool) onSelectionModeChanged,
    required Function(Set<int>) onSelectedIdsChanged,
  }) {
    setState(() {
      _isSelectionMode = true;
      _selectedIds.clear();
      _selectedIds.add(firstId);
    });
    onSelectionModeChanged(true);
    onSelectedIdsChanged(_selectedIds);
  }

  void exitSelectionMode() {
    setState(() {
      _isSelectionMode = false;
      _selectedIds.clear();
    });
  }

  void toggleSelection(int id, {
    required Function(Set<int>) onSelectedIdsChanged,
  }) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
    onSelectedIdsChanged(_selectedIds);
  }
}