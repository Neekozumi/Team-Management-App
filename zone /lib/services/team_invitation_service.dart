import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../core/constants/app_constants.dart';
import '../services/team_service.dart'; 

class TeamInvitationService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final Uuid _uuid = Uuid();
  final TeamService _teamService = TeamService(); 

  Future<String> generateInviteLink(String teamId) async {
    try {
      final code = _uuid.v4();
      final userId = _supabase.auth.currentUser!.id;

      await _supabase
          .from(AppConstants.teamInvitationsTable)
          .insert({
            'team_id': teamId,
            'invite_code': code,
            'created_by': userId,
            'expires_at': DateTime.now().add(const Duration(days: AppConstants.inviteLinkExpiryDays)).toIso8601String(), 
            'invited_email': null, 
          });

      return '${AppConstants.inviteLinkPrefix}$code';
    } catch (e) {
      print('Error generating invite link: $e');
      return 'Error generating link'; 
    }
  }

  Future<bool> sendEmailInvitation(String teamId, String email) async {
    try {
      final code = _uuid.v4();
      final userId = _supabase.auth.currentUser!.id;

      await _supabase
          .from(AppConstants.teamInvitationsTable)
          .insert({
            'team_id': teamId,
            'invite_code': code,
            'invited_email': email,
            'created_by': userId,
            'expires_at': DateTime.now().add(const Duration(days: AppConstants.inviteLinkExpiryDays)).toIso8601String(), 
          });

      return true;
    } catch (e) {
      print('Error sending email invitation: $e'); 
      return false;
    }
  }

  Future<bool> joinTeamByCode(String code) async {
    try {
      final userId = _supabase.auth.currentUser!.id;
      if (userId == null) {
        print('User not logged in.');
        return false; 
      }

      final invResponse = await _supabase
          .from(AppConstants.teamInvitationsTable)
          .select('team_id,is_active,expires_at,invited_email') 
          .eq('invite_code', code)
          .maybeSingle(); 

      if (invResponse == null) {
        print('Invitation not found for code: $code');
        return false; 
      }

      final expires = DateTime.parse(invResponse['expires_at'] as String);
      if (invResponse['is_active'] != true || expires.isBefore(DateTime.now())) {
        print('Invitation expired or not active.');
        return false; 
      }

      final invitedEmail = invResponse['invited_email'] as String?;
      if (invitedEmail != null) {
        final currentUserEmail = _supabase.auth.currentUser!.email;
        if (currentUserEmail == null || currentUserEmail.toLowerCase() != invitedEmail.toLowerCase()) {
          print('Email mismatch for direct invitation.');
          return false; 
        }
      }

      final teamId = invResponse['team_id'] as String;

      final success = await _teamService.addMemberToTeam(
        teamId,
        userId,
        role: AppConstants.roleMember, 
      );

      if (success) {
        await _supabase
            .from(AppConstants.teamInvitationsTable)
            .update({'is_active': false})
            .eq('invite_code', code);
      }

      return success;
    } catch (e) {
      print('Error joining team by code: $e'); 
      return false;
    }
  }
}