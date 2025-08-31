import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

class SelectionIcon extends StatelessWidget {
  final bool isSelected;
  final VoidCallback onPressed;

  const SelectionIcon({
    super.key,
    required this.isSelected,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: isSelected
          ? Icon(
              Symbols.check_circle,
              color: Theme.of(context).colorScheme.primary,
              fill: 1.0,
            )
          : const Icon(Symbols.circle),
      onPressed: onPressed,
      padding: EdgeInsets.zero,
    );
  }
}