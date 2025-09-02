import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:surveyapp/models/base_form_response.dart';
import 'package:surveyapp/models/dynamic_form.dart';

class SavedFormsScreen extends StatelessWidget {
  const SavedFormsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Saved Surveys'),
      ),
      body: ValueListenableBuilder(
          valueListenable: Hive.box<String>('surveys').listenable(),
          builder: (context, box, child) {
            if (box.isEmpty || box.values.isEmpty || box.keys.isEmpty) {
              return Center(
                child: Text(
                  "No saved surveys found.",
                  style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                ),
              );
            }
            final forms = box.values
                .map((e) => DynamicForm.fromJson(jsonDecode(e)['form']))
                .toList();
            final responses = box.values
                .map(
                    (e) => BaseFormResponse.fromJson(jsonDecode(e)['response']))
                .toList();
            for (var i = 0; i < responses.length; i++) {
              var e = responses[i];
              if (e.sections.isEmpty) {
                box.delete(forms[i].id);
              }
            }
            responses.retainWhere((e) => e.sections.isNotEmpty);
            return ListView.separated(
              itemCount: responses.length,
              itemBuilder: (context, idx) {
                if (responses[idx].sections.isEmpty) {
                  return ListTile(
                    leading: CircleAvatar(
                      child: Text("${idx + 1}"),
                    ),
                    title: Text('Form: ${forms[idx].name}'),
                    subtitle: const Text('No responses saved.'),
                  );
                }

                final data = responses[idx].sections[0].data;
                var subTitle = switch (data.length) {
                  0 => '',
                  1 => '',
                  2 => data[1].value,
                  3 => data[2].value,
                  4 => data[3].value,
                  _ => data[4].value,
                };

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
                      context.push('/form', extra: forms[idx].toJson()),
                  title: Text(responses[idx].formName),
                  trailing: Icon(Icons.arrow_forward_ios_rounded, size: 24),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "${responses[idx].sections[0].data[0].value}, $subTitle",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'Created on ${DateFormat.yMMMMEEEEd().format(responses[idx].created)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                );
              },
              separatorBuilder: (BuildContext context, int index) => Divider(),
            );
          }),
    );
  }
}
