// Copyright (c) 2025 CuongKenn and ICTU-OpenAgri Contributors
// Licensed under the MIT License. See LICENSE file in the project root for full license information.

class User {
  final String id;
  final String email;
  final String? username;
  final String? displayName;
  final String? photoUrl;
  final String? phoneNumber;
  final DateTime? createdAt;
  final bool isSuperuser;
  final bool isActive;

  User({
    required this.id,
    required this.email,
    this.username,
    this.displayName,
    this.photoUrl,
    this.phoneNumber,
    this.createdAt,
    this.isSuperuser = false,
    this.isActive = true,
  });

  // Convert from JSON
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id']?.toString() ?? '',
      email: json['email'] ?? '',
      username: json['username'],
      displayName:
          json['displayName'] ?? json['display_name'] ?? json['full_name'],
      photoUrl: json['photoUrl'] ?? json['photo_url'],
      phoneNumber: json['phoneNumber'] ?? json['phone_number'],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : json['created_at'] != null
              ? DateTime.parse(json['created_at'])
              : null,
      isSuperuser: json['is_superuser'] ?? false,
      isActive: json['is_active'] ?? true,
    );
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'username': username,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'phoneNumber': phoneNumber,
      'createdAt': createdAt?.toIso8601String(),
      'is_superuser': isSuperuser,
      'is_active': isActive,
    };
  }

  // Copy with method
  User copyWith({
    String? id,
    String? email,
    String? username,
    String? displayName,
    String? photoUrl,
    String? phoneNumber,
    DateTime? createdAt,
    bool? isSuperuser,
    bool? isActive,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      username: username ?? this.username,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      createdAt: createdAt ?? this.createdAt,
      isSuperuser: isSuperuser ?? this.isSuperuser,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  String toString() {
    return 'User(id: $id, email: $email, username: $username, isSuperuser: $isSuperuser)';
  }
}
