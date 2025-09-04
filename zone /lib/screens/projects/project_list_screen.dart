
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../models/project_model.dart';
import '../../models/team_model.dart';
import '../../models/team_member_model.dart'; 
import '../../models/user_model.dart'; 
import '../../services/project_service.dart';
import '../../services/team_service.dart';

class ProjectListScreen extends StatefulWidget {
  final String teamId;
  const ProjectListScreen({Key? key, required this.teamId}) : super(key: key);

  @override
  State<ProjectListScreen> createState() => _ProjectListScreenState();
}

class _ProjectListScreenState extends State<ProjectListScreen> {
  final ProjectService _projectService = ProjectService();
  final TeamService _teamService = TeamService();
  final User? currentUser = Supabase.instance.client.auth.currentUser;

  TeamModel? _currentTeam;
  List<ProjectModel> _projects = [];
  String? _myRoleInTeam;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadProjectAndTeamDetails();
  }

  Future<void> _loadProjectAndTeamDetails() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      if (currentUser == null) {
        if (mounted) context.go('/login');
        return;
      }

      _currentTeam = await _teamService.getTeamById(widget.teamId);
      if (_currentTeam == null) {
        throw Exception('Không tìm thấy nhóm này.');
      }

      final List<TeamMemberModel> members = await _teamService.getTeamMembers(widget.teamId);
      
      final TeamMemberModel myMember = members.firstWhere(
        (m) => m.user.id == currentUser!.id, 
        orElse: () {
          final UserModel dummyUser = UserModel(
            id: currentUser!.id,
            email: currentUser!.email ?? 'unknown@example.com',
            fullName: currentUser!.email?.split('@')[0] ?? 'Unknown User',
            avatarUrl: null,
            createdAt: DateTime.now(),
          );
          return TeamMemberModel(
            id: '', 
            teamId: widget.teamId,
            user: dummyUser, 
            role: AppConstants.roleMember, 
            joinedAt: DateTime.now(), 
          );
        },
      );
      
      _myRoleInTeam = myMember.role;

      _projects = await _projectService.getProjectsByTeam(widget.teamId);
    } catch (e) {
      print('Error loading projects: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'Lỗi tải dự án: ${e.toString().replaceAll('Exception: ', '').split(':')[0]}';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _navigateToCreateProject() {
    context.push('/team_detail/${widget.teamId}/projects/create');
  }

  void _navigateToProjectDetail(String projectId) {
    context.push('/projects/$projectId');
  }

  @override
  Widget build(BuildContext context) {
    final canCreateProject = _myRoleInTeam == AppConstants.roleOwner ||
                             _myRoleInTeam == AppConstants.roleAdmin;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          _currentTeam?.name != null
              ? 'Dự án của ${_currentTeam!.name}'
              : 'Dự án',
          style: const TextStyle(
            color: AppColors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppColors.white,
        elevation: 1, 
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.black),
          onPressed: () => context.pop(),
        ),
        actions: [
          if (canCreateProject)
            IconButton(
              icon: const Icon(Icons.add_box_outlined, color: AppColors.primary),
              onPressed: _navigateToCreateProject,
              tooltip: 'Tạo dự án mới', 
            ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: AppColors.primary),
                  SizedBox(height: 16),
                  Text('Đang tải dự án...', style: TextStyle(color: AppColors.grey)),
                ],
              ),
            )
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, color: AppColors.error, size: 48),
                        const SizedBox(height: 16),
                        Text(
                          _errorMessage!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: AppColors.error, fontSize: 16),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _loadProjectAndTeamDetails,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Thử lại'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: AppColors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : _projects.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.folder_open_outlined, color: AppColors.grey, size: 60),
                          const SizedBox(height: 16),
                          const Text(
                            'Chưa có dự án nào trong nhóm này.',
                            style: TextStyle(fontSize: 18, color: AppColors.grey),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),
                          if (canCreateProject)
                            ElevatedButton.icon(
                              onPressed: _navigateToCreateProject,
                              icon: const Icon(Icons.add),
                              label: const Text('Tạo dự án mới'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: AppColors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadProjectAndTeamDetails,
                      color: AppColors.primary,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _projects.length,
                        itemBuilder: (context, index) {
                          final project = _projects[index];
                          return _buildProjectCard(project);
                        },
                      ),
                    ),
    );
  }

  Widget _buildProjectCard(ProjectModel project) {
    IconData statusIcon;
    Color statusColor;
    String statusText;

    switch (project.status) {
      case AppConstants.projectActive:
        statusIcon = Icons.play_circle_fill_rounded; 
        statusColor = AppColors.success;
        statusText = 'Đang hoạt động';
        break;
      case AppConstants.projectCompleted:
        statusIcon = Icons.check_circle_rounded; 
        statusColor = AppColors.info;
        statusText = 'Hoàn thành';
        break;
      case AppConstants.projectPaused:
        statusIcon = Icons.pause_circle_filled_rounded; 
        statusColor = AppColors.warning;
        statusText = 'Tạm dừng';
        break;
      default:
        statusIcon = Icons.info_outline;
        statusColor = AppColors.grey;
        statusText = 'Không xác định';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      child: InkWell(
        onTap: () => _navigateToProjectDetail(project.id),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                project.name,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.black,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              if (project.description != null && project.description!.isNotEmpty)
                Text(
                  project.description!,
                  style: const TextStyle(fontSize: 14, color: AppColors.grey),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              if (project.description != null && project.description!.isNotEmpty)
                const SizedBox(height: 12),
              Row(
                children: [
                  Icon(statusIcon, color: statusColor, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    statusText,
                    style: TextStyle(
                      fontSize: 14,
                      color: statusColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  Icon(Icons.calendar_today_outlined, color: AppColors.grey, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    'Tạo: ${project.createdAt.day}/${project.createdAt.month}/${project.createdAt.year}',
                    style: const TextStyle(fontSize: 12, color: AppColors.grey),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}