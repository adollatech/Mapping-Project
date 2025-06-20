import 'field.dart';

class DynamicForm {
  final String id;
  final String name;
  final List<String> assignedTo;
  final List<Section> sections;

  DynamicForm({
    required this.id,
    required this.name,
    required this.assignedTo,
    required this.sections,
  });

  factory DynamicForm.fromJson(Map<String, dynamic> json) {
    return DynamicForm(
      id: json['id'],
      name: json['name'],
      assignedTo: List<String>.from(json['assigned_to']),
      sections: (json['sections'] as List)
          .map((section) => Section.fromJson(section))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'assigned_to': assignedTo,
      'sections': sections.map((section) => section.toJson()).toList(),
    };
  }
}

class Section {
  final String title;
  final List<Field> fields;

  Section({
    required this.title,
    required this.fields,
  });

  factory Section.fromJson(Map<String, dynamic> json) {
    return Section(
      title: json['title'],
      fields: (json['fields'] as List)
          .map((field) => Field.fromJson(field))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'fields': fields.map((field) => field.toJson()).toList(),
    };
  }
}
