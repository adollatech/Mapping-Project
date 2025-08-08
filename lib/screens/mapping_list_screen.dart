import 'package:flutter/material.dart';
import 'package:surveyapp/models/survey_response.dart';
import 'package:surveyapp/screens/view_mapping_screen.dart';
import 'package:surveyapp/services/database_service.dart';
import 'package:surveyapp/widgets/mappings_map.dart';

class MappingListScreen extends StatefulWidget {
  const MappingListScreen({super.key, required this.formId});
  final String formId;

  @override
  State<MappingListScreen> createState() => _MappingListScreenState();
}

class _MappingListScreenState extends State<MappingListScreen> {
  final _indexNotifier = ValueNotifier(false);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text("Mappings"),
          actions: [
            SwitchListTile(
                value: _indexNotifier.value,
                title: Text('Map View'),
                onChanged: (val) => _indexNotifier.value = val)
          ],
        ),
        body: FutureBuilder<List<SurveyResponse>>(
          future: DatabaseService().getAll('responses',
              fromMap: (json) => SurveyResponse.fromJson(json)),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text("Error loading mappings data"));
            }
            if (!snapshot.hasData || snapshot.data == null) {
              return const Center(child: Text("No mapping data"));
            }

            final responses = snapshot.data!;

            return ValueListenableBuilder(
                valueListenable: _indexNotifier,
                builder: (context, value, child) {
                  return Visibility(
                    visible: value,
                    replacement: ListView.builder(
                      itemCount: responses.length,
                      itemBuilder: (context, index) {
                        final session = responses[index];
                        return ListTile(
                          title: Text(
                              session.response.sections.first.data.first.value),
                          subtitle: Text(
                              'Boundaries: ${session.mappedArea.boundaryPoints.map((bp) => '${bp.index}. ${bp.position.toSexagesimal()}')}'
                              '\nArea: ${session.mappedArea.area?.toStringAsFixed(4)}'),
                          isThreeLine: session.mappedArea.area != null,
                          onTap: () {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (ctx) =>
                                        ViewMappingScreen(survey: session)));
                          },
                        );
                      },
                    ),
                    child: MappedAreasMapWidget(
                      surveys: responses,
                    ),
                  );
                });
          },
        ));
  }
}
