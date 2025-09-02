import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:surveyapp/models/survey_response.dart';
import 'package:surveyapp/services/auth_service.dart';
import 'package:surveyapp/widgets/custom_stream_builder.dart';
import 'package:surveyapp/widgets/mapped_areas_map_widget.dart';
import 'package:surveyapp/widgets/response_list_tile.dart';

class ResponsesScreen extends StatefulWidget {
  const ResponsesScreen({super.key});

  @override
  State<ResponsesScreen> createState() => _ResponsesScreenState();
}

class _ResponsesScreenState extends State<ResponsesScreen> {
  final mapView = ValueNotifier(false);

  @override
  Widget build(BuildContext context) {
    final userId = AuthService().userId;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Surveys'),
        actions: [
          ValueListenableBuilder(
              valueListenable: mapView,
              builder: (context, value, child) {
                return SizedBox(
                  width: 140,
                  child: CheckboxListTile.adaptive(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                      value: value,
                      onChanged: (v) {
                        mapView.value = v == true;
                      },
                      title: Text('Map View')),
                );
              })
        ],
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
            return ValueListenableBuilder(
                valueListenable: mapView,
                builder: (context, value, child) {
                  return Visibility(
                    visible: value,
                    replacement: ListView.separated(
                      itemCount: responses.length,
                      itemBuilder: (context, idx) {
                        return ResponseListTile(
                          onTap: () {
                            context.push('/view-mapping',
                                extra: responses[idx].toJson());
                          },
                          index: idx,
                          survey: responses[idx],
                        );
                      },
                      separatorBuilder: (BuildContext context, int index) =>
                          Divider(),
                    ),
                    child: MappedAreasMapWidget(surveys: responses),
                  );
                });
          }),
    );
  }
}
