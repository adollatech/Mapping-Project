import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart' show XFile;
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:surveyapp/models/field.dart';
import 'package:surveyapp/utils/field_validation.dart';
import 'package:surveyapp/widgets/image_upload_field.dart';

// --- Helper Functions ---

/// Validates a given value against a field's validation rules.
///
/// Returns an error message if any validation fails, otherwise returns null.
String? _validateField(dynamic value, FieldValidation fieldValidation) {
  final validations = fieldValidation.validate(value);
  if (validations.isNotEmpty) {
    for (var validation in validations) {
      if (validation.condition) {
        return validation.message;
      }
    }
  }
  return null;
}

// --- Base Input Field ---

/// A base class for text input fields, providing common functionality.
class BaseTextInputField extends StatelessWidget {
  const BaseTextInputField({
    super.key,
    required this.field,
    required this.onChanged,
    this.keyboardType = TextInputType.text,
    this.obscureText = false,
    this.trailing,
    this.currentValue,
  });

  final Field field;
  final TextInputType keyboardType;
  final Function(String) onChanged;
  final bool obscureText;
  final Widget? trailing;
  final dynamic currentValue;

  @override
  Widget build(BuildContext context) {
    return ShadInputFormField(
      id: field.id,
      label: Text(field.label),
      placeholder: Text(field.placeholder ?? ''),
      keyboardType: keyboardType,
      onChanged: onChanged,
      obscureText: obscureText,
      trailing: trailing,
      initialValue: currentValue,
      validator: (value) =>
          _validateField(value, FieldValidation(validation: field.validation)),
    );
  }
}

// --- Specialized Text Input Fields ---

class TextInputField extends StatelessWidget {
  const TextInputField({
    super.key,
    required this.field,
    required this.onChanged,
    this.currentValue,
  });
  final Field field;
  final Function(String) onChanged;
  final String? currentValue;

  @override
  Widget build(BuildContext context) {
    return BaseTextInputField(
      field: field,
      onChanged: onChanged,
      currentValue: currentValue,
    );
  }
}

class PhoneInputField extends StatelessWidget {
  const PhoneInputField(
      {super.key,
      required this.field,
      required this.onChanged,
      this.currentValue});
  final Field field;
  final Function(String) onChanged;
  final String? currentValue;

  @override
  Widget build(BuildContext context) {
    return BaseTextInputField(
      field: field,
      onChanged: onChanged,
      keyboardType: TextInputType.phone,
      currentValue: currentValue,
    );
  }
}

class EmailInputField extends StatelessWidget {
  const EmailInputField(
      {super.key,
      required this.field,
      required this.onChanged,
      this.currentValue});
  final Field field;
  final Function(String) onChanged;
  final String? currentValue;

  @override
  Widget build(BuildContext context) {
    return BaseTextInputField(
      field: field,
      onChanged: onChanged,
      keyboardType: TextInputType.emailAddress,
      currentValue: currentValue,
    );
  }
}

class NumberInputField extends StatelessWidget {
  const NumberInputField(
      {super.key,
      required this.field,
      required this.onChanged,
      this.currentValue});
  final Field field;
  final Function(double) onChanged;
  final String? currentValue;

  @override
  Widget build(BuildContext context) {
    return BaseTextInputField(
      field: field,
      onChanged: (v) {
        final parsedValue = double.tryParse(v);
        if (parsedValue != null) {
          onChanged(parsedValue);
        }
      },
      keyboardType: TextInputType.number,
      currentValue: currentValue,
    );
  }
}

class PasswordInputField extends StatefulWidget {
  const PasswordInputField(
      {super.key,
      required this.field,
      required this.onChanged,
      this.currentValue});
  final Field field;
  final Function(String) onChanged;
  final String? currentValue;

  @override
  State<PasswordInputField> createState() => _PasswordInputFieldState();
}

class _PasswordInputFieldState extends State<PasswordInputField> {
  bool _showPassword = false;

  @override
  Widget build(BuildContext context) {
    return BaseTextInputField(
      field: widget.field,
      onChanged: widget.onChanged,
      obscureText: !_showPassword,
      trailing: ShadIconButton.ghost(
        icon: Icon(_showPassword ? Icons.visibility : Icons.visibility_off),
        onPressed: () => setState(() => _showPassword = !_showPassword),
      ),
      currentValue: widget.currentValue,
    );
  }
}

// --- Date Input Field ---

class DateInputField extends StatelessWidget {
  const DateInputField(
      {super.key,
      required this.field,
      required this.onChanged,
      this.currentValue});
  final Field field;
  final Function(DateTime?) onChanged;
  final DateTime? currentValue;

  @override
  Widget build(BuildContext context) {
    return ShadDatePickerFormField(
      id: field.id,
      label: Text(field.label),
      width: MediaQuery.of(context).size.width * 0.9,
      onChanged: onChanged,
      initialValue: currentValue,
      validator: (value) =>
          _validateField(value, FieldValidation(validation: field.validation)),
    );
  }
}

// --- Select Input Fields ---

class SelectInputField extends StatelessWidget {
  const SelectInputField(
      {super.key,
      required this.field,
      required this.onChanged,
      this.currentValue});
  final Field field;
  final Function(String?) onChanged;
  final String? currentValue;

