class Agent {
  final String id;
  final String name;
  final String email;
  final String? phone;

  Agent({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
  });

  factory Agent.fromJson(Map<String, dynamic> json) {
    return Agent(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      phone: json['phone'],
    );
  }

  // Convert an Agent instance to a JSON map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
    };
  }
}
