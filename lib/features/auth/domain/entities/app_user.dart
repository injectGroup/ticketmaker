import 'package:equatable/equatable.dart';

class AppUser extends Equatable {
  const AppUser({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    this.phone = '',
    this.dateOfBirth,
    this.marketingOptIn = false,
    this.preferredCity,
    this.interests = const [],
  });

  final String id;
  final String email;
  final String firstName;
  final String lastName;
  final String phone;
  final DateTime? dateOfBirth;
  final bool marketingOptIn;
  final String? preferredCity;
  final List<String> interests;

  String get displayName => '$firstName $lastName'.trim();

  bool get needsPersonalization =>
      preferredCity == null ||
      preferredCity!.trim().isEmpty ||
      interests.isEmpty;

  AppUser copyWith({
    String? id,
    String? email,
    String? firstName,
    String? lastName,
    String? phone,
    DateTime? dateOfBirth,
    bool? marketingOptIn,
    String? preferredCity,
    List<String>? interests,
    bool clearPreferredCity = false,
    bool clearDateOfBirth = false,
  }) {
    return AppUser(
      id: id ?? this.id,
      email: email ?? this.email,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      phone: phone ?? this.phone,
      dateOfBirth: clearDateOfBirth
          ? null
          : (dateOfBirth ?? this.dateOfBirth),
      marketingOptIn: marketingOptIn ?? this.marketingOptIn,
      preferredCity: clearPreferredCity
          ? null
          : (preferredCity ?? this.preferredCity),
      interests: interests ?? this.interests,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'email': email,
    'firstName': firstName,
    'lastName': lastName,
    'phone': phone,
    if (dateOfBirth != null) 'dateOfBirth': dateOfBirth!.toIso8601String(),
    'marketingOptIn': marketingOptIn,
    'preferredCity': preferredCity,
    'interests': interests,
  };

  factory AppUser.fromJson(Map<String, dynamic> json) {
    final dobRaw = json['dateOfBirth'];
    return AppUser(
      id: json['id'] as String? ?? json['uid'] as String? ?? '',
      email: json['email'] as String? ?? '',
      firstName: json['firstName'] as String? ?? '',
      lastName: json['lastName'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      dateOfBirth: dobRaw is String && dobRaw.isNotEmpty
          ? DateTime.tryParse(dobRaw)
          : null,
      marketingOptIn: json['marketingOptIn'] as bool? ?? false,
      preferredCity: json['preferredCity'] as String?,
      interests: (json['interests'] as List<dynamic>? ?? const [])
          .map((e) => e.toString())
          .toList(),
    );
  }

  @override
  List<Object?> get props => [
    id,
    email,
    firstName,
    lastName,
    phone,
    dateOfBirth,
    marketingOptIn,
    preferredCity,
    interests,
  ];
}
