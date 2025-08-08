import 'package:flutter/material.dart';
import 'package:surveyapp/models/survey_response.dart';
import 'package:surveyapp/screens/mapping_form_screen.dart';
import 'package:surveyapp/services/auth_service.dart';
import 'package:surveyapp/widgets/custom_stream_builder.dart';
import 'package:surveyapp/widgets/response_list_tile.dart';

class SelectResponsesScreen extends StatelessWidget {
  const SelectResponsesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userId = AuthService().userId;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Survey'),
      ),
      body: CustomStreamBuilder(
          collection: 'responses',
          filter: 'collected_by = "$userId"',
          expand: 'form',
          fromMap: (json) => SurveyResponse.fromJson(json),
          onEmpty: () => Center(
                child: Text(
                  "No responses found.",
                  style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                ),
              ),
          builder: (context, forms) {
            return ListView.separated(
              itemCount: forms.length,
              itemBuilder: (context, idx) {
                return ResponseListTile(
                  index: idx,
                  survey: forms[idx],
                  onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (ctx) => MappingFormScreen(
                                form: forms[idx].form!,
                                response: forms[idx].response,
                              ))),
                );
              },
              separatorBuilder: (BuildContext context, int index) => Divider(),
            );
          }),
    );
  }
}
