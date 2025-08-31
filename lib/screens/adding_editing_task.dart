import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:drift/drift.dart' hide Column;
import 'package:intl/intl.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../core/constants.dart';
import '../cubit/task_cubit.dart';
import '../database/database.dart';

enum TaskMode { add, edit }

class AddingEditingTask extends StatefulWidget {
  final TaskMode mode;
  final Task? task;

  const AddingEditingTask({
    super.key,
    required this.mode,
    this.task,
  }) : assert(
          mode == TaskMode.edit ? task != null : true,
          'Task must be provided in edit mode',
        );

  @override
  State<AddingEditingTask> createState() => _AddingEditingTaskState();
}

class _AddingEditingTaskState extends State<AddingEditingTask> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  DateTime? _selectedDate;

  bool get _isEditMode => widget.mode == TaskMode.edit;

  @override
  void initState() {
    super.initState();
    if (_isEditMode) {
      _initializeEditMode();
    }
  }

  void _initializeEditMode() {
    final task = widget.task!;
    _titleController.text = task.title;
    _descriptionController.text = task.description ?? '';
    _selectedDate = task.deadline;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  String? _getDescription() {
    final text = _descriptionController.text.trim();
    return text.isEmpty ? null : text;
  }

  void _submitForm() {
    if (!_formKey.currentState!.validate() || _selectedDate == null) {
      return;
    }

    final cubit = context.read<TasksCubit>();

    if (_isEditMode) {
      _updateTask(cubit);
    } else {
      _addTask(cubit);
    }
  }

  void _updateTask(TasksCubit cubit) {
    final updatedTask = widget.task!.copyWith(
      title: _titleController.text,
      description: Value(_getDescription()),
      deadline: _selectedDate!,
    );
    
    cubit.updateTask(updatedTask);
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  void _addTask(TasksCubit cubit) {
    cubit.addTask(
      _titleController.text,
      _selectedDate!,
      _getDescription(),
    );
    Navigator.of(context).pop();
  }

  Widget _buildTitleField() {
    return Container(
      margin: const EdgeInsets.only(left: AppConstants.spacingHuge),
      child: TextFormField(
        controller: _titleController,
        style: Theme.of(context).textTheme.headlineMedium,
        decoration: const InputDecoration(
          hintText: AppStrings.taskTitleHint,
          border: InputBorder.none,
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return AppStrings.taskTitleRequired;
          }
          return null;
        },
      ),
    );
  }

  Widget _buildDateSelector() {
    return InkWell(
      onTap: () => _selectDate(context),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppConstants.paddingSmall),
        child: Row(
          spacing: AppConstants.spacingDefault,
          children: [
            IconTheme(
              data: IconThemeData(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              child: const Icon(Icons.calendar_month),
            ),
            Text(
              _selectedDate == null
                  ? AppStrings.selectDate
                  : DateFormat(AppConstants.dateFormat).format(_selectedDate!),
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDescriptionField() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppConstants.paddingSmall),
      child: Row(
        spacing: AppConstants.spacingDefault,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 12.0),
            child: IconTheme(
              data: IconThemeData(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              child: const Icon(Symbols.description),
            ),
          ),
          Expanded(
            child: TextFormField(
              controller: _descriptionController,
              style: Theme.of(context).textTheme.bodyLarge,
              maxLines: null,
              keyboardType: TextInputType.multiline,
              decoration: InputDecoration(
                hintText: AppStrings.addDetails,
                hintStyle: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                border: InputBorder.none,
              ),
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
        title: Text(
          _isEditMode ? AppStrings.editTaskTitle : AppStrings.addTaskTitle,
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppConstants.paddingDefault),
            child: FilledButton(
              onPressed: _submitForm,
              child: Text(
                _isEditMode ? AppStrings.saveButton : AppStrings.addButton,
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingDefault),
        child: Form(
          key: _formKey,
          child: Column(
            spacing: AppConstants.spacingDefault,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTitleField(),
              _buildDateSelector(),
              _buildDescriptionField(),
            ],
          ),
        ),
      ),
    );
  }
}