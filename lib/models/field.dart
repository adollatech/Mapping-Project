class FieldDependency {
  final String fieldId;
  final dynamic showWhenValue; // Can be String, bool, int, etc.

  FieldDependency({
    required this.fieldId,
    required this.showWhenValue,
  });

  factory FieldDependency.fromMap(Map<String, dynamic> map) {
    return FieldDependency(
      fieldId: map['fieldId'] as String,
      showWhenValue: map['showWhenValue'], // Keep it dynamic
    );
  }

  factory FieldDependency.fromJson(Map<String, dynamic> source) =>
      FieldDependency.fromMap(source);

  Map<String, dynamic> toMap() {
    return {
      'fieldId': fieldId,
      'showWhenValue': showWhenValue,
    };
  }
}

class Field {
  final String id;
  final String label;
  final String type;
  final String? placeholder;
  List<String>? options;
  final Validation validation;
  final String? hint;
  final dynamic defaultValue; // For initial values
  final FieldDependency? dependsOn;

  Field({
    required this.id,
    required this.label,
    required this.type,
    this.placeholder,
    this.options,
    required this.validation,
    this.hint,
    this.defaultValue,
    this.dependsOn,
  });

  factory Field.fromJson(Map<String, dynamic> json) {
    return Field(
      id: json['id'],
      label: json['label'],
      type: json['type'],
      placeholder: json['placeholder'],
      options:
          json['options'] != null ? List<String>.from(json['options']) : null,
      validation: Validation.fromJson(json['validation']),
      hint: json['hint'] as String?,
      defaultValue: json['defaultValue'],
      dependsOn: json['dependsOn'] != null
          ? FieldDependency.fromMap(json['dependsOn'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'label': label,
      'type': type,
      'placeholder': placeholder,
      'options': options,
      'validation': validation.toJson(),
      'hint': hint,
      'defaultValue': defaultValue,
      'dependsOn': dependsOn?.toMap(),
    };
  }

  Field copyWith({
    String? id,
    String? label,
    String? type,
    String? placeholder,
    List<String>? options,
    Validation? validation,
    String? hint,
    dynamic defaultValue,
    FieldDependency? dependsOn,
  }) {
    return Field(
      id: id ?? this.id,
      label: label ?? this.label,
      type: type ?? this.type,
      placeholder: placeholder ?? this.placeholder,
      options: options ?? this.options,
      validation: validation ?? this.validation,
      hint: hint ?? this.hint,
      defaultValue: defaultValue ?? this.defaultValue,
      dependsOn: dependsOn ?? this.dependsOn,
    );
  }
}

class Validation {
  final String type;
  final bool required;
  final String? pattern;
  final int? minLength;
  final int? maxLength;
  final num? min;
  final num? max;

  Validation({
    required this.type,
    required this.required,
    this.pattern,
    this.minLength,
    this.maxLength,
    this.min,
    this.max,
  });

  factory Validation.fromJson(Map<String, dynamic> json) {
    return Validation(
      type: json['type'],
      required: json['required'],
      pattern: json['pattern'],
      minLength: json['minLength'],
      maxLength: json['maxLength'],
      max: json['max'],
      min: json['min'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'required': required,
      'pattern': pattern,
      'minLength': minLength,
      'maxLength': maxLength,
      'min': min,
      'max': max,
    };
  }
}
