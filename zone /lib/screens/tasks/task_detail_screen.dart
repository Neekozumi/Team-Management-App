// lib/screens/task/task_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../models/task_model.dart';
import '../../models/user_model.dart'; 
import '../../models/team_member_model.dart'; 
import '../../services/task_service.dart';
import '../../services/team_service.dart';

class TaskDetailScreen extends StatefulWidget {
  final String taskId;
  const TaskDetailScreen({Key? key, required this.taskId}) : super(key: key);

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  final TaskService _taskService = TaskService();
  final TeamService _teamService = TeamService();
  final SupabaseClient _supabase = Supabase.instance.client;

  TaskModel? _task;
  bool _isLoading = true;
  String? _errorMessage;
  String? _myRoleInTeam;
  String? _currentProjectTeamId;

  @override
  void initState() {
    super.initState();
    _loadTaskDetails();
  }

  Future<void> _loadTaskDetails() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      if (_supabase.auth.currentUser == null) {
        if (mounted) context.go('/login');
        return;
      }

      _task = await _taskService.getTaskById(widget.taskId);
      if (_task == null) {
        throw Exception('Không tìm thấy công việc này.');
      }

      final projectData = await _supabase
          .from(AppConstants.projectsTable)
          .select('team_id')
          .eq('id', _task!.projectId)
          .single();
      _currentProjectTeamId = projectData['team_id'] as String;

