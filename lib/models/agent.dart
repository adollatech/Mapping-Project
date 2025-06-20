class Agent {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String companyCode;

  Agent({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.companyCode,
  });

  // Convert a JSON map to an Agent instance
  factory Agent.fromJson(Map<String, dynamic> json) {
    return Agent(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String,
      companyCode: json['companyCode'] as String,
    );
  }

  // Convert an Agent instance to a JSON map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'companyCode': companyCode,
    };
  }
}
