import 'package:flutter/material.dart' hide FormFieldBuilder;
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:surveyapp/models/dynamic_form.dart';
import 'package:surveyapp/models/field.dart';
import 'package:surveyapp/widgets/form_field_builder.dart';

class FormSectionContent extends StatelessWidget {
  final Section section;
  final int sectionIndex;
  final Map<String, dynamic> fieldValues;
  final Function(String, dynamic) onFieldValueChanged;
  final bool Function(Field) isFieldVisible;

  const FormSectionContent({
    super.key,
    required this.section,
    required this.sectionIndex,
    required this.fieldValues,
    required this.onFieldValueChanged,
    required this.isFieldVisible,
  });

  @override
  Widget build(BuildContext context) {
    List<Widget> fieldWidgets = section.fields
        .map((field) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: FormFieldBuilder(
                field: field,
                fieldValues: fieldValues,
                onFieldValueChanged: onFieldValueChanged,
                isFieldVisible: isFieldVisible,
              ),
            ))
        .toList();

    // Remove empty widgets (fields that are not visible)
    fieldWidgets.removeWhere((widget) =>
        widget is Padding &&
        (widget.child is SizedBox &&
            (widget.child as SizedBox).height == 0 &&
            (widget.child as SizedBox).width == 0));

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${sectionIndex + 1}. ${section.title}',
                style: ShadTheme.of(context).textTheme.h4,
              ),
              if (section.description?.isNotEmpty == true) ...[
                const SizedBox(height: 8),
                Text(
                  section.description!,
                  style: ShadTheme.of(context).textTheme.muted,
                ),
              ],
            ],
          ),
        ),
        ...fieldWidgets,
      ],
    );
  }
}
