import 'package:flutter/material.dart';
import 'package:surveyapp/models/field.dart';
import 'package:surveyapp/utils/region_data.dart';
import 'package:surveyapp/widgets/form_fields.dart';

class FormFieldBuilder extends StatelessWidget {
  final Field field;
  final Map<String, dynamic> fieldValues;
  final Function(String, dynamic) onFieldValueChanged;
  final bool Function(Field) isFieldVisible;

  const FormFieldBuilder({
    super.key,
    required this.field,
    required this.fieldValues,
    required this.onFieldValueChanged,
    required this.isFieldVisible,
  });

  @override
  Widget build(BuildContext context) {
    if (!isFieldVisible(field)) {
      return const SizedBox.shrink();
    }

    void onChanged(dynamic value) {
      onFieldValueChanged(field.id, value);
    }

    final currentValue = fieldValues[field.id];

    switch (field.type) {
      case 'select':
        return SelectInputField(
          key: ValueKey(field.id),
          field: field,
          currentValue: currentValue,
          onChanged: onChanged,
        );
      case 'date':
        return DateInputField(
          key: ValueKey(field.id),
          field: field,
          currentValue: currentValue is DateTime
              ? currentValue
              : DateTime.tryParse(currentValue ?? ''),
          onChanged: onChanged,
        );
      case 'image':
      case 'file':
        return FileInputField(
          key: ValueKey(field.id),
          field: field,
          onImagePicked: (file, fieldId) {
            onFieldValueChanged(fieldId, file);
          },
        );
      case 'number':
        return NumberInputField(
          key: ValueKey(field.id),
          field: field,
          currentValue: currentValue,
          onChanged: onChanged,
        );
      case 'textarea':
        return TextAreaInputField(
          key: ValueKey(field.id),
          field: field,
          currentValue: currentValue,
          onChanged: onChanged,
        );
      case 'text':
        return TextInputField(
          key: ValueKey(field.id),
          field: field,
          currentValue: currentValue,
          onChanged: onChanged,
        );
      case 'tel':
        return PhoneInputField(
          key: ValueKey(field.id),
          field: field,
          currentValue: currentValue,
          onChanged: onChanged,
        );
      case 'email':
        return EmailInputField(
          key: ValueKey(field.id),
          field: field,
          currentValue: currentValue,
          onChanged: onChanged,
        );
      case 'checkbox':
        return CheckboxInputField(
          key: ValueKey(field.id),
          field: field,
          initialValue: currentValue ?? false,
          onChanged: onChanged,
        );
      case 'radio':
        return RadioSelectInputField(
          key: ValueKey(field.id),
          field: field,
          selectedValue: currentValue,
          onChanged: onChanged,
        );
      case 'multiselect':
        return MultiSelectInputField(
          key: ValueKey(field.id),
          field: field,
          currentValues: currentValue,
          onChanged: onChanged,
        );
      case 'district':
      case 'region':
        final regionsDataFuture = RegionData.create('assets/data/regions.json');
        return FutureBuilder<RegionData>(
          key: ValueKey("${field.id}_${fieldValues['region']}"),
          future: regionsDataFuture,
          builder: (ctx, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting &&
                field.type == 'region') {
              return const Center(child: CircularProgressIndicator());
            }
            if (!snapshot.hasData) {
              if (field.type == 'district' &&
                  (fieldValues['region'] == null ||
                      fieldValues['region'] == '')) {
                return const SizedBox.shrink();
              }
              if (!snapshot.hasData && field.type == 'region') {
                return Text("Error loading ${field.label}");
              }
              return const SizedBox.shrink();
            }

            final regionDataProvider = snapshot.data!;
            List<String> data;
            if (field.type == 'region') {
              data = regionDataProvider.getAllRegionLabels();
            } else {
              final selectedRegion = fieldValues['region'] as String?;
              if (selectedRegion == null || selectedRegion.isEmpty) {
                data = [];
              } else {
                data = regionDataProvider.getDistrictsByRegion(selectedRegion);
              }
            }

            final fieldWithDynamicOptions = field.copyWith(options: data);

            return SearchableSelectInputField(
              key: ValueKey("${field.id}_${fieldValues['region']}_options"),
              field: fieldWithDynamicOptions,
              currentValue: currentValue,
              onChanged: onChanged,
            );
          },
        );
      default:
        return Tooltip(
          message: "Unimplemented field type: ${field.type}",
          child: Text("Error: Unknown field type '${field.type}'"),
        );
    }
  }
}
