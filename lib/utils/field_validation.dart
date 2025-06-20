import 'package:surveyapp/models/field.dart';

class Validator {
  final bool condition;
  final String message;

  Validator({required this.condition, required this.message});
}

class FieldValidation {
  final Validation validation;
  FieldValidation({required this.validation});

  List<Validator> validate(dynamic value) {
    final validations = <Validator>[];
    if (validation.required) {
      validations.add(Validator(
          condition: (value == null || value == ''),
          message: "This field is required"));
    }
    if (validation.minLength != null) {
      validations.add(Validator(
          condition:
              (value.toString().length < (validation.minLength?.toInt() ?? 0)),
          message: "Minimum length is ${validation.minLength}"));
    }
    if (validation.maxLength != null) {
      validations.add(Validator(
          condition:
              (value.toString().length > (validation.maxLength?.toInt() ?? 0)),
          message: "Maximum length is ${validation.maxLength}"));
    }
    if (validation.min != null) {
      validations.add(Validator(
          condition: ((num.tryParse(value) ?? 0) < (validation.min ?? 0)),
          message: "Minimum accepted value is ${validation.min}"));
    }
    if (validation.pattern != null) {
      validations.add(Validator(
          condition: !RegExp(validation.pattern!).hasMatch(value),
          message: 'Invalid format'));
    }
    if (validation.max != null) {
      validations.add(Validator(
          condition: ((num.tryParse(value) ?? 0) > (validation.max ?? 0)),
          message: "Maximum accepted value is ${validation.max}"));
    }
    if (validation.type == 'email') {
      validations.add(Validator(
          condition:
              !RegExp(r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$")
                  .hasMatch(value),
          message: "Invalid email address"));
    }
    if (validation.type == 'phone') {
      validations.add(Validator(
          condition: !RegExp(r"^\d{10}$").hasMatch(value),
          message: "Invalid phone number"));
    }
    if (validation.type == 'url') {
      validations.add(Validator(
          condition:
              !RegExp(r"^(https?|ftp)://[^\s/$.?#].[^\s]*$").hasMatch(value),
          message: "Invalid URL"));
    }
    if (validation.type == 'image') {
      validations.add(Validator(
          condition: !RegExp(r"^.+\.(jpg|jpeg|png|gif)$").hasMatch(value),
          message: "Invalid image format"));
    }
    if (validation.type == 'password') {
      validations.add(Validator(
          condition: !RegExp(r"^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)[a-zA-Z\d]{8,}$")
              .hasMatch(value),
          message:
              "Password must have 8+ chars, 1 uppercase, 1 lowercase, and 1 number"));
    }
    return validations;
  }
}
