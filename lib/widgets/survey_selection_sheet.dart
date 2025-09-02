import 'package:flutter/material.dart';

class SurveySelectionSheet extends StatelessWidget {
  final String title;
  final Widget listView;
  final VoidCallback onClose;

  const SurveySelectionSheet({
    super.key,
    required this.title,
    required this.listView,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.3,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SafeArea(
            top: false,
            child: CustomScrollView(
              controller: scrollController,
              slivers: [
                // Handle bar and title
                SliverToBoxAdapter(
                  child: Column(
                    children: [
                      Container(
                        margin: const EdgeInsets.only(top: 8),
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              title,
                            ),
                            IconButton(
                              onPressed: onClose,
                              icon: const Icon(Icons.close),
                            ),
                          ],
                        ),
                      ),
                      Divider(
                        height: 0,
                      ),
                    ],
                  ),
                ),
                // List content
                SliverFillRemaining(
                  hasScrollBody: true,
                  child: listView,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
