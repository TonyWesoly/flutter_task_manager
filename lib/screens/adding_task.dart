import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../cubit/task_cubit.dart';

class AddingTask extends StatefulWidget {
  const AddingTask({super.key});

  @override
  State<AddingTask> createState() => _AddingTaskState();
}

class _AddingTaskState extends State<AddingTask> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  DateTime? _selectedDate;

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
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
      // Add task using cubit
      context.read<TasksCubit>().addTask(_titleController.text, _selectedDate!);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: FilledButton(
                    onPressed: _submitForm,
                    child: const Text('Zapisz'),
                  ),
          ),
                
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Form(
          key: _formKey,
          child: Column(
            spacing: 10.0,
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
