import 'package:flutter/material.dart'; 

class TeamModel {
  final String id;
  String name; 
  String? description; 
  final String ownerId;
  final String? ownerName; 
  final DateTime createdAt;

  TeamModel({
    required this.id,
    required this.name,
    this.description,
    required this.ownerId,
    this.ownerName,
    required this.createdAt,
  });

  factory TeamModel.fromJson(Map<String, dynamic> json) {
    return TeamModel(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?, 
      ownerId: json['owner_id'] as String,
      ownerName: (json['profiles'] as Map<String, dynamic>?)?['full_name'] as String?, 
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toUpdateJson() {
    return {
      'name': name,
      'description': description,
    };
  }
}