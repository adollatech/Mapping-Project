import 'package:flutter/material.dart';
import 'package:surveyapp/models/survey_response.dart';
import 'package:surveyapp/screens/view_mapping_screen.dart';
import 'package:surveyapp/services/auth_service.dart';
import 'package:surveyapp/widgets/custom_stream_builder.dart';
import 'package:surveyapp/widgets/response_list_tile.dart';

class ResponsesScreen extends StatelessWidget {
  const ResponsesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userId = AuthService().userId;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Surveys'),
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
          builder: (context, responses) {
            return ListView.separated(
              itemCount: responses.length,
              itemBuilder: (context, idx) {
                return ResponseListTile(
                  onTap: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (ctx) =>
                                ViewMappingScreen(survey: responses[idx])));
                  },
                  index: idx,
                  survey: responses[idx],
                );
              },
              separatorBuilder: (BuildContext context, int index) => Divider(),
            );
          }),
    );
  }
}
