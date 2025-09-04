import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../models/project_model.dart';
import '../../models/task_model.dart';
import '../../models/user_model.dart';
import '../../models/team_member_model.dart'; 
import '../../services/project_service.dart';
import '../../services/task_service.dart';
import '../../services/team_service.dart';

class ProjectDetailScreen extends StatefulWidget {
  final String projectId;
  const ProjectDetailScreen({Key? key, required this.projectId}) : super(key: key);

  @override
  State<ProjectDetailScreen> createState() => _ProjectDetailScreenState();
}

class _ProjectDetailScreenState extends State<ProjectDetailScreen> {
  final ProjectService _projectService = ProjectService();
  final TaskService _taskService = TaskService();
  final TeamService _teamService = TeamService();
  final User? currentUser = Supabase.instance.client.auth.currentUser;

  ProjectModel? _project;
  List<TaskModel> _tasks = [];
  bool _isLoading = true;
  String? _errorMessage;
  String? _myRoleInTeam;

  @override
  void initState() {
    super.initState();
    _loadProjectDetails();
  }

  Future<void> _loadProjectDetails() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      if (currentUser == null) {
        if (mounted) context.go('/login');
        return;
      }

      _project = await _projectService.getProjectById(widget.projectId);
      if (_project == null) {
        throw Exception('Không tìm thấy dự án này.');
      }

      final List<TeamMemberModel> teamMembers = await _teamService.getTeamMembers(_project!.teamId);