  @override
  Widget build(BuildContext context) {
    return ShadSelectFormField<String>(
      id: field.id,
      label: Text(field.label),
      minWidth: MediaQuery.of(context).size.width * 0.9,
      maxWidth: MediaQuery.of(context).size.width * 0.95,
      options: field.options!
          .map((val) => ShadOption(value: val, child: Text(val)))
          .toList(),
      selectedOptionBuilder: (context, value) =>
          value == 'none' ? Text(field.label) : Text(value),
      placeholder: Text(field.placeholder ?? 'Select an option'),
      onChanged: onChanged,
      initialValue: currentValue,
      validator: (value) =>
          _validateField(value, FieldValidation(validation: field.validation)),
    );
  }
}

class SearchableSelectInputField extends StatefulWidget {
  const SearchableSelectInputField(
      {super.key,
      required this.field,
      required this.onChanged,
      this.currentValue});
  final Field field;
  final Function(String?) onChanged;
  final String? currentValue;

  @override
  State<SearchableSelectInputField> createState() =>
      _SearchableSelectInputFieldState();
}

class _SearchableSelectInputFieldState
    extends State<SearchableSelectInputField> {
  late List<String> _options;
  String _searchValue = '';

  List<String> get _filteredOptions => _options
      .where(
          (option) => option.toLowerCase().contains(_searchValue.toLowerCase()))
      .toList();

  @override
  void initState() {
    super.initState();
    _options = widget.field.options!;
  }

  @override
  Widget build(BuildContext context) {
    return ShadSelectFormField<String>.withSearch(
      id: widget.field.id,
      label: Text(widget.field.label),
      placeholder: Text(widget.field.label),
      minWidth: double.infinity,
      initialValue: widget.currentValue,
      onSearchChanged: (value) => setState(() => _searchValue = value),
      searchPlaceholder: const Text('Search...'),
      options: [
        if (_filteredOptions.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Text('No match found'),
          ),
        ..._filteredOptions.map(
          (option) => ShadOption(
            value: option,
            child: Text(option),
          ),
        ),
      ],
      selectedOptionBuilder: (context, value) => Text(value),
      onChanged: widget.onChanged,
    );
  }
}

class MultiSelectInputField extends StatelessWidget {
  const MultiSelectInputField(
      {super.key,
      required this.field,
      required this.onChanged,
      this.currentValues});
  final Field field;
  final Function(Set<String>?) onChanged;
  final Set<String>? currentValues;

  @override
  Widget build(BuildContext context) {
    return ShadSelectMultipleFormField(
      id: field.id,
      label: Text(field.label),
      initialValue: currentValues,
      onChanged: onChanged,
      allowDeselection: true,
      closeOnSelect: false,
      options: field.options!
          .map((val) => ShadOption(value: val, child: Text(val)))
          .toList(),
      selectedOptionsBuilder: (context, values) =>
          values.isEmpty ? Text(field.label) : Text(values.join(', ')),
      placeholder: Text(field.placeholder ?? 'Select options'),
      validator: (value) =>
          _validateField(value, FieldValidation(validation: field.validation)),
    );
  }
}

class RadioSelectInputField extends StatelessWidget {
  const RadioSelectInputField({
    super.key,
    required this.field,
    required this.onChanged,
    this.selectedValue,
  });

  final Field field;
  final String? selectedValue;
  final void Function(String?) onChanged;

  @override
  Widget build(BuildContext context) {
    return ShadRadioGroupFormField<String>(
      id: field.id,
      label: Text(field.label),
      items: field.options!.map(
        (option) => ShadRadio(
          value: option,
          label: Text(option),
        ),
      ),
      initialValue: selectedValue,
      onChanged: onChanged,
      validator: (value) =>
          _validateField(field, FieldValidation(validation: field.validation)),
    );
  }
}

class CheckboxInputField extends StatelessWidget {
  const CheckboxInputField({
    super.key,
    required this.field,
    required this.onChanged,
    this.initialValue = false,
  });

  final Field field;
  final Function(bool) onChanged;
  final bool initialValue;

  @override
  Widget build(BuildContext context) {
    return ShadCheckboxFormField(
      id: field.id,
      initialValue: initialValue,
      inputLabel: Text(field.label),
      label: Text(field.label),
      onChanged: onChanged,
      validator: (value) =>
          _validateField(field, FieldValidation(validation: field.validation)),
    );
  }
}

class TextAreaInputField extends StatelessWidget {
  const TextAreaInputField({
    super.key,
    required this.field,
    required this.onChanged,
    this.currentValue,
  });

  final Field field;
  final Function(String) onChanged;
  final String? currentValue;

  @override
  Widget build(BuildContext context) {
    return ShadTextareaFormField(
      id: field.id,
      label: Text(field.label),
      placeholder: Text(field.placeholder ?? ''),
      onChanged: onChanged,
      // initialValue: currentValue,
      validator: (value) =>
          _validateField(value, FieldValidation(validation: field.validation)),
    );
  }
}

class FileInputField extends StatelessWidget {
  const FileInputField({
    super.key,
    required this.field,
    required this.onImagePicked,
  });

  final Field field;
  final Function(XFile file, String fieldId) onImagePicked;

  @override
  Widget build(BuildContext context) {
    return ImageUploadField(
      label: field.label,
      onImagePicked: (image) => onImagePicked(image, field.id),
    );
  }
}
