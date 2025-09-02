import 'dart:convert';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:hive_ce/hive.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:surveyapp/models/area.dart';
import 'package:surveyapp/models/base_form_response.dart';
import 'package:surveyapp/models/dynamic_form.dart';
import 'package:surveyapp/models/field.dart';
import 'package:surveyapp/screens/boundary_mapping_screen.dart';
import 'package:surveyapp/services/auth_service.dart';
import 'package:surveyapp/services/database_service.dart';
import 'package:surveyapp/utils/utils.dart';
import 'package:surveyapp/widgets/form_renderer.dart';

class MappingFormScreen extends StatefulWidget {
  final DynamicForm form;
  final BaseFormResponse? response;

  const MappingFormScreen({super.key, required this.form, this.response});

  @override
  State<MappingFormScreen> createState() => _MappingFormScreenState();
}

class _MappingFormScreenState extends State<MappingFormScreen> {
  int _currentIndex = 0;
  final Map<String, dynamic> _fieldValues = {};
  final _formKey = GlobalKey<ShadFormState>();
  int _stackIndex = 0;

  @override
  void initState() {
    super.initState();
    _fillForm();
    _initializeFieldValues();
    _loadSavedValues();
  }

  void _loadSavedValues() {
    final box = Hive.box<String>('surveys');
    final saved = box.get(widget.form.id, defaultValue: '');
    if (saved != null || saved?.isEmpty == false) {
      try {
        final response =
            BaseFormResponse.fromJson(jsonDecode(saved!)['response']);
        log('Field values: $_fieldValues');
        for (var section in response.sections) {
          for (var data in section.data) {
            if (data.value != null) {
              _fieldValues[data.fieldId] = data.value;
            }
          }
        }
      } catch (_) {
        log("Failed to load saved form values for ${widget.form.id}. Using defaults.");
      }
    }
  }

  void _fillForm() {
    if (widget.response != null) {
      try {
        for (var section in widget.response!.sections) {
          for (var data in section.data) {
            if (data.value != null) {
              _fieldValues[data.fieldId] = data.value;
            }
          }
        }
      } catch (_) {
        log("Failed to load form values for ${widget.form.id} with response for ${widget.response?.sections.first.data.first.value}");
      }
    }
  }

  void _initializeFieldValues() {
    for (var section in widget.form.sections) {
      for (var field in section.fields) {
        if (field.defaultValue != null) {
          _fieldValues[field.id] = field.defaultValue;
        }
        if (field.type == 'checkbox' && field.defaultValue == null) {
          _fieldValues[field.id] = false;
        }
      }
    }
  }

  void _onFieldValueChanged(String fieldId, dynamic value) {
    setState(() {
      _fieldValues[fieldId] = value;
      _clearDependentFieldValues(fieldId, value);
    });
  }

  void _clearDependentFieldValues(String changedFieldId, dynamic newValue) {
    for (var section in widget.form.sections) {
      for (var field in section.fields) {
        if (field.dependsOn?.fieldId == changedFieldId) {
          if (newValue != field.dependsOn!.showWhenValue) {
            if (_fieldValues.containsKey(field.id)) {
              _fieldValues.remove(field.id);
              _fieldValues[field.id] = null;
            }
          }
        }
      }
    }
  }

  void _goToSection(int index) {
    if (index >= 0 && index < widget.form.sections.length) {
      setState(() => _currentIndex = index);
    }
  }

  void _nextSection() {
    if (_formKey.currentState?.validate() ?? false) {
      _saveForm();

      // Switch to mapping if it's the last section
      if (_currentIndex == widget.form.sections.length - 1) {
        setState(() => _stackIndex += 1);
        return;
      }

      if (_currentIndex < widget.form.sections.length - 1) {
        setState(() => _currentIndex++);
      }
    } else {
      showSnackBar(context, "Please correct the errors before proceeding.");
    }
  }

  void _previousSection() {
    if (_stackIndex > 0) {
      setState(() => _stackIndex -= 1);
      return;
    }
    if (_currentIndex > 0) {
      setState(() => _currentIndex--);
    }
  }

  Future<void> _saveOffline(MappedArea mappedArea) async {
    if (_formKey.currentState?.validate() ?? false) {
      final response = _getSavedFormValues();
      if (response != null) {
        final box = Hive.box("unsynced");
        box.add(jsonEncode({
          'form': widget.form.id,
          'collected_by': AuthService().userId,
          'area': mappedArea.toJson(),
          'responses': response.toJson(),
        }));
      }
    }
  }

