// lib/models/team_member_model.dart
import 'package:flutter/material.dart'; 
import 'user_model.dart'; 

class TeamMemberModel {
  final String id;
  final String teamId;
  final UserModel user;
  String role; 
  final DateTime joinedAt;

  TeamMemberModel({
    required this.id,
    required this.teamId,
    required this.user, 
    required this.role,
    required this.joinedAt,
  });

  factory TeamMemberModel.fromJson(Map<String, dynamic> json) {

    final userJson = json['user'] as Map<String, dynamic>?; // Lấy dữ liệu user nested

    if (userJson == null) {
      throw Exception('User data is missing for team member ${json['id']}');
    }

    return TeamMemberModel(
      id: json['id'] as String,
      teamId: json['team_id'] as String,
      user: UserModel.fromJson(userJson), 
      role: json['role'] as String,
      joinedAt: DateTime.parse(json['joined_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'team_id': teamId,
      'user_id': user.id, 
      'role': role,
    };
  }
}