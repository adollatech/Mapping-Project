import 'field.dart';

class DynamicForm {
  final String id;
  final String name;
  final String? description;
  final List<String> assignedTo;
  final List<Section> sections;
  final DateTime? created;
  final DateTime? updated;

  DynamicForm({
    required this.id,
    required this.name,
    required this.assignedTo,
    required this.sections,
    this.description,
    this.created,
    this.updated,
  });

  factory DynamicForm.fromJson(Map<String, dynamic> json) {
    return DynamicForm(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      assignedTo: List<String>.from(json['assigned_to']),
      sections: (json['sections'] as List)
          .map((section) => Section.fromJson(section))
          .toList(),
      created: DateTime.tryParse(json['created']),
      updated: DateTime.tryParse(json['updated']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'assigned_to': assignedTo,
      'sections': sections.map((section) => section.toJson()).toList(),
      'created': created?.toIso8601String(),
      'updated': updated?.toIso8601String(),
    };
  }
}

class Section {
  final String title;
  final String id;
  final String? description;
  final List<Field> fields;

  Section({
    required this.title,
    required this.fields,
    required this.id,
    this.description,
  });

  factory Section.fromJson(Map<String, dynamic> json) {
    return Section(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      fields: (json['fields'] as List)
          .map((field) => Field.fromJson(field))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'fields': fields.map((field) => field.toJson()).toList(),
    };
  }
}
