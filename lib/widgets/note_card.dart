import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:lume/pages/settings_page.dart';
import 'package:lume/services/theme_manager.dart';
import '../models/note.dart';
import 'package:intl/intl.dart';
import 'dart:convert';

class NoteCard extends StatelessWidget {
  final Note note;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final bool isSelected;
  final bool isSelecting;
  final VoidCallback onSelect;

  const NoteCard({
    super.key,
    required this.note,
    required this.onTap,
    required this.onDelete,
    this.isSelected = false,
    this.isSelecting = false,
    required this.onSelect,
  });

  String _extractPlainText(String quillContent) {
    try {
      final contentJson = jsonDecode(quillContent);
      if (contentJson is List) {
        return contentJson
            .map((block) {
              if (block is Map && block.containsKey('insert')) {
                return block['insert'] is String ? block['insert'] : '';
              }
              return '';
            })
            .join('');
      }
    } catch (e) {
      return quillContent;
    }
    return quillContent;
  }

  @override
  Widget build(BuildContext context) {
    final plainText = _extractPlainText(note.content);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isActuallySelected = isSelecting && isSelected;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color:
          isActuallySelected
              ? ThemeManager.accentColor.withOpacity(0.2)
              : isDark
              ? Colors.grey[900]
              : Colors.grey[300],
      elevation: isDark ? 0 : 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: isSelecting ? onSelect : onTap,
        onLongPress: onSelect,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      note.title.isNotEmpty ? note.title : '(Sem título)',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color:
                            isSelected
                                ? ThemeManager.accentColor
                                : theme.textTheme.titleMedium?.color,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      plainText.length > 100
                          ? '${plainText.substring(0, 100)}...'
                          : plainText,
                      maxLines: 2,
                      style: TextStyle(
                        color:
                            isSelected
                                ? ThemeManager.accentColor.withOpacity(0.8)
                                : isDark
                                ? Colors.grey[400]
                                : Colors.grey[800],
                      ),
                    ),
                    const SizedBox(height: 8),
                    ValueListenableBuilder(
                      valueListenable: DateFormatManager.dateFormatNotifier,
                      builder: (context, dateFormat, _) {
                        return ValueListenableBuilder(
                          valueListenable: DateFormatManager.timeFormatNotifier,
                          builder: (context, timeFormat, _) {
                            return Text(
                              '${DateFormat(dateFormat, 'pt_BR').format(note.updatedAt)}   ${DateFormat(timeFormat, 'pt_BR').format(note.updatedAt)}',
                              style: TextStyle(
                                color:
                                    isSelected
                                        ? ThemeManager.accentColor.withOpacity(
                                          0.8,
                                        )
                                        : isDark
                                        ? Colors.grey[500]
                                        : Colors.grey[700],
                                fontSize: 12,
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
              if (isSelecting)
                Checkbox(
                  value: isSelected,
                  onChanged: (_) => onSelect(),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                  side: BorderSide(
                    color: isSelected ? ThemeManager.accentColor : Colors.grey,
                    width: 2,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
