// lib/models/task_model.dart

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:flutter/foundation.dart'; // Required for @freezed

part 'task_model.freezed.dart';
part 'task_model.g.dart';

@freezed
class TaskModel with _$TaskModel {
  const factory TaskModel({
    required String id,
    required String title,
    String? description, // Mô tả có thể null
    @JsonKey(name: 'project_id') required String projectId,
    @JsonKey(name: 'assignee_id') String? assigneeId, // 
    String? assigneeName, 
    String? assigneeAvatarUrl, 
    required String status, 
    required String priority, 
    @JsonKey(name: 'due_date') DateTime? dueDate, 
    @JsonKey(name: 'created_at') required DateTime createdAt,
  }) = _TaskModel;

  factory TaskModel.fromJson(Map<String, dynamic> json) => _$TaskModelFromJson(json);
}