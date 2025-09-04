// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'task_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$TaskModelImpl _$$TaskModelImplFromJson(Map<String, dynamic> json) =>
    _$TaskModelImpl(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      projectId: json['project_id'] as String,
      assigneeId: json['assignee_id'] as String?,
      assigneeName: json['assigneeName'] as String?,
      assigneeAvatarUrl: json['assigneeAvatarUrl'] as String?,
      status: json['status'] as String,
      priority: json['priority'] as String,
      dueDate: json['due_date'] == null
          ? null
          : DateTime.parse(json['due_date'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
    );

Map<String, dynamic> _$$TaskModelImplToJson(_$TaskModelImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'description': instance.description,
      'project_id': instance.projectId,
      'assignee_id': instance.assigneeId,
      'assigneeName': instance.assigneeName,
      'assigneeAvatarUrl': instance.assigneeAvatarUrl,
      'status': instance.status,
      'priority': instance.priority,
      'due_date': instance.dueDate?.toIso8601String(),
      'created_at': instance.createdAt.toIso8601String(),
    };
