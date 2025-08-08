import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:surveyapp/models/dynamic_form.dart';

class FormSidebar extends StatelessWidget {
  final List<Section> sections;
  final int currentIndex;
  final Function(int) onGoToSection;
  final VoidCallback onNextSection;
  final VoidCallback onPreviousSection;

  const FormSidebar({
    super.key,
    required this.sections,
    required this.currentIndex,
    required this.onGoToSection,
    required this.onNextSection,
    required this.onPreviousSection,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: ShadTheme.of(context).colorScheme.card,
        border: Border(
          right: BorderSide(
            color: ShadTheme.of(context).colorScheme.border,
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: ShadTheme.of(context).colorScheme.border,
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.assignment_outlined,
                  color: ShadTheme.of(context).colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Progress',
                    style: ShadTheme.of(context).textTheme.h4,
                  ),
                ),
              ],
            ),
          ),

          // Progress indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Section ${currentIndex + 1} of ${sections.length}',
                  style: ShadTheme.of(context).textTheme.muted,
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: (currentIndex + 1) / sections.length,
                  backgroundColor: ShadTheme.of(context)
                      .colorScheme
                      .muted
                      .withValues(alpha: 0.3),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    ShadTheme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),

          // Section stepper
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: sections.length,
              itemBuilder: (context, index) {
                final section = sections[index];
                final isActive = index == currentIndex;
                final isCompleted = index < currentIndex;
                final isAccessible = index <=
                    currentIndex; // Can only access current and previous sections

                return Container(
                  margin: const EdgeInsets.only(bottom: 4),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: isAccessible ? () => onGoToSection(index) : null,
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 16),
                        decoration: BoxDecoration(
                          color: isActive
                              ? ShadTheme.of(context)
                                  .colorScheme
                                  .primary
                                  .withValues(alpha: 0.1)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            // Step indicator
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: isCompleted
                                    ? ShadTheme.of(context).colorScheme.primary
                                    : isActive
                                        ? ShadTheme.of(context)
                                            .colorScheme
                                            .primary
                                        : ShadTheme.of(context)
                                            .colorScheme
                                            .muted
                                            .withValues(alpha: 0.3),
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: isCompleted
                                    ? Icon(
                                        Icons.check,
                                        color: ShadTheme.of(context)
                                            .colorScheme
                                            .primaryForeground,
                                        size: 16,
                                      )
                                    : Text(
                                        '${index + 1}',
                                        style: TextStyle(
                                          color: isActive
                                              ? ShadTheme.of(context)
                                                  .colorScheme
                                                  .primaryForeground
                                              : ShadTheme.of(context)
                                                  .colorScheme
                                                  .mutedForeground,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                              ),
                            ),
                            const SizedBox(width: 12),

                            // Section title
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    section.title,
                                    style: TextStyle(
                                      color: isActive
                                          ? ShadTheme.of(context)
                                              .colorScheme
                                              .primary
                                          : isAccessible
                                              ? ShadTheme.of(context)
                                                  .colorScheme
                                                  .foreground
                                              : ShadTheme.of(context)
                                                  .colorScheme
                                                  .mutedForeground,
                                      fontSize: 14,
                                      fontWeight: isActive
                                          ? FontWeight.w600
                                          : FontWeight.w500,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (section.description?.isNotEmpty ==
                                      true) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      section.description!,
                                      style: ShadTheme.of(context)
                                          .textTheme
                                          .muted
                                          .copyWith(
                                            fontSize: 12,
                                          ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ],
                              ),
                            ),

                            // Arrow indicator for active section
                            if (isActive)
                              Icon(
                                Icons.arrow_forward_ios,
                                size: 12,
                                color:
                                    ShadTheme.of(context).colorScheme.primary,
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Action buttons
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: ShadTheme.of(context).colorScheme.border,
                  width: 1,
                ),
              ),
            ),
            child: Column(
              children: [
                // Navigation buttons
                Row(
                  spacing: 8,
                  children: [
                    Expanded(
                      child: ShadButton.ghost(
                        onPressed: currentIndex > 0 ? onPreviousSection : null,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.arrow_back_ios, size: 16),
                            const SizedBox(width: 4),
                            const Text('Back'),
                          ],
                        ),
                      ),
                    ),
                    Expanded(
                      child: ShadButton.ghost(
                        onPressed: onNextSection,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('Next'),
                            const SizedBox(width: 4),
                            Icon(Icons.arrow_forward_ios, size: 16),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
