import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart'; // Assuming this is your UI library
import 'package:surveyapp/models/dynamic_form.dart';
import 'package:surveyapp/models/field.dart'; // Ensure this points to your updated field.dart
import 'package:surveyapp/utils/region_data.dart';
import 'package:surveyapp/utils/utils.dart';
import 'package:surveyapp/widgets/form_fields.dart'; // Your custom form field widgets

class FormAdapter extends StatefulWidget {
  final DynamicForm form;

  const FormAdapter({super.key, required this.form});

  @override
  State<FormAdapter> createState() => _FormAdapterState();
}

class _FormAdapterState extends State<FormAdapter> {
  int _currentIndex = 0;
  List<Widget> _builtSections = []; // Initialize as empty
  final Map<String, dynamic> _fieldValues = {};
  final _formKey = GlobalKey<ShadFormState>();
  bool _isInitialBuildDone =
      false; // Flag to ensure _buildSections runs once after context is available

  @override
  void initState() {
    super.initState();
    _initializeFieldValues();
    // DO NOT call _buildSections() here if it uses context
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Check a flag to ensure this part of initialization runs only once,
    // or if specific dependencies change that require rebuilding sections.
    // For this case, once after initState is usually sufficient for initial build.
    if (!_isInitialBuildDone) {
      _buildSections(); // Now it's safe to call, context is available
      _isInitialBuildDone = true;
    }
  }

  // Initialize field values with defaults if provided
  void _initializeFieldValues() {
    for (var section in widget.form.sections) {
      for (var field in section.fields) {
        if (field.defaultValue != null) {
          _fieldValues[field.id] = field.defaultValue;
        }
        // For checkboxes, a common default might be false if not explicitly set
        if (field.type == 'checkbox' && field.defaultValue == null) {
          _fieldValues[field.id] = false;
        }
      }
    }
  }

  // Rebuilds the section widgets based on current field values
  void _buildSections() {
    // Ensure context is available if called from elsewhere later (though less likely for this method)
    if (!mounted) return;

    _builtSections = widget.form.sections
        .map((section) =>
            _buildSectionUI(section, widget.form.sections.indexOf(section)))
        .toList();
    // If _buildSections is called from setState, no need to call setState again here.
    // If it's called from didChangeDependencies for the first time,
    // the subsequent build() call will pick up the changes.
  }

  void _onFieldValueChanged(String fieldId, dynamic value) {
    setState(() {
      _fieldValues[fieldId] = value;
      _buildSections(); // This is fine here, as setState triggers a build where context is valid
      _clearDependentFieldValues(fieldId, value);
    });
    log("Field Values: $_fieldValues");
  }

  void _clearDependentFieldValues(String changedFieldId, dynamic newValue) {
    for (var section in widget.form.sections) {
      for (var field in section.fields) {
        if (field.dependsOn?.fieldId == changedFieldId) {
          if (newValue != field.dependsOn!.showWhenValue) {
            // If the parent's new value no longer meets the condition
            // for this dependent field to show, clear its value.
            if (_fieldValues.containsKey(field.id)) {
              // Check if it exists before trying to remove or set to null
              _fieldValues.remove(field.id);
              // You might want to set it to null or an appropriate default
              // _fieldValues[field.id] = null;
              log("Cleared value for dependent field: ${field.id}");
            }
          }
        }
      }
    }
  }

  void _nextSection() {
    if (_formKey.currentState?.validate() ?? false) {
      // Validate before going next
      if (_currentIndex < _builtSections.length - 1) {
        setState(() => _currentIndex++);
      }
    } else {
      // Optionally show a message if validation fails
      showSnackBar(context, "Please correct the errors before proceeding.");
    }
  }

  void _previousSection() {
    if (_currentIndex > 0) {
      setState(() => _currentIndex--);
    }
  }

  bool _isFieldVisible(Field field) {
    if (field.dependsOn == null) {
      return true; // Always visible if no dependencies
    }
    final dependentOnFieldId = field.dependsOn!.fieldId;
    final showWhenValue = field.dependsOn!.showWhenValue;
    final actualValue = _fieldValues[dependentOnFieldId];

    // Handle initial state where dependentOnFieldId might not be in _fieldValues yet
    // or if its value is null.
    if (actualValue == null) {
      // If showWhenValue is also null, and actualValue is null, consider it a match.
      // Or if showWhenValue is specifically looking for null (though less common for UI triggers).
      return showWhenValue == null;
    }

    return actualValue == showWhenValue;
  }

