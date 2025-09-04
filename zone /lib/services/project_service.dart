import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/project_model.dart';
import '../core/constants/app_constants.dart'; 

class ProjectService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<ProjectModel>> getProjectsByTeam(String teamId) async {
    try {
      final response = await _supabase
          .from(AppConstants.projectsTable)
          .select('*')
          .eq('team_id', teamId)
          .order('created_at', ascending: false);

      return response.map((json) => ProjectModel.fromJson(json)).toList();
    } catch (e) {
      print('Error getting projects by team: $e');
      rethrow;
    }
  }

  Future<ProjectModel?> getProjectById(String projectId) async {
    try {
      final response = await _supabase
          .from(AppConstants.projectsTable)
          .select('*')
          .eq('id', projectId)
          .single(); 

      return ProjectModel.fromJson(response);
    } catch (e) {
      if (e is PostgrestException && e.code == 'PGRST116') {
        return null;
      }
      print('Error getting project by ID: $e');
      rethrow;
    }
  }

  Future<ProjectModel> createProject({
    required String name,
    String? description,
    required String teamId,
  }) async {
    try {
      final response = await _supabase.from(AppConstants.projectsTable).insert({
        'name': name,
        'description': description,
        'team_id': teamId,
        'status': AppConstants.projectActive, 
      }).select().single(); 

      return ProjectModel.fromJson(response);
    } catch (e) {
      print('Error creating project: $e');
      rethrow;
    }
  }

  Future<void> updateProject(ProjectModel project) async {
    try {
      final updateData = {
        'name': project.name,
        'description': project.description,
        'status': project.status,
      };

      await _supabase
          .from('projects')
          .update(updateData) 
          .eq('id', project.id); 

      print('Supabase: Project ${project.id} updated successfully.'); // Log thành công
    } on PostgrestException catch (e) {
      print('Supabase Error updating project: ${e.message}');
      throw Exception('Lỗi Supabase khi cập nhật dự án: ${e.message}');
    } catch (e) {
      print('General Error updating project: $e');
      throw Exception('Lỗi không xác định khi cập nhật dự án: $e');
    }
  }

  Future<void> deleteProject(String projectId) async {
    try {
      await _supabase.from('projects').delete().eq('id', projectId);
    } catch (e) {
      throw Exception('Lỗi khi xóa dự án: $e');
    }
  }
}