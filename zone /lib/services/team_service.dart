import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/team_model.dart';
import '../models/team_member_model.dart';
import '../core/constants/app_constants.dart'; 

class TeamService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<TeamModel?> createTeam(String name, String? description) async {
    try {
      final userId = _supabase.auth.currentUser!.id;
      final response = await _supabase
          .from(AppConstants.teamsTable)
          .insert({
            'name': name,
            'description': description,
            'owner_id': userId, 
          })
          .select()
          .single(); 

      final newTeam = TeamModel.fromJson(response);

      await _supabase.from(AppConstants.teamMembersTable).insert({
        'team_id': newTeam.id,
        'user_id': userId,
        'role': AppConstants.roleOwner,
        'joined_at': DateTime.now().toIso8601String(), 
      });

      return newTeam;
    } catch (e) {
      print('Error creating team: $e');
      return null; 
    }
  }

  Future<List<TeamModel>> getUserTeams() async {
    try {
      final userId = _supabase.auth.currentUser!.id;
      final resp = await _supabase
          .from(AppConstants.teamMembersTable)
          .select('teams(*, profiles!teams_owner_id_fkey(full_name))') 
          .eq('user_id', userId);

      return (resp as List).map((e) {
        final teamData = e['teams'] as Map<String, dynamic>;
        if (teamData['profiles'] != null) {
          teamData['owner_name'] = (teamData['profiles'] as Map<String, dynamic>)['full_name'];
        }
        return TeamModel.fromJson(teamData);
      }).toList();
    } catch (e) {
      print('Error getting user teams: $e');
      return [];
    }
  }

  Future<TeamModel?> getTeamById(String teamId) async {
    try {
      final data = await _supabase
          .from(AppConstants.teamsTable)
          .select('*, profiles!teams_owner_id_fkey(full_name)') 
          .eq('id', teamId)
          .single();

      if (data != null) {
        final Map<String, dynamic> teamData = data;
        if (teamData['profiles'] != null) {
          teamData['owner_name'] = (teamData['profiles'] as Map<String, dynamic>)['full_name'];
        }
        return TeamModel.fromJson(teamData);
      }
      return null;
    } catch (e) {
      print('Error getting team by id: $e');
      return null;
    }
  }

  Future<bool> updateTeam(String teamId, String newName, String newDescription) async {
    try {
      await _supabase.from(AppConstants.teamsTable).update({
        'name': newName,
        'description': newDescription,
      }).eq('id', teamId);
      return true;
    } catch (e) {
      print('Error updating team: $e');
      return false;
    }
  }

  Future<bool> deleteTeam(String teamId) async {
    try {

      await _supabase.from(AppConstants.teamMembersTable).delete().eq('team_id', teamId);
      await _supabase.from(AppConstants.teamInvitationsTable).delete().eq('team_id', teamId); // Cần hằng số này
      await _supabase.from(AppConstants.teamsTable).delete().eq('id', teamId);
      return true;
    } catch (e) {
      print('Error deleting team: $e');
      return false;
    }
  }

  Future<List<TeamMemberModel>> getTeamMembers(String teamId) async {
    try {
      final resp = await _supabase
          .from(AppConstants.teamMembersTable)
          .select('*, user:user_id(*)')                                    
          .eq('team_id', teamId);


      return (resp as List).map((json) {
        try {

          return TeamMemberModel.fromJson(json as Map<String, dynamic>);
        } catch (e) {
          print('Error parsing TeamMemberModel from JSON: $e, JSON: $json');
          rethrow; 
        }
      }).toList();
    } catch (e) {
      print('Error getting team members: $e');
      return [];
    }
  }

  Future<bool> addMemberToTeam(String teamId, String userIdToAdd, {String role = AppConstants.defaultMemberRole}) async {
    try {
      final existingMember = await _supabase
          .from(AppConstants.teamMembersTable)
          .select('id')
          .eq('team_id', teamId)
          .eq('user_id', userIdToAdd)
          .maybeSingle(); 
      if (existingMember != null) {
        print('Member already exists in team.');
        return false; 
      }

      await _supabase.from(AppConstants.teamMembersTable).insert({
        'team_id': teamId,
        'user_id': userIdToAdd,
        'role': role,
        'joined_at': DateTime.now().toIso8601String(), 
      });
      return true;
    } catch (e) {
      print('Error adding member to team: $e');
      return false;
    }
  }

  Future<bool> removeMember(String teamId, String targetUserId) async {
    try {
      await _supabase
          .from(AppConstants.teamMembersTable)
          .delete()
          .eq('team_id', teamId)
          .eq('user_id', targetUserId);
      return true;
    } catch (e) {
      print('Error removing member: $e');
      return false;
    }
  }

  Future<bool> updateMemberRole(String teamId, String targetUserId, String newRole) async {
    try {
      await _supabase
          .from(AppConstants.teamMembersTable)
          .update({'role': newRole})
          .eq('team_id', teamId)
          .eq('user_id', targetUserId);
      return true;
    } catch (e) {
      print('Error updating member role: $e');
      return false;
    }
  }

  Future<bool> leaveTeam(String teamId) async {
    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) return false; 

      await _supabase
          .from(AppConstants.teamMembersTable)
          .delete()
          .eq('team_id', teamId)
          .eq('user_id', currentUser.id);
      return true;
    } catch (e) {
      print('Error leaving team: $e');
      return false;
    }
  }

  Future<bool> transferOwnership(String teamId, String newOwnerId) async {
    try {
      final currentOwnerId = _supabase.auth.currentUser!.id;

      await _supabase
          .from(AppConstants.teamsTable)
          .update({'owner_id': newOwnerId})
          .eq('id', teamId);

      await _supabase
          .from(AppConstants.teamMembersTable)
          .update({'role': AppConstants.roleAdmin})
          .eq('team_id', teamId)
          .eq('user_id', currentOwnerId);

      await _supabase
          .from(AppConstants.teamMembersTable)
          .update({'role': AppConstants.roleOwner})
          .eq('team_id', teamId)
          .eq('user_id', newOwnerId);

      return true;
    } catch (e) {
      print('Error transferring ownership: $e');
      return false;
    }
  }

}