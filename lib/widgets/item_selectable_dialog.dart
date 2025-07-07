import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

class ItemSelectableDialog<T> extends StatelessWidget {
  const ItemSelectableDialog(
      {super.key,
      required this.label,
      required this.dialogTitle,
      required this.items,
      required this.itemBuilder,
      required this.onItemSelected,
      this.description = '',
      this.leading});
  final String label;
  final String dialogTitle;
  final List<T> items;
  final String description;
  final Widget Function(T item) itemBuilder;
  final void Function(T item) onItemSelected;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(label),
      leading: leading,
      onTap: () {
        showShadDialog(
          context: context,
          builder: (context) => ShadDialog(
            title: Text(dialogTitle),
            description: Text(description),
            gap: 2,
            child: Material(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  return ListTile(
                    title: itemBuilder(item),
                    selected: label == item.toString(),
                    onTap: () {
                      onItemSelected(item);
                      Navigator.of(context).pop();
                    },
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}
