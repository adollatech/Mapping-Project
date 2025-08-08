import 'package:surveyapp/models/area.dart';
import 'package:surveyapp/models/base_form_response.dart';
import 'package:surveyapp/models/dynamic_form.dart';

class SurveyResponse {
  final String id;
  final DynamicForm? form;
  final String formId;
  final BaseFormResponse response;
  final String collectedBy;
  final MappedArea mappedArea;
  final DateTime created;
  final DateTime updated;

  SurveyResponse({
    required this.id,
    required this.formId,
    required this.response,
    required this.collectedBy,
    required this.mappedArea,
    required this.created,
    required this.updated,
    this.form,
  });

  factory SurveyResponse.fromJson(Map<String, dynamic> json) {
    return SurveyResponse(
      id: json['id'],
      formId: json['form'],
      form: DynamicForm.fromJson(json['expand']['form']),
      response: BaseFormResponse.fromJson(json['responses']),
      collectedBy: json['collected_by'],
      mappedArea: MappedArea.fromJson(json['area']),
      created: DateTime.parse(json['created']),
      updated: DateTime.parse(json['updated']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'form': form,
      'responses': response.toJson(),
      'collected_by': collectedBy,
      'area': mappedArea.toJson(),
      'created': created.toIso8601String(),
      'updated': updated.toIso8601String(),
    };
  }
}