  Future<void> _submitForm(MappedArea mappedArea) async {
    if (_formKey.currentState?.validate() ?? false) {
      try {
        final response = _getSavedFormValues();
        if (response != null) {
          await DatabaseService().create(
            'surveys',
            {
              'form': widget.form.id,
              'collected_by': AuthService().userId,
              'area': mappedArea.toJson(),
              'responses': response.toJson(),
            },
          );
          Hive.box<String>('surveys').delete(widget.form.id);
          if (mounted) {
            showSnackBar(context, 'Survey has been successfully submitted',
                success: true);
          }
          setState(() {
            _fieldValues.clear();
          });
        } else {
          showSnackBar(context, 'No form data to submit.', error: true);
        }
      } on Exception catch (e) {
        if (mounted) {
          showSnackBar(context, 'Failed to submit form: $e', error: true);
        }
      }
    } else {
      showSnackBar(context, 'Please correct the errors in the form.',
          error: true);
    }
  }

  BaseFormResponse? _getSavedFormValues() {
    final data =
        Hive.box<String>('surveys').get(widget.form.id, defaultValue: null);
    if (data != null) {
      final fullResponse =
          BaseFormResponse.fromJson(jsonDecode(data)['response']);
      return fullResponse;
    }
    return null;
  }

  void _saveForm() {
    _formKey.currentState?.save();
    final box = Hive.box<String>('surveys');

    // Save all sections, not just current
    List<FormResponseSection> allSections = [];
    for (var section in widget.form.sections) {
      final List<Data> sectionData = [];
      for (var field in section.fields) {
        if (_isFieldVisible(field) &&
            _fieldValues[field.id] != null &&
            _fieldValues[field.id].toString().isNotEmpty &&
            _fieldValues[field.id].runtimeType != bool) {
          sectionData.add(Data(
            fieldId: field.id,
            value: _fieldValues[field.id],
            fieldName: field.label,
          ));
        }
      }
      if (sectionData.isNotEmpty) {
        allSections.add(FormResponseSection(
          title: section.title,
          data: sectionData,
        ));
      }
    }

    if (allSections.isEmpty) {
      return;
    }

    final response = BaseFormResponse(
      id: widget.form.id,
      formName: widget.form.name,
      sections: allSections,
      created: DateTime.now(),
    );

    final responseJson = response.toJson();
    box.put(widget.form.id,
        jsonEncode({'response': responseJson, 'form': widget.form.toJson()}));
  }

  bool _isTabletOrLarger(BuildContext context) {
    return MediaQuery.of(context).size.width >= 768;
  }

  bool _isFieldVisible(Field field) {
    if (field.dependsOn == null) {
      return true;
    }
    final dependentOnFieldId = field.dependsOn!.fieldId;
    final showWhenValue = field.dependsOn!.showWhenValue;
    final actualValue = _fieldValues[dependentOnFieldId];

    if (actualValue == null) {
      return showWhenValue == null;
    }

    switch (field.dependsOn?.condition) {
      case Condition.equals:
        return actualValue == showWhenValue;
      case Condition.contains:
        return actualValue.contains(showWhenValue);
      default:
        return actualValue != showWhenValue;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isTabletOrLarger = _isTabletOrLarger(context);
    return PopScope(
      onPopInvokedWithResult: (popped, result) async {
        _saveForm();
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              _saveForm();
              Navigator.of(context).pop();
            },
          ),
          title: Text(widget.form.name),
          actions: _stackIndex == 1
              ? [
                  ShadButton.ghost(
                    leading: const Icon(Icons.arrow_back_ios_new_rounded),
                    onPressed: () => _previousSection(),
                    child: Text('Back'),
                  ),
                  SizedBox(width: 8),
                ]
              : null,
        ),
        body: IndexedStack(
          index: _stackIndex,
          children: [
            ShadForm(
              key: _formKey,
              initialValue: _fieldValues,
              child: FormRenderer(
                form: widget.form,
                currentIndex: _currentIndex,
                fieldValues: _fieldValues,
                onFieldValueChanged: _onFieldValueChanged,
                onGoToSection: _goToSection,
                onNextSection: _nextSection,
                onPreviousSection: _previousSection,
                isFieldVisible: _isFieldVisible,
                isTabletOrLarger: isTabletOrLarger,
              ),
            ),
            BoundaryMappingScreen(
              onSubmitAreaMapped: _submitForm,
              onSaveAreaMappedOffline: _saveOffline,
            )
          ],
        ),
      ),
    );
  }
}
