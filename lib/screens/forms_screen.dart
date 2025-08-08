import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:surveyapp/models/dynamic_form.dart';
import 'package:surveyapp/screens/mapping_form_screen.dart';
import 'package:surveyapp/services/auth_service.dart';
import 'package:surveyapp/utils/utils.dart';
import 'package:surveyapp/widgets/custom_stream_builder.dart';

class FormsScreen extends StatelessWidget {
  const FormsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userId = AuthService().userId;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pick a form'),
      ),
      body: CustomStreamBuilder(
          collection: 'forms',
          filter: 'assigned_to.id ?= "$userId"',
          fromMap: (json) => DynamicForm.fromJson(json),
          builder: (context, forms) {
            return ListView.separated(
              itemCount: forms.length,
              itemBuilder: (context, idx) {
                return ListTile(
                  contentPadding:
                      EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                  leading: CircleAvatar(
                    child: Text("${idx + 1}",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        )),
                  ),
                  onTap: () =>
                      push(context, MappingFormScreen(form: forms[idx])),
                  title: Text(forms[idx].name),
                  trailing: Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 24,
                  ),
                  subtitle: Text(
                    forms[idx].description ??
                        DateFormat('MMM d, yyyy').format(forms[idx].created!),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              },
              separatorBuilder: (BuildContext context, int index) => Divider(
                height: 0,
              ),
            );
          }),
    );
  }
}