      final TeamMemberModel myMember = teamMembers.firstWhere(
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
            teamId: _project!.teamId,
            user: dummyUser, 
            role: AppConstants.roleMember, 
            joinedAt: DateTime.now(), 
          );
        },
      );
      
      _myRoleInTeam = myMember.role;

      _tasks = await _taskService.getTasksByProject(widget.projectId);
    } catch (e) {
      print('Error loading project details: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'Lỗi tải chi tiết dự án: ${e.toString().replaceAll('Exception: ', '').split(':')[0]}';
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

  void _navigateToCreateTask() {
    if (_project != null) {
      context.push('/projects/${_project!.id}/tasks/create');
    }
  }

  void _navigateToTaskDetail(String taskId) {
    context.push('/tasks/$taskId');
  }

  bool _canEditProject() {
    return _myRoleInTeam == AppConstants.roleOwner || _myRoleInTeam == AppConstants.roleAdmin;
  }

  bool _canCreateTask() {
    return _myRoleInTeam == AppConstants.roleOwner ||
        _myRoleInTeam == AppConstants.roleAdmin ||
        _myRoleInTeam == AppConstants.roleMember;
  }

  Future<void> _toggleTaskStatus(TaskModel task) async {
    if (_isLoading) return;
    setState(() {
      _isLoading = true;
    });

    try {
      final String newStatus =
          task.status == AppConstants.taskDone ? AppConstants.taskTodo : AppConstants.taskDone;
      final updatedTask = task.copyWith(status: newStatus);
      await _taskService.updateTask(updatedTask);

      await _loadProjectDetails();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Cập nhật trạng thái task "${task.title}" thành "${newStatus == AppConstants.taskDone ? "Hoàn thành" : "Chưa làm"}"'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      print('Error updating task status: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi cập nhật trạng thái task: ${e.toString().replaceAll('Exception: ', '').split(':')[0]}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _navigateToEditProject() async {
    if (_project == null) return;

    final bool? result = await context.push<bool>(
      '/projects/${_project!.id}/edit',
    );

    if (result == true) {
      await _loadProjectDetails();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          _project?.name ?? 'Chi tiết dự án',
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
          if (_canEditProject() && _project != null)
            IconButton(
              icon: const Icon(Icons.edit, color: AppColors.primary),
              onPressed: _navigateToEditProject,
              tooltip: 'Chỉnh sửa dự án',
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
                  Text('Đang tải chi tiết dự án...', style: TextStyle(color: AppColors.grey)),
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
                          onPressed: _loadProjectDetails,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Thử lại'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : _project == null
                  ? const Center(
                      child: Text(
                        'Không tìm thấy dự án.',
                        style: TextStyle(fontSize: 18, color: AppColors.grey),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadProjectDetails,
                      color: AppColors.primary,
                      child: CustomScrollView(
                        slivers: [
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildProjectInfoCard(_project!),
                                  const SizedBox(height: 24),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text(
                                        'Danh sách công việc',
                                        style: TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.black),
                                      ),
                                      if (_canCreateTask())
                                        IconButton(
                                          icon: const Icon(Icons.add_task, color: AppColors.primary, size: 28),
                                          onPressed: _navigateToCreateTask,
                                          tooltip: 'Thêm công việc mới',
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                ],
                              ),
                            ),
                          ),
                          _tasks.isEmpty
                              ? SliverFillRemaining(
                                  hasScrollBody: false,
                                  child: Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Icon(Icons.assignment_turned_in_outlined, color: AppColors.grey, size: 60),
                                        const SizedBox(height: 16),
                                        const Text(
                                          'Chưa có công việc nào trong dự án này.',
                                          style: TextStyle(fontSize: 16, color: AppColors.grey),
                                          textAlign: TextAlign.center,
                                        ),
                                        const SizedBox(height: 24),
                                        if (_canCreateTask())
                                          ElevatedButton.icon(
                                            onPressed: _navigateToCreateTask,
                                            icon: const Icon(Icons.add),
                                            label: const Text('Tạo công việc mới'),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: AppColors.primary,
                                              foregroundColor: Colors.white,
                                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(10),
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                )
                              : SliverList(
                                  delegate: SliverChildBuilderDelegate(
                                    (context, index) {
                                      final task = _tasks[index];
                                      return _buildTaskCard(task);
                                    },
                                    childCount: _tasks.length,
                                  ),
                                ),
                        ],
                      ),
                    ),
    );
  }

  Widget _buildProjectInfoCard(ProjectModel project) {
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
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              project.name,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.black,
              ),
            ),
            const SizedBox(height: 10),
            if (project.description != null && project.description!.isNotEmpty)
              Text(
                project.description!,
                style: const TextStyle(fontSize: 15, color: AppColors.grey),
              ),
            if (project.description != null && project.description!.isNotEmpty)
              const SizedBox(height: 15),
            const Divider(color: AppColors.lightGrey, thickness: 1),
            const SizedBox(height: 10),
            _buildInfoRow(
              Icons.track_changes,
              'Trạng thái:',
              statusText,
              color: statusColor,
              iconColor: statusColor,
            ),
            const SizedBox(height: 8),
            _buildInfoRow(
              Icons.calendar_today_outlined,
              'Ngày tạo:',
              '${project.createdAt.day}/${project.createdAt.month}/${project.createdAt.year}',
              iconColor: AppColors.grey,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, {Color? color, Color? iconColor}) {
    return Row(
      children: [
        Icon(icon, color: iconColor ?? AppColors.grey, size: 20),
        const SizedBox(width: 10),
        Text(
          label,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppColors.black,
          ),
        ),
        const SizedBox(width: 5),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 15,
              color: color ?? AppColors.grey,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildTaskCard(TaskModel task) {
    IconData statusIcon;
    Color statusColor;
    String statusText;

    switch (task.status) {
      case AppConstants.taskTodo:
        statusIcon = Icons.radio_button_unchecked;
        statusColor = AppColors.grey;
        statusText = 'Cần làm';
        break;
      case AppConstants.taskDoing:
        statusIcon = Icons.hourglass_empty;
        statusColor = AppColors.warning;
        statusText = 'Đang làm';
        break;
      case AppConstants.taskDone:
        statusIcon = Icons.check_circle_rounded;
        statusColor = AppColors.success;
        statusText = 'Đã xong';
        break;
      default:
        statusIcon = Icons.info_outline;
        statusColor = AppColors.grey;
        statusText = 'Không xác định';
    }

    IconData priorityIcon;
    Color priorityColor;
    String priorityText;

    switch (task.priority) {
      case AppConstants.priorityLow:
        priorityIcon = Icons.arrow_downward_rounded;
        priorityColor = AppColors.info;
        priorityText = 'Thấp';
        break;
      case AppConstants.priorityMedium:
        priorityIcon = Icons.horizontal_rule_rounded;
        priorityColor = AppColors.warning;
        priorityText = 'Trung bình';
        break;
      case AppConstants.priorityHigh:
        priorityIcon = Icons.arrow_upward_rounded;
        priorityColor = AppColors.error;
        priorityText = 'Cao';
        break;
      default:
        priorityIcon = Icons.info_outline;
        priorityColor = AppColors.grey;
        priorityText = 'Không xác định';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      elevation: 2,
      child: InkWell(
        onTap: () => _navigateToTaskDetail(task.id),
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      task.title,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: AppColors.black,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => _toggleTaskStatus(task),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: statusColor, width: 0.5)
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(statusIcon, size: 18, color: statusColor),
                          const SizedBox(width: 4),
                          Text(statusText, style: TextStyle(fontSize: 12, color: statusColor, fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              if (task.description != null && task.description!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  task.description!,
                  style: const TextStyle(fontSize: 13, color: AppColors.grey),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(priorityIcon, color: priorityColor, size: 18),
                  const SizedBox(width: 4),
                  Text(
                    'Độ ưu tiên: $priorityText',
                    style: TextStyle(fontSize: 13, color: priorityColor, fontWeight: FontWeight.w500),
                  ),
                  const Spacer(),
                  if (task.dueDate != null) ...[
                    Icon(Icons.date_range, color: AppColors.grey, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      'Hạn: ${task.dueDate!.day}/${task.dueDate!.month}/${task.dueDate!.year}',
                      style: const TextStyle(fontSize: 12, color: AppColors.grey),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 10),
              if (task.assigneeId != null)
                _buildAssigneeInfo(task.assigneeName, task.assigneeAvatarUrl),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAssigneeInfo(String? assigneeName, String? assigneeAvatarUrl) {
    return Row(
      children: [
        CircleAvatar(
          radius: 14,
          backgroundColor: AppColors.lightGrey,
          backgroundImage: (assigneeAvatarUrl != null && assigneeAvatarUrl.isNotEmpty)
              ? NetworkImage(assigneeAvatarUrl)
              : null,
          child: (assigneeAvatarUrl == null || assigneeAvatarUrl.isEmpty)
              ? Text(
                  assigneeName?.isNotEmpty == true ? assigneeName![0].toUpperCase() : '?',
                  style: const TextStyle(fontSize: 14, color: AppColors.white),
                )
              : null,
        ),
        const SizedBox(width: 8),
        Text(
          'Người giao: ${assigneeName ?? 'Chưa xác định'}',
          style: const TextStyle(fontSize: 13, color: AppColors.black, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}