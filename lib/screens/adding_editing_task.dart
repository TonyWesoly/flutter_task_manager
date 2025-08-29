import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_task_manager/database/database.dart';
import 'package:intl/intl.dart';
import '../cubit/task_cubit.dart';

enum TaskMode { add, edit }

class AddingEditingTask extends StatefulWidget {
  final TaskMode mode;
  final Task? task;

  const AddingEditingTask({
    super.key,
    required this.mode,
    this.task,
  }) : assert(mode == TaskMode.edit ? task != null : true,
             'Task must be provided in edit mode');

  @override
  State<AddingEditingTask> createState() => _AddingEditingTaskState();
}

class _AddingEditingTaskState extends State<AddingEditingTask> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    if (widget.mode == TaskMode.edit) {
      _titleController.text = widget.task!.title;
      _selectedDate = widget.task!.deadline;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
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

  void _submitForm() {
    if (_formKey.currentState!.validate() && _selectedDate != null) {
      if (widget.mode == TaskMode.edit) {
        final updatedTask = widget.task!.copyWith(
          title: _titleController.text,
          deadline: _selectedDate!,
        );
        context.read<TasksCubit>().updateTask(updatedTask);
        Navigator.of(context).popUntil((route) => route.isFirst);
      } else {
        context.read<TasksCubit>().addTask(
          _titleController.text,
          _selectedDate!,
        );
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.mode == TaskMode.edit ? 'Edytuj zadanie' : 'Dodaj zadanie'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: FilledButton(
              onPressed: _submitForm,
              child: Text(widget.mode == TaskMode.edit ? 'Zapisz' : 'Dodaj'),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Form(
          key: _formKey,
          child: Column(
            spacing: 16.0,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                margin: const EdgeInsets.only(left: 38.0),
                child: TextFormField(
                  controller: _titleController,
                  style: Theme.of(context).textTheme.headlineMedium,
                  decoration: const InputDecoration(
                    hintText: 'Tytuł zadania',
                    border: InputBorder.none,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Proszę wpisać tytuł zadania';
                    }
                    return null;
                  },
                ),
              ),
              InkWell(
                onTap: () => _selectDate(context),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Row(
                    spacing: 16.0,
                    children: [
                      IconTheme(
                        data: IconThemeData(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        child: const Icon(Icons.calendar_month),
                      ),
                      Text(
                        style: Theme.of(context).textTheme.bodyLarge,
                        _selectedDate == null
                            ? 'Wybierz datę'
                            : DateFormat('dd-MM-yyyy').format(_selectedDate!),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
