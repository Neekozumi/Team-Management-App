// lib/models/project_model.dart

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:flutter/foundation.dart'; 

part 'project_model.freezed.dart';
part 'project_model.g.dart';

@freezed
class ProjectModel with _$ProjectModel {
  const factory ProjectModel({
    required String id,
    required String name,
    String? description, 
    @JsonKey(name: 'team_id') required String teamId,
    required String status, // 'active', 'completed', 'paused'
    @JsonKey(name: 'created_at') required DateTime createdAt,
  }) = _ProjectModel;

  factory ProjectModel.fromJson(Map<String, dynamic> json) => _$ProjectModelFromJson(json);
}