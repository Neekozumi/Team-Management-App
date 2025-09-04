import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../models/task_model.dart';
import '../../models/user_model.dart'; 
import '../../services/task_service.dart';
import '../../services/team_service.dart'; 
import '../../models/team_member_model.dart';


class EditTaskScreen extends StatefulWidget {
  final String taskId;
  const EditTaskScreen({Key? key, required this.taskId}) : super(key: key);

  @override
  State<EditTaskScreen> createState() => _EditTaskScreenState();
}

class _EditTaskScreenState extends State<EditTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  final TaskService _taskService = TaskService();
  final TeamService _teamService = TeamService();

  TaskModel? _currentTask;
  List<TeamMemberModel> _teamMembers = []; 
  bool _isLoading = true;
  String? _selectedStatus;
  String? _selectedPriority;
  String? _selectedAssigneeId; 

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();


  @override
  void initState() {
    super.initState();
    _loadTaskData();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

Future<void> _loadTaskData() async {
  setState(() => _isLoading = true);
  try {
    _currentTask = await _taskService.getTaskById(widget.taskId);
    if (_currentTask == null) {
      throw Exception('Không tìm thấy công việc để chỉnh sửa.');
    }

    _titleController.text = _currentTask!.title;
    _descriptionController.text = _currentTask!.description ?? '';
    _selectedStatus = _currentTask!.status;
    _selectedPriority = _currentTask!.priority;
    _selectedAssigneeId = _currentTask!.assigneeId;

    final projectData = await Supabase.instance.client
        .from(AppConstants.projectsTable)
        .select('team_id')
        .eq('id', _currentTask!.projectId)
        .single();
    final String teamId = projectData['team_id'] as String;

    _teamMembers = await _teamService.getTeamMembers(teamId);

  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi tải dữ liệu công việc: ${e.toString().split(':')[0]}'),
          backgroundColor: AppColors.error,
        ),
      );
      context.pop(); 
    }
  } finally {
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }
}

  Future<void> _updateTask() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedStatus == null || _selectedPriority == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn trạng thái và độ ưu tiên.'), backgroundColor: AppColors.error),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final updatedTask = _currentTask!.copyWith(
        status: _selectedStatus!,
        priority: _selectedPriority!,
        assigneeId: _selectedAssigneeId, 
      );

      await _taskService.updateTask(updatedTask);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Công việc đã được cập nhật thành công!'), backgroundColor: AppColors.success),
        );
        context.pop(true);
      }
    } catch (e) {
      if (mounted) {
        print('Error updating task: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi cập nhật công việc: ${e.toString().split(':')[0]}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case AppConstants.taskTodo: return 'Cần làm';
      case AppConstants.taskDoing: return 'Đang làm';
      case AppConstants.taskDone: return 'Đã xong';
      default: return 'Không xác định';
    }
  }

  String _getPriorityText(String priority) {
    switch (priority) {
      case AppConstants.priorityLow: return 'Thấp';
      case AppConstants.priorityMedium: return 'Trung bình';
      case AppConstants.priorityHigh: return 'Cao';
      default: return 'Không xác định';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Chỉnh sửa công việc',
          style: TextStyle(
            color: AppColors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppColors.black),
          onPressed: () => context.pop(),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: AppColors.primary),
                  SizedBox(height: 16),
                  Text('Đang tải dữ liệu công việc...', style: TextStyle(color: AppColors.grey)),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: _titleController,
                      readOnly: true, 
                      decoration: InputDecoration(
                        labelText: 'Tiêu đề công việc',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        filled: true,
                        fillColor: AppColors.lightGrey.withOpacity(0.3),
                      ),
                      style: const TextStyle(color: AppColors.black, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _descriptionController,
                      readOnly: true, 
                      decoration: InputDecoration(
                        labelText: 'Mô tả công việc',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        filled: true,
                        fillColor: AppColors.lightGrey.withOpacity(0.3),
                      ),
                      maxLines: 4,
                      keyboardType: TextInputType.multiline,
                      style: const TextStyle(color: AppColors.black),
                    ),
                    const SizedBox(height: 20),

                    DropdownButtonFormField<String>(
                      value: _selectedStatus,
                      decoration: InputDecoration(
                        labelText: 'Trạng thái',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        filled: true,
                        fillColor: AppColors.white,
                      ),
                      hint: const Text('Chọn trạng thái'),
                      items: const [
                        DropdownMenuItem(
                          value: AppConstants.taskTodo,
                          child: Text('Cần làm'),
                        ),
                        DropdownMenuItem(
                          value: AppConstants.taskDoing,
                          child: Text('Đang làm'),
                        ),
                        DropdownMenuItem(
                          value: AppConstants.taskDone,
                          child: Text('Đã xong'),
                        ),
                      ],
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedStatus = newValue;
                        });
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Vui lòng chọn trạng thái.';
                        }
                        return null;
                      },
                      style: const TextStyle(color: AppColors.black),
                    ),
                    const SizedBox(height: 20),

                    DropdownButtonFormField<String>(
                      value: _selectedPriority,
                      decoration: InputDecoration(
                        labelText: 'Độ ưu tiên',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        filled: true,
                        fillColor: AppColors.white,
                      ),
                      hint: const Text('Chọn độ ưu tiên'),
                      items: const [
                        DropdownMenuItem(
                          value: AppConstants.priorityLow,
                          child: Text('Thấp'),
                        ),
                        DropdownMenuItem(
                          value: AppConstants.priorityMedium,
                          child: Text('Trung bình'),
                        ),
                        DropdownMenuItem(
                          value: AppConstants.priorityHigh,
                          child: Text('Cao'),
                        ),
                      ],
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedPriority = newValue;
                        });
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Vui lòng chọn độ ưu tiên.';
                        }
                        return null;
                      },
                      style: const TextStyle(color: AppColors.black),
                    ),
                    const SizedBox(height: 20),

                    DropdownButtonFormField<String>(
                      value: _selectedAssigneeId,
                      decoration: InputDecoration(
                        labelText: 'Người được giao (tùy chọn)',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        filled: true,
                        fillColor: AppColors.white,
                      ),
                      hint: const Text('Chọn người được giao'),
                      items: [
                        const DropdownMenuItem<String>(
                          value: null,
                          child: Text('Chưa được giao'),
                        ),
                        ..._teamMembers.map<DropdownMenuItem<String>>((teamMember) {
                          final UserModel user = teamMember.user ;
                          return DropdownMenuItem<String>(
                            value: user.id,
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 12,
                                  backgroundImage: user.avatarUrl != null && user.avatarUrl!.isNotEmpty
                                      ? NetworkImage(user.avatarUrl!)
                                      : null,
                                  child: user.avatarUrl == null || user.avatarUrl!.isEmpty
                                      ? const Icon(Icons.person, size: 16, color: AppColors.grey)
                                      : null,
                                ),
                                const SizedBox(width: 8),
                                Text(user.fullName ?? user.email),
                              ],
                            ),
                          );
                        }).toList(),
                      ],
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedAssigneeId = newValue;
                        });
                      },
                      style: const TextStyle(color: AppColors.black),
                    ),
                    const SizedBox(height: 30),

                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _updateTask,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text(
                                'Cập nhật công việc',
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}