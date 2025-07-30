import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:surveyapp/models/dynamic_form.dart';
import 'package:surveyapp/screens/mapping_form_screen.dart';
import 'package:surveyapp/utils/utils.dart';
import 'package:surveyapp/widgets/custom_stream_builder.dart';

class FormsScreen extends StatelessWidget {
  const FormsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Surveys Available'),
      ),
      body: CustomStreamBuilder(
          collection: 'forms',
          fromMap: (json) => DynamicForm.fromJson(json),
          builder: (context, forms) {
            return ListView.separated(
              itemCount: forms.length,
              itemBuilder: (context, idx) {
                return ListTile(
                  leading: CircleAvatar(
                    child: Text("${idx + 1}"),
                  ),
                  onTap: () =>
                      push(context, MappingFormScreen(form: forms[idx])),
                  title: Text(forms[idx].name),
                  subtitle: Text(forms[idx].description ??
                      DateFormat('jmY').format(forms[idx].created!)),
                );
              },
              separatorBuilder: (BuildContext context, int index) => Divider(),
            );
          }),
    );
  }
}
