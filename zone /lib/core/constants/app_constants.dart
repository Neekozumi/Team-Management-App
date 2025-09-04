class AppConstants {

  static const String appUrl = '';
  
  static const String profilesTable = 'profiles';
  
  static const String teamsTable = 'teams';
  static const String teamMembersTable = 'team_members';
  static const String teamInvitationsTable = 'team_invitations';
  static const String notificationsTable = 'notifications';

  static const String projectsTable = 'projects';
  static const String tasksTable = 'tasks';
  static const String channelsTable = 'channels';
  static const String messagesTable = 'messages';
  
  // User roles
  static const String roleOwner = 'owner';
  static const String roleAdmin = 'admin';
  static const String roleMember = 'member';
    static const String defaultMemberRole = roleMember;


  static const inviteLinkPrefix = 'https://zone/invite/';
  
  // Task status
  static const String taskTodo = 'todo';
  static const String taskDoing = 'doing';
  static const String taskDone = 'done';
  
  // Task priority
  static const String priorityLow = 'low';
  static const String priorityMedium = 'medium';
  static const String priorityHigh = 'high';
  
  // Project status
  static const String projectActive = 'active';
  static const String projectCompleted = 'completed';
  static const String projectPaused = 'paused';
  
  // Channel types
  static const String channelGeneral = 'general';
  static const String channelProject = 'project';
  static const String channelDirect = 'direct';
  
  // Notification types
  static const String notificationTaskAssigned = 'task_assigned';
  static const String notificationTaskCompleted = 'task_completed';
  static const String notificationNewMessage = 'new_message';
  static const String notificationTeamInvitation = 'team_invitation';
  static const String notificationMemberJoined = 'member_joined';
  
  // Invite settings
  static const int inviteLinkExpiryDays = 7;
  static const int inviteCodeLength = 8;
}