  Widget _buildFieldUI(Field field) {
    if (!_isFieldVisible(field)) {
      return const SizedBox.shrink();
    }

    // Common onChanged callback
    void onChanged(dynamic value) {
      _onFieldValueChanged(field.id, value);
    }

    // It's good practice to provide the current value to the field widgets
    // so they can display it, especially for radio buttons or selects.
    final currentValue = _fieldValues[field.id];

    switch (field.type) {
      case 'select':
        return SelectInputField(
          key: ValueKey(field.id), // Important for state preservation
          field: field,
          currentValue: currentValue,
          onChanged: onChanged,
        );
      case 'date':
        return DateInputField(
          key: ValueKey(field.id),
          field: field,
          currentValue: currentValue,
          onChanged: onChanged,
        );
      case 'image':
      case 'file':
        return FileInputField(
          key: ValueKey(field.id),
          field: field,
          // FileInputField might have a different callback structure
          onImagePicked: (file, fieldId) {
            // Assuming fieldId is passed back
            _onFieldValueChanged(fieldId, file);
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
          initialValue:
              currentValue ?? false, // Checkboxes often need a boolean
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
        // This part remains complex due to its async nature and how options are populated.
        // Ensure that _fieldValues['region'] is correctly updated for 'district' to work.
        final regionsDataFuture = RegionData.create('assets/data/regions.json');
        return FutureBuilder<RegionData>(
          key: ValueKey(
              "${field.id}_${_fieldValues['region']}"), // Key might need to depend on region value for districts
          future: regionsDataFuture,
          builder: (ctx, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting &&
                field.type == 'region') {
              // Show a loader only for the initial load of regions if needed
              return const Center(child: CircularProgressIndicator());
            }
            if (!snapshot.hasData) {
              // Return a placeholder or empty box if data isn't ready,
              // or if it's a district and the region isn't selected yet.
              if (field.type == 'district' &&
                  (_fieldValues['region'] == null ||
                      _fieldValues['region'] == '')) {
                // If it's a district and no region is selected, it shouldn't show options or be enabled.
                // You might return a disabled field or a message.
                // For now, returning SizedBox.shrink if the region (its dependency) isn't set.
                // This specific dependency should ideally also be handled by the `dependsOn` logic.
                // For simplicity here, we assume 'district' implicitly depends on 'region'.
                return SizedBox.shrink();
              }
              if (!snapshot.hasData && field.type == 'region') {
                return Text(
                    "Error loading ${field.label}"); // Or some error indicator
              }
              return SizedBox
                  .shrink(); // General case if no data and not handled above
            }

            final regionDataProvider = snapshot.data!;
            List<String> data;
            if (field.type == 'region') {
              data = regionDataProvider.getAllRegionLabels();
            } else {
              // district
              final selectedRegion = _fieldValues['region'] as String?;
              if (selectedRegion == null || selectedRegion.isEmpty) {
                data = []; // No region selected, so no districts to show
              } else {
                data = regionDataProvider.getDistrictsByRegion(selectedRegion);
              }
            }

            // Create a new Field instance with updated options
            final fieldWithDynamicOptions = field.copyWith(options: data);

            return SearchableSelectInputField(
              key: ValueKey(
                  "${field.id}_${_fieldValues['region']}_options"), // More specific key
              field: fieldWithDynamicOptions,
              currentValue:
                  currentValue, // Pass current value for district/region
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

  Widget _buildSectionUI(Section section, int index) {
    List<Widget> fieldWidgets = section.fields
        .map((field) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: _buildFieldUI(field),
            ))
        .toList();
    fieldWidgets.removeWhere((widget) =>
        widget is SizedBox && widget.height == 0 && widget.width == 0);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12.0),
          child: Text(
            '${index + 1}. ${section.title}',
            // This line is now safe
            style: ShadTheme.of(context).textTheme.h4,
          ),
        ),
        ...fieldWidgets,
      ],
    );
  }

  void _submitForm() {
    if (_formKey.currentState?.validate() ?? false) {
      _formKey.currentState?.save(); // This might be specific to ShadForm
      // Access values via _fieldValues or _formKey.currentState?.value
      final formDataToSubmit = Map<String, dynamic>.from(_fieldValues);

      // Filter out values for fields that are not currently visible
      for (var section in widget.form.sections) {
        for (var field in section.fields) {
          if (!_isFieldVisible(field) &&
              formDataToSubmit.containsKey(field.id)) {
            formDataToSubmit.remove(field.id);
          }
        }
      }

      log('Form Data: $formDataToSubmit');
      showSnackBar(context, 'Form Submitted! (See console for data)',
          success: true);
      // Implement your actual submission logic here
    } else {
      showSnackBar(context, 'Please correct the errors in the form.',
          error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialBuildDone ||
        (_builtSections.isEmpty && widget.form.sections.isNotEmpty)) {
      // If _buildSections hasn't run yet or somehow resulted in empty sections
      // when there should be some, show a loader.
      // This might happen if didChangeDependencies hasn't completed its first run
      // before the first build.
      // Alternatively, if _buildSections is guaranteed by didChangeDependencies,
      // and sections can truly be empty, the latter checks are more appropriate.
      return const Center(
          child: CircularProgressIndicator(key: ValueKey("adapter_loader")));
    }

    if (_builtSections.isEmpty && widget.form.sections.isNotEmpty) {
      return const Center(
          child: Text("No form sections available.",
              key: ValueKey("adapter_no_sections")));
    }
    if (_builtSections.isEmpty) {
      // This case might be hit if the form truly has no sections defined in widget.form
      return const Center(
          child: Text("Form is empty.", key: ValueKey("adapter_form_empty")));
    }

    return ShadForm(
      key: _formKey,
      // initialValues: _fieldValues, // ShadForm might support this for initial values from map
      child: Stack(
        children: [
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.only(
                  left: 16.0,
                  right: 16.0,
                  bottom: 80.0,
                  top: 16.0), // Added top padding & more bottom
              child: AnimatedSwitcher(
                duration:
                    const Duration(milliseconds: 300), // Faster transition
                transitionBuilder: (child, animation) =>
                    FadeTransition(opacity: animation, child: child),
                child: Container(
                  key: ValueKey<int>(_currentIndex), // Key for AnimatedSwitcher
                  alignment: Alignment.topLeft, // Better for forms
                  child: _builtSections
                          .isNotEmpty // Ensure _builtSections is not accessed if empty
                      ? _builtSections[_currentIndex]
                      : const SizedBox.shrink(),
                ),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Material(
              // Added Material for elevation and theming
              elevation: 4.0,
              child: Stack(children: [
                ShadCard(
                  // Assuming ShadCard is appropriate here
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8.0, vertical: 8.0),
                  radius: BorderRadius.zero, // Full width look
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ShadIconButton.ghost(
                        onPressed: _currentIndex > 0 ? _previousSection : null,
                        icon: Tooltip(
                            message: "Previous section",
                            child:
                                const Icon(Icons.arrow_back_ios_new_rounded)),
                      ),
                      // Progress Indicator (Optional)
                      Text("${_currentIndex + 1} / ${_builtSections.length}"),
                      if (_currentIndex == _builtSections.length - 1)
                        Row(
                          spacing: 8.0,
                          children: [
                            ShadButton.secondary(
                              onPressed: _submitForm,
                              size: ShadButtonSize.sm, // Call submit directly
                              child: const Text('Save'),
                            ),
                            ShadButton(
                              onPressed: _submitForm,
                              size: ShadButtonSize.sm, // Call submit directly
                              child: const Text('Submit'),
                            ),
                          ],
                        )
                      else
                        ShadIconButton.ghost(
                          onPressed: _nextSection,
                          icon: Tooltip(
                              message: "Next section",
                              child:
                                  const Icon(Icons.arrow_forward_ios_rounded)),
                        ),
                    ],
                  ),
                ),
                LinearProgressIndicator(
                  value: _currentIndex + 1 / _builtSections.length,
                )
              ]),
            ),
          ),
        ],
      ),
    );
  }
}
