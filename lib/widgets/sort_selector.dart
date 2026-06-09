import 'package:flutter/material.dart';
import '../utils/constants.dart';
import '../utils/l10n.dart';

class SortSelector extends StatelessWidget {
  final SortMode currentMode;
  final ValueChanged<SortMode> onChanged;

  const SortSelector({
    super.key,
    required this.currentMode,
    required this.onChanged,
  });

  PopupMenuItem<SortMode> _item(BuildContext context, SortMode mode, IconData icon, String zh, String en) {
    final isSelected = currentMode == mode;
    return PopupMenuItem<SortMode>(
      value: mode,
      child: Row(
        children: [
          Icon(icon, size: 20, color: isSelected ? AppConstants.primaryColor : Colors.grey),
          const SizedBox(width: 12),
          Text(context.t(zh, en),
            style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, color: isSelected ? AppConstants.primaryColor : null)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final items = [
      _item(context, SortMode.alphabeticalAsc, Icons.sort_by_alpha, '字母顺序 (A-Z)', 'Alphabetical (A-Z)'),
      _item(context, SortMode.alphabeticalDesc, Icons.sort_by_alpha, '字母顺序 (Z-A)', 'Alphabetical (Z-A)'),
      _item(context, SortMode.importTimeNewest, Icons.access_time, '导入时间 (最新)', 'Import time (Newest)'),
      _item(context, SortMode.importTimeOldest, Icons.access_time, '导入时间 (最早)', 'Import time (Oldest)'),
    ];

    return GestureDetector(
      onTap: () async {
        final result = await showMenu<SortMode>(
          context: context,
          position: RelativeRect.fromLTRB(
            MediaQuery.of(context).size.width - 20,
            kToolbarHeight + MediaQuery.of(context).padding.top + 10,
            0,
            0,
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          items: items,
        );
        if (result != null) onChanged(result);
      },
      child: const Padding(
        padding: EdgeInsets.all(12),
        child: Icon(Icons.sort, size: 20),
      ),
    );
  }
}
