import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/task_model.dart';
import '../models/user_model.dart'; 
import '../core/constants/app_constants.dart';

class TaskService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<TaskModel>> getTasksByProject(String projectId) async {
    try {
      final response = await _supabase
          .from(AppConstants.tasksTable)
          .select('*, profiles!assignee_id(full_name, avatar_url)') 
          .eq('project_id', projectId)
          .order('created_at', ascending: false);

      return response.map((json) {
        final taskJson = Map<String, dynamic>.from(json);
        if (json['profiles'] != null) {
          taskJson['assigneeName'] = json['profiles']['full_name'];
          taskJson['assigneeAvatarUrl'] = json['profiles']['avatar_url'];
        }
        return TaskModel.fromJson(taskJson);
      }).toList();
    } catch (e) {
      print('Error getting tasks by project: $e');
      rethrow;
    }
  }

  Future<TaskModel?> getTaskById(String taskId) async {
    try {
      final response = await _supabase
          .from(AppConstants.tasksTable)
          .select('*, profiles!assignee_id(full_name, avatar_url)')
          .eq('id', taskId)
          .single();

      final taskJson = Map<String, dynamic>.from(response);
      if (response['profiles'] != null) {
        taskJson['assigneeName'] = response['profiles']['full_name'];
        taskJson['assigneeAvatarUrl'] = response['profiles']['avatar_url'];
      }
      return TaskModel.fromJson(taskJson);
    } catch (e) {
      if (e is PostgrestException && e.code == 'PGRST116') {
        return null;
      }
      print('Error getting task by ID: $e');
      rethrow;
    }
  }

  Future<TaskModel> createTask({
    required String title,
    String? description,
    required String projectId,
    String? assigneeId,
    String? status, 
    String? priority,
    DateTime? dueDate,
  }) async {
    try {
      final response = await _supabase.from(AppConstants.tasksTable).insert({
        'title': title,
        'description': description,
        'project_id': projectId,
        'assignee_id': assigneeId,
        'status': status ?? AppConstants.taskTodo, 
        'priority': priority ?? AppConstants.priorityMedium, 
        'due_date': dueDate?.toIso8601String(), 
      }).select('*, profiles!assignee_id(full_name, avatar_url)').single();

      final taskJson = Map<String, dynamic>.from(response);
      if (response['profiles'] != null) {
        taskJson['assigneeName'] = response['profiles']['full_name'];
        taskJson['assigneeAvatarUrl'] = response['profiles']['avatar_url'];
      }
      return TaskModel.fromJson(taskJson);
    } catch (e) {
      print('Error creating task: $e');
      rethrow;
    }
  }

  Future<TaskModel> updateTask(TaskModel task) async {
    try {
      final Map<String, dynamic> updates = {
        'title': task.title,
        'description': task.description,
        'assignee_id': task.assigneeId,
        'status': task.status,
        'priority': task.priority,
        'due_date': task.dueDate?.toIso8601String(),
      };

      final response = await _supabase
          .from(AppConstants.tasksTable)
          .update(updates)
          .eq('id', task.id)
          .select('*, profiles!assignee_id(full_name, avatar_url)')
          .single();

      final taskJson = Map<String, dynamic>.from(response);
      if (response['profiles'] != null) {
        taskJson['assigneeName'] = response['profiles']['full_name'];
        taskJson['assigneeAvatarUrl'] = response['profiles']['avatar_url'];
      }
      return TaskModel.fromJson(taskJson);
    } catch (e) {
      print('Error updating task: $e');
      rethrow;
    }
  }

  Future<bool> deleteTask(String taskId) async {
    try {
      await _supabase.from(AppConstants.tasksTable).delete().eq('id', taskId);
      return true;
    } catch (e) {
      print('Error deleting task: $e');
      return false;
    }
  }
}