      if (_currentProjectTeamId != null) {
        final members = await _teamService.getTeamMembers(_currentProjectTeamId!);
        _myRoleInTeam = members
            .firstWhere(
                (m) => m.user.id == _supabase.auth.currentUser!.id, 
                orElse: () => TeamMemberModel( 
                      id: '', 
                      teamId: _currentProjectTeamId!,
                      user: UserModel( 
                        id: _supabase.auth.currentUser!.id,
                        email: _supabase.auth.currentUser!.email ?? '',
                        fullName: 'Người dùng hiện tại', 
                        createdAt: DateTime.now(),
                      ),
                      role: '', 
                      joinedAt: DateTime.now(),
                    ))
            .role;
      } else {
        throw Exception('Không tìm thấy nhóm cho dự án này.');
      }
    } catch (e) {
      print('Error loading task details: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'Lỗi tải chi tiết công việc: ${e.toString().split(':')[0]}';
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

  bool _canEditTask() {
    return _myRoleInTeam == AppConstants.roleOwner ||
           _myRoleInTeam == AppConstants.roleAdmin ||
           _task?.assigneeId == _supabase.auth.currentUser?.id;
  }

  bool _canDeleteTask() {
    return _myRoleInTeam == AppConstants.roleOwner ||
           _myRoleInTeam == AppConstants.roleAdmin;
  }

  Future<void> _toggleTaskStatus() async {
    if (_task == null || _isLoading) return;
    setState(() {
      _isLoading = true;
    });

    try {
      String newStatus;
      if (_task!.status == AppConstants.taskTodo) {
        newStatus = AppConstants.taskDoing;
      } else if (_task!.status == AppConstants.taskDoing) {
        newStatus = AppConstants.taskDone;
      } else {
        newStatus = AppConstants.taskTodo;
      }

      final updatedTask = _task!.copyWith(status: newStatus);
      final result = await _taskService.updateTask(updatedTask);
      setState(() {
        _task = result;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Trạng thái task đã được cập nhật thành "${_getStatusText(newStatus)}"'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      print('Error toggling task status: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi cập nhật trạng thái: ${e.toString().split(':')[0]}'),
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

  Future<void> _deleteTask() async {
    if (_task == null || _isLoading) return;

    final bool confirm = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Xác nhận xóa'),
          content: Text('Bạn có chắc chắn muốn xóa công việc "${_task!.title}"?'),
          actions: <Widget>[
            TextButton(
              onPressed: () => context.pop(false),
              child: const Text('Hủy', style: TextStyle(color: AppColors.grey)),
            ),
            ElevatedButton(
              onPressed: () => context.pop(true),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
              child: const Text('Xóa', style: TextStyle(color: AppColors.white)),
            ),
          ],
        );
      },
    ) ?? false;

    if (!confirm) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final bool deleted = await _taskService.deleteTask(widget.taskId);
      if (deleted && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Công việc đã được xóa thành công!'),
            backgroundColor: AppColors.success,
          ),
        );
        context.pop();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Không thể xóa công việc.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      print('Error deleting task: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi xóa công việc: ${e.toString().split(':')[0]}'),
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

  String _getStatusText(String status) {
    switch (status) {
      case AppConstants.taskTodo:
        return 'Cần làm';
      case AppConstants.taskDoing:
        return 'Đang làm';
      case AppConstants.taskDone:
        return 'Đã xong';
      default:
        return 'Không xác định';
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case AppConstants.taskTodo:
        return Icons.radio_button_unchecked;
      case AppConstants.taskDoing:
        return Icons.hourglass_empty;
      case AppConstants.taskDone:
        return Icons.check_circle;
      default:
        return Icons.info_outline;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case AppConstants.taskTodo:
        return AppColors.grey;
      case AppConstants.taskDoing:
        return AppColors.warning;
      case AppConstants.taskDone:
        return AppColors.success;
      default:
        return AppColors.grey;
    }
  }

  String _getPriorityText(String priority) {
    switch (priority) {
      case AppConstants.priorityLow:
        return 'Thấp';
      case AppConstants.priorityMedium:
        return 'Trung bình';
      case AppConstants.priorityHigh:
        return 'Cao';
      default:
        return 'Không xác định';
    }
  }

  IconData _getPriorityIcon(String priority) {
    switch (priority) {
      case AppConstants.priorityLow:
        return Icons.arrow_downward;
      case AppConstants.priorityMedium:
        return Icons.horizontal_rule;
      case AppConstants.priorityHigh:
        return Icons.arrow_upward;
      default:
        return Icons.info_outline;
    }
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case AppConstants.priorityLow:
        return AppColors.info;
      case AppConstants.priorityMedium:
        return AppColors.warning;
      case AppConstants.priorityHigh:
        return AppColors.error;
      default:
        return AppColors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          _task?.title ?? 'Chi tiết công việc',
          style: const TextStyle(
            color: AppColors.black,
            fontWeight: FontWeight.bold,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.black),
          onPressed: () => context.pop(),
        ),
        actions: [
          if (_task != null && _canEditTask())
            IconButton(
              icon: const Icon(Icons.edit, color: AppColors.primary),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Chức năng chỉnh sửa task chưa được triển khai.'),
                      backgroundColor: AppColors.info),
                );
              },
            ),
          if (_task != null && _canDeleteTask())
            IconButton(
              icon: const Icon(Icons.delete_outline, color: AppColors.error),
              onPressed: _deleteTask,
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
                  Text('Đang tải chi tiết công việc...', style: TextStyle(color: AppColors.grey)),
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
                          onPressed: _loadTaskDetails,
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
              : _task == null
                  ? const Center(
                      child: Text(
                        'Không tìm thấy công việc.',
                        style: TextStyle(fontSize: 18, color: AppColors.grey),
                      ),
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Card(
                            elevation: 5,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                            child: Padding(
                              padding: const EdgeInsets.all(20.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _task!.title,
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.black,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  if (_task!.description != null && _task!.description!.isNotEmpty)
                                    Text(
                                      _task!.description!,
                                      style: const TextStyle(fontSize: 15, color: AppColors.grey),
                                    ),
                                  if (_task!.description != null && _task!.description!.isNotEmpty)
                                    const SizedBox(height: 15),
                                  Divider(color: AppColors.lightGrey.withOpacity(0.5)),
                                  const SizedBox(height: 10),
                                  _buildInfoRow(
                                    _getStatusIcon(_task!.status),
                                    'Trạng thái:',
                                    _getStatusText(_task!.status),
                                    color: _getStatusColor(_task!.status),
                                    iconColor: _getStatusColor(_task!.status),
                                  ),
                                  const SizedBox(height: 8),
                                  _buildInfoRow(
                                    _getPriorityIcon(_task!.priority),
                                    'Độ ưu tiên:',
                                    _getPriorityText(_task!.priority),
                                    color: _getPriorityColor(_task!.priority),
                                    iconColor: _getPriorityColor(_task!.priority),
                                  ),
                                  const SizedBox(height: 8),
                                  _buildInfoRow(
                                    Icons.calendar_today,
                                    'Ngày tạo:',
                                    DateFormat('dd/MM/yyyy').format(_task!.createdAt),
                                    iconColor: AppColors.grey,
                                  ),
                                  if (_task!.dueDate != null) ...[
                                    const SizedBox(height: 8),
                                    _buildInfoRow(
                                      Icons.date_range,
                                      'Ngày đến hạn:',
                                      DateFormat('dd/MM/yyyy').format(_task!.dueDate!),
                                      iconColor: AppColors.grey,
                                    ),
                                  ],
                                  const SizedBox(height: 10),
                                  if (_task!.assigneeId != null)
                                    _buildAssigneeInfo(_task!.assigneeName, _task!.assigneeAvatarUrl),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          if (_task != null && _canEditTask())
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: _isLoading ? null : _toggleTaskStatus,
                                icon: _isLoading
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          color: AppColors.white,
                                          strokeWidth: 3,
                                        ),
                                      )
                                    : Icon(_getStatusIcon(_task!.status)),
                                label: Text(
                                  _isLoading
                                      ? 'Đang cập nhật...'
                                      : 'Chuyển trạng thái (${_getStatusText(_task!.status)})',
                                  style: const TextStyle(fontSize: 16),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _getStatusColor(_task!.status),
                                  foregroundColor: AppColors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 5,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value,
      {Color? color, Color? iconColor}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
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
            softWrap: true,
          ),
        ),
      ],
    );
  }

  Widget _buildAssigneeInfo(String? assigneeName, String? assigneeAvatarUrl) {
    return Row(
      children: [
        CircleAvatar(
          radius: 18,
          backgroundColor: AppColors.lightGrey,
          backgroundImage: assigneeAvatarUrl != null && assigneeAvatarUrl.isNotEmpty
              ? NetworkImage(assigneeAvatarUrl)
              : null,
          child: assigneeAvatarUrl == null || assigneeAvatarUrl.isEmpty
              ? const Icon(Icons.person, size: 22, color: AppColors.grey)
              : null,
        ),
        const SizedBox(width: 10),
        Text(
          'Người được giao: ${assigneeName ?? 'Chưa được giao'}',
          style: const TextStyle(fontSize: 15, color: AppColors.black),
        ),
      ],
    );
  }
}