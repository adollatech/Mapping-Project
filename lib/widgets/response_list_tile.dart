import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:surveyapp/models/survey_response.dart';

class ResponseListTile extends StatelessWidget {
  final int index;
  final SurveyResponse survey;
  final VoidCallback onTap;
  const ResponseListTile({
    super.key,
    required this.index,
    required this.survey,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        child: Text("${index + 1}"),
      ),
      onTap: onTap,
      title: Text('Form: ${survey.response.formName}'),
      subtitle: Text(
        'Land owner: ${survey.response.sections[0].data[0].value}'
        '\nCaptured on ${DateFormat('MMM d, yyyy hh:mma').format(survey.created)}',
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
