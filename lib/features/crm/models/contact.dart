class Contact {
  final String id;
  final String accountId;
  final String firstName;
  final String lastName;
  final String email;

  Contact({
    required this.id,
    required this.accountId,
    required this.firstName,
    required this.lastName,
    required this.email,
  });

  factory Contact.fromJson(Map<String, dynamic> json) {
    return Contact(
      id: json['id'] as String,
      accountId: json['accountId'] as String,
      firstName: json['firstName'] as String,
      lastName: json['lastName'] as String,
      email: json['email'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'accountId': accountId,
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
    };
  }
}
