class FormResponseSection {
  final String title;
  final List<Data> data;

  FormResponseSection({
    required this.title,
    required this.data,
  });

  factory FormResponseSection.fromJson(Map<String, dynamic> json) {
    return FormResponseSection(
      title: json['title'],
      data:
          (json['data'] as List).map((field) => Data.fromJson(field)).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'data': data.map((d) => d.toJson()).toList(),
    };
  }
}

class Data {
  final String fieldId;
  final dynamic value;
  final String? fieldName;

  Data({required this.fieldId, required this.value, this.fieldName});

  factory Data.fromJson(Map<String, dynamic> json) {
    return Data(
      fieldId: json['field_id'],
      value: json['value'],
      fieldName: json['field_name'],
    );
  }
  Map<String, dynamic> toJson() {
    return {
      'field_id': fieldId,
      'value': value,
      'field_name': fieldName,
    };
  }
}

class BaseFormResponse {
  final String id;
  final String formName;
  final List<FormResponseSection> sections;
  final DateTime created;

  BaseFormResponse({
    required this.id,
    required this.formName,
    required this.sections,
    required this.created,
  });

  factory BaseFormResponse.fromJson(Map<String, dynamic> json) {
    return BaseFormResponse(
      id: json['id'],
      formName: json['form_name'],
      sections: (json['sections'] as List)
          .map((section) => FormResponseSection.fromJson(section))
          .toList(),
      created: DateTime.parse(json['created']),
    );
  }
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'form_name': formName,
      'sections': sections.map((s) => s.toJson()).toList(),
      'created': created.toIso8601String(),
    };
  }
}
