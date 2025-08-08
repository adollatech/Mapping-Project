import 'package:flutter/material.dart';
import 'package:surveyapp/models/dynamic_form.dart';
import 'package:surveyapp/models/field.dart';
import 'package:surveyapp/widgets/form_section_content.dart';
import 'package:surveyapp/widgets/form_side_bar.dart';
import 'package:surveyapp/widgets/form_bottom_bar.dart';

class FormRenderer extends StatelessWidget {
  final DynamicForm form;
  final int currentIndex;
  final Map<String, dynamic> fieldValues;
  final Function(String, dynamic) onFieldValueChanged;
  final Function(int) onGoToSection;
  final VoidCallback onNextSection;
  final VoidCallback onPreviousSection;
  final bool Function(Field) isFieldVisible;
  final bool isTabletOrLarger;

  const FormRenderer({
    super.key,
    required this.form,
    required this.currentIndex,
    required this.fieldValues,
    required this.onFieldValueChanged,
    required this.onGoToSection,
    required this.onNextSection,
    required this.onPreviousSection,
    required this.isFieldVisible,
    this.isTabletOrLarger = false,
  });

  @override
  Widget build(BuildContext context) {
    if (form.sections.isEmpty) {
      return const Center(
        child: Text("Form is empty.", key: ValueKey("adapter_form_empty")),
      );
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Row(
        children: [
          // Sidebar for tablets and larger devices
          if (isTabletOrLarger)
            FormSidebar(
              sections: form.sections,
              currentIndex: currentIndex,
              onGoToSection: onGoToSection,
              onNextSection: onNextSection,
              onPreviousSection: onPreviousSection,
            ),

          // Main content area
          Expanded(
            child: Stack(
              children: [
                // Form content
                SingleChildScrollView(
                  child: Container(
                    padding: EdgeInsets.only(
                      left: 16.0,
                      right: 16.0,
                      bottom: isTabletOrLarger
                          ? 20.0
                          : 80.0, // More bottom padding on mobile for bottom bar
                      top: 16.0,
                    ),
                    alignment: Alignment.topCenter,
                    constraints: BoxConstraints(
                        maxWidth: 600,
                        minHeight: MediaQuery.of(context).size.height - 80),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      transitionBuilder: (child, animation) =>
                          FadeTransition(opacity: animation, child: child),
                      child: Container(
                        key: ValueKey<int>(currentIndex),
                        alignment: Alignment.topLeft,
                        child: FormSectionContent(
                          section: form.sections[currentIndex],
                          sectionIndex: currentIndex,
                          fieldValues: fieldValues,
                          onFieldValueChanged: onFieldValueChanged,
                          isFieldVisible: isFieldVisible,
                        ),
                      ),
                    ),
                  ),
                ),

                // Bottom bar for mobile devices
                if (!isTabletOrLarger)
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: FormBottomBar(
                      currentIndex: currentIndex,
                      totalSections: form.sections.length,
                      onNextSection: onNextSection,
                      onPreviousSection: onPreviousSection,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
