import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

class FormBottomBar extends StatelessWidget {
  final int currentIndex;
  final int totalSections;
  final VoidCallback onNextSection;
  final VoidCallback onPreviousSection;

  const FormBottomBar({
    super.key,
    required this.currentIndex,
    required this.totalSections,
    required this.onNextSection,
    required this.onPreviousSection,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 4.0,
      child: Stack(
        children: [
          ShadCard(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
            radius: BorderRadius.zero,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ShadButton.ghost(
                  onPressed: currentIndex > 0 ? onPreviousSection : null,
                  leading: const Tooltip(
                    message: "Back",
                    child: Icon(Icons.arrow_back_ios_new_rounded),
                  ),
                  child: const Text('Back'),
                ),
                Text("${currentIndex + 1} / $totalSections"),
                ShadButton.ghost(
                  onPressed: onNextSection,
                  trailing: const Tooltip(
                    message: "Next",
                    child: Icon(Icons.arrow_forward_ios_rounded),
                  ),
                  child: const Text('Next'),
                ),
              ],
            ),
          ),
          LinearProgressIndicator(
            value: (currentIndex + 1) / totalSections,
          ),
        ],
      ),
    );
  }
}
