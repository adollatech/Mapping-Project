import 'package:flutter/material.dart';
import 'package:surveyapp/models/dynamic_form.dart';
import 'package:surveyapp/utils/form_adapter.dart';

class MappingFormScreen extends StatelessWidget {
  const MappingFormScreen({super.key, required this.form});
  final DynamicForm form;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(form.name),
      ),
      body: FormAdapter(form: form),
    );
  }
}
