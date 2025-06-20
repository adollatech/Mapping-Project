import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:surveyapp/models/dynamic_form.dart';
import 'package:surveyapp/utils/form_adapter.dart';

class MappingFormScreen extends StatefulWidget {
  const MappingFormScreen({super.key});

  @override
  State<MappingFormScreen> createState() => _MappingFormScreenState();
}

class _MappingFormScreenState extends State<MappingFormScreen> {
  late Future<DynamicForm> _formFuture;

  @override
  void initState() {
    super.initState();
    _formFuture = _loadForm();
  }

  Future<DynamicForm> _loadForm() async {
    final String jsonString =
        await rootBundle.loadString('assets/data/form.json');
    final Map<String, dynamic> jsonData = json.decode(jsonString);
    return DynamicForm.fromJson(jsonData);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DynamicForm>(
      future: _formFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Scaffold(
              appBar: AppBar(
                title: const Text('Error'),
              ),
              body:
                  Center(child: Text('Error loading form: ${snapshot.error}')));
        } else if (!snapshot.hasData) {
          return Scaffold(
              appBar: AppBar(
                title: const Text('No Data'),
              ),
              body: Center(
                child: Text('No form data available'),
              ));
        } else {
          final DynamicForm form = snapshot.data!;
          return Scaffold(
            appBar: AppBar(
              title: Text(form.name),
            ),
            body: FormAdapter(form: form),
          );
        }
      },
    );
  }
}
