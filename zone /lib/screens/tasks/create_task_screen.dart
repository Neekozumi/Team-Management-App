import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../models/task_model.dart';
import '../../models/user_model.dart';
import '../../models/team_member_model.dart'; 
import '../../services/task_service.dart';
import '../../services/team_service.dart';

class CreateTaskScreen extends StatefulWidget {
  final String projectId;
  const CreateTaskScreen({Key? key, required this.projectId}) : super(key: key);

  @override
  State<CreateTaskScreen> createState() => _CreateTaskScreenState();
}

class _CreateTaskScreenState extends State<CreateTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TaskService _taskService = TaskService();
  final TeamService _teamService = TeamService();
  final SupabaseClient _supabase = Supabase.instance.client;

  bool _isLoading = false;
  DateTime? _selectedDueDate;
  String _selectedStatus = AppConstants.taskTodo;
  String _selectedPriority = AppConstants.priorityMedium;
  String? _selectedAssigneeId; 
  List<TeamMemberModel> _rawTeamMembers = []; 
  List<DropdownMenuItem<String>> _assigneeDropdownItems = [];
  String? _currentProjectTeamId;

  @override
  void initState() {
    super.initState();
    _loadTeamMembers();
  }

  Future<void> _loadTeamMembers() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final projectData = await _supabase
          .from(AppConstants.projectsTable)
          .select('team_id')
          .eq('id', widget.projectId)
          .single();

      _currentProjectTeamId = projectData['team_id'] as String;

      if (_currentProjectTeamId != null) {
        _rawTeamMembers = await _teamService.getTeamMembers(_currentProjectTeamId!);

        _assigneeDropdownItems = [
          const DropdownMenuItem<String>(
            value: null, 
            child: Row(
              children: [
                Icon(Icons.person_off, color: AppColors.grey),
                SizedBox(width: 10),
                Text('Chưa được giao', style: TextStyle(color: AppColors.grey)),
              ],
            ),
          ),
          ..._rawTeamMembers.map<DropdownMenuItem<String>>((member) {
            return DropdownMenuItem<String>(
              value: member.user.id, 
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: AppColors.lightGrey,
                    backgroundImage: member.user.avatarUrl != null && member.user.avatarUrl!.isNotEmpty 
                        ? NetworkImage(member.user.avatarUrl!)
                        : null,
                    child: member.user.avatarUrl == null || member.user.avatarUrl!.isEmpty 
                        ? Text(
                            member.user.fullName?.isNotEmpty == true 
                                ? member.user.fullName![0].toUpperCase() 
                                : (member.user.email.isNotEmpty ? member.user.email[0].toUpperCase() : '?'),
                            style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w500),
                          )
                        : null,
                  ),
                  const SizedBox(width: 10),
                  Text(member.user.fullName ?? member.user.email), 
                ],
              ),
            );
          }).toList(),
        ];
      }
    } catch (e) {
      print('Error loading team members: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi tải thành viên nhóm: ${e.toString().split(':')[0]}'),
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

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _selectDueDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDueDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: AppColors.white,
              onSurface: AppColors.black,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDueDate) {
      setState(() {
        _selectedDueDate = picked;
      });
    }
  }

  Future<void> _createTask() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await _taskService.createTask(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        projectId: widget.projectId,
        assigneeId: _selectedAssigneeId, 
        status: _selectedStatus,
        priority: _selectedPriority,
        dueDate: _selectedDueDate,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Công việc đã được tạo thành công!'),
            backgroundColor: AppColors.success,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        print('Error creating task: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi tạo công việc: ${e.toString().split(':')[0]}'),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Tạo công việc mới',
          style: TextStyle(
            color: AppColors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.black),
          onPressed: () => context.pop(),
        ),
      ),
      body: _isLoading && _rawTeamMembers.isEmpty 
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
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
                      decoration: _inputDecoration('Tiêu đề công việc', Icons.task),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Tiêu đề công việc không được để trống';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _descriptionController,
                      maxLines: 4,
                      decoration: _inputDecoration('Mô tả công việc (tùy chọn)', Icons.description),
                    ),
                    const SizedBox(height: 20),
                    _buildDropdownField<String?>( 
                      'Người được giao (tùy chọn)',
                      Icons.person_outline,
                      _selectedAssigneeId,
                      _assigneeDropdownItems, 
                      (String? newValue) {
                        setState(() {
                          _selectedAssigneeId = newValue;
                        });
                      },
                      hintText: 'Chọn người được giao',
                    ),
                    const SizedBox(height: 20),
                    _buildDropdownField<String>( 
                      'Trạng thái',
                      Icons.assignment_turned_in_outlined,
                      _selectedStatus,
                      const [
                        DropdownMenuItem(value: AppConstants.taskTodo, child: Text('Cần làm')),
                        DropdownMenuItem(value: AppConstants.taskDoing, child: Text('Đang làm')),
                        DropdownMenuItem(value: AppConstants.taskDone, child: Text('Đã xong')),
                      ],
                      (String? newValue) {
                        if (newValue != null) {
                          setState(() {
                            _selectedStatus = newValue;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 20),
                    _buildDropdownField<String>( 
                      'Độ ưu tiên',
                      Icons.flag_outlined,
                      _selectedPriority,
                      const [
                        DropdownMenuItem(value: AppConstants.priorityLow, child: Text('Thấp')),
                        DropdownMenuItem(value: AppConstants.priorityMedium, child: Text('Trung bình')),
                        DropdownMenuItem(value: AppConstants.priorityHigh, child: Text('Cao')),
                      ],
                      (String? newValue) {
                        if (newValue != null) {
                          setState(() {
                            _selectedPriority = newValue;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 20),
                    GestureDetector(
                      onTap: () => _selectDueDate(context),
                      child: AbsorbPointer(
                        child: TextFormField(
                          controller: TextEditingController(
                            text: _selectedDueDate == null
                                ? ''
                                : DateFormat('dd/MM/yyyy').format(_selectedDueDate!),
                          ),
                          decoration: _inputDecoration('Ngày đến hạn (tùy chọn)', Icons.calendar_today),
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : _createTask,
                        icon: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: AppColors.white,
                                  strokeWidth: 3,
                                ),
                              )
                            : const Icon(Icons.add_circle_outline, size: 24),
                        label: Text(
                          _isLoading ? 'Đang tạo...' : 'Tạo công việc',
                          style: const TextStyle(fontSize: 18),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
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
            ),
    );
  }

  InputDecoration _inputDecoration(String labelText, IconData icon) {
    return InputDecoration(
      labelText: labelText,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.lightGrey),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
      prefixIcon: Icon(icon, color: AppColors.grey),
      filled: true,
      fillColor: AppColors.white,
    );
  }

  Widget _buildDropdownField<T>(
    String labelText,
    IconData icon,
    T? value,
    List<DropdownMenuItem<T>> items,
    ValueChanged<T?> onChanged, {
    String? hintText,
  }) {
    return InputDecorator(
      decoration: _inputDecoration(labelText, icon),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          hint: hintText != null ? Text(hintText, style: const TextStyle(color: AppColors.grey)) : null,
          isExpanded: true,
          onChanged: onChanged,
          items: items,
          style: const TextStyle(color: AppColors.black, fontSize: 16),
          icon: const Icon(Icons.arrow_drop_down, color: AppColors.grey),
          dropdownColor: AppColors.white, 
          elevation: 8, 
        ),
      ),
    );
  }
}