import 'package:flutter/material.dart';
import 'package:lume/services/theme_manager.dart';

class CategoryFilterChip extends StatelessWidget {
  final String category;
  final bool selected;
  final ValueChanged<bool> onSelected;

  const CategoryFilterChip({
    super.key,
    required this.category,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: FilterChip(
        checkmarkColor: ThemeManager.accentColor,
        label: Text(category),
        selected: selected,
        onSelected: onSelected,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        selectedColor: Theme.of(context).scaffoldBackgroundColor,
        surfaceTintColor: ThemeManager.accentColor,
        labelStyle: TextStyle(
          color: selected ? ThemeManager.accentColor : Colors.grey,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        side: BorderSide(
          color: selected ? ThemeManager.accentColor : Colors.grey[700]!,
          width: 1,
        ),
      ),
    );
  }
}
