import 'package:flutter/material.dart';
import '../core/constants.dart';

class ConfirmationDialog extends StatelessWidget {
  final String title;
  final String? content;
  final String confirmText;
  final String cancelText;
  final VoidCallback onConfirm;
  final Color? confirmTextColor;

  const ConfirmationDialog({
    super.key,
    required this.title,
    this.content,
    required this.confirmText,
    this.cancelText = AppStrings.cancelButton,
    required this.onConfirm,
    this.confirmTextColor,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title),
      content: content != null ? Text(content!) : null,
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(cancelText),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
            onConfirm();
          },
          child: Text(
            confirmText,
            style: confirmTextColor != null
                ? TextStyle(color: confirmTextColor)
                : null,
          ),
        ),
      ],
    );
  }

  static Future<void> show({
    required BuildContext context,
    required String title,
    String? content,
    required String confirmText,
    String cancelText = AppStrings.cancelButton,
    required VoidCallback onConfirm,
    Color? confirmTextColor,
  }) {
    return showDialog(
      context: context,
      builder: (context) => ConfirmationDialog(
        title: title,
        content: content,
        confirmText: confirmText,
        cancelText: cancelText,
        onConfirm: onConfirm,
        confirmTextColor: confirmTextColor,
      ),
    );
  }
}