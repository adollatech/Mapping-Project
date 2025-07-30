import 'package:latlong2/latlong.dart';
import 'package:surveyapp/models/agent.dart';
import 'package:surveyapp/models/dynamic_form.dart';

class SurveyResponse {
  final String id;
  final DynamicForm form;
  final Map<String, dynamic> responses;
  final Agent collectedBy;
  final List<LatLng> boundaries;
  final DateTime created;
  final DateTime updated;

  SurveyResponse({
    required this.id,
    required this.form,
    required this.responses,
    required this.collectedBy,
    required this.boundaries,
    required this.created,
    required this.updated,
  });

  factory SurveyResponse.fromJson(Map<String, dynamic> json) {
    return SurveyResponse(
      id: json['id'],
      form: DynamicForm.fromJson(json['form']),
      responses: Map<String, dynamic>.from(json['responses']),
      collectedBy: Agent.fromJson(json['collected_by']),
      boundaries:
          (json['boundaries'] as List).map((e) => LatLng.fromJson(e)).toList(),
      created: DateTime.parse(json['created']),
      updated: DateTime.parse(json['updated']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'form': form,
      'responses': responses,
      'collected_by': collectedBy.toJson(),
      'boundaries': boundaries.map((e) => e.toJson()).toList(),
      'created': created.toIso8601String(),
      'updated': updated.toIso8601String(),
    };
  }
}
