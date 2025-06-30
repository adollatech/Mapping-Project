class Agent {
  final String id;
  final String name;
  final String email;
  final String? phone;
  final String? companyCode;

  Agent({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.companyCode,
  });

  factory Agent.fromJson(Map<String, dynamic> json) {
    return Agent(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      phone: json['phone'],
      companyCode: json['companyCode'],
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
