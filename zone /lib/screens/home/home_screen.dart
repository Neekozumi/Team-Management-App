import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zone/core/constants/app_constants.dart';
import 'package:zone/services/team_invitation_service.dart';

import '../../core/constants/app_colors.dart';
import '../../services/auth_service.dart';
import '../../services/team_service.dart';
import '../../services/project_service.dart'; 
import '../../models/user_model.dart';
import '../../models/team_model.dart';
import '../../models/project_model.dart'; 

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AuthService _authService = AuthService();
  final TeamService _teamService = TeamService();
  final ProjectService _projectService = ProjectService(); 
  UserModel? _currentUser;
  List<TeamModel> _userTeams = [];
  TeamModel? _selectedTeam;
  List<ProjectModel> _recentProjects = []; 
  int _selectedIndex = 0; 
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserDataAndProjects();
  }

  Future<void> _loadUserDataAndProjects() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final session = Supabase.instance.client.auth.currentSession;
      if (session != null) {
        final user = await _authService.getCurrentUser();
        if (user != null && mounted) {
          final teams = await _teamService.getUserTeams();
          setState(() {
            _currentUser = user;
            _userTeams = teams;
            _selectedTeam = teams.isNotEmpty ? teams.first : null;
          });

          if (_selectedTeam != null) {
            final projects = await _projectService.getProjectsByTeam(_selectedTeam!.id);
            setState(() {
              _recentProjects = projects.take(3).toList();
            });
          } else {
            setState(() {
              _recentProjects = [];
            });
          }
        }
      } else {
        if (mounted) context.go('/login');
      }
    } catch (e) {
      print('Error loading user data or teams/projects: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Không thể tải dữ liệu: ${e.toString().split(':')[0]}'),
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

  Future<void> _refreshData() async {
    await _loadUserDataAndProjects();
  }

  void _onNavTap(int index) {
    if (index == 3) {
      context.go('/profile');
    } else {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  void _showTeamOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.white, 
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Quản lý nhóm',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.black,
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.list, color: AppColors.primary),
              title: const Text('Danh sách nhóm của tôi', style: TextStyle(color: AppColors.black)),
              onTap: () {
                Navigator.pop(context);
                context.push('/teams'); 
              },
            ),
            ListTile(
              leading: const Icon(Icons.add, color: AppColors.primary),
              title: const Text('Tạo nhóm mới', style: TextStyle(color: AppColors.black)),
              onTap: () {
                Navigator.pop(context);
                context.push('/create_team'); 
              },
            ),
            ListTile(
              leading: const Icon(Icons.person_add, color: AppColors.primary),
              title: const Text('Tham gia nhóm bằng mã', style: TextStyle(color: AppColors.black)),
              onTap: () {
                Navigator.pop(context);
                _showJoinTeamDialog(); 
              },
            ),
            if (_selectedTeam != null)
              ListTile(
                leading: const Icon(Icons.info, color: AppColors.primary),
                title: Text('Chi tiết nhóm "${_selectedTeam!.name}"', style: const TextStyle(color: AppColors.black)),
                onTap: () {
                  Navigator.pop(context);
                  context.push('/team_detail/${_selectedTeam!.id}'); // Điều hướng đến TeamDetailScreen
                },
              ),
          ],
        ),
      ),
    );
  }

  void _showJoinTeamDialog() {
    final TextEditingController _codeController = TextEditingController();
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Tham gia nhóm', style: TextStyle(color: AppColors.black)),
          content: TextField(
            controller: _codeController,
            decoration: const InputDecoration(
              hintText: 'Nhập mã tham gia nhóm',
              hintStyle: TextStyle(color: AppColors.grey),
            ),
            style: const TextStyle(color: AppColors.black),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Hủy', style: TextStyle(color: AppColors.grey)),
            ),
            ElevatedButton(
              onPressed: () async {
                final code = _codeController.text.trim();
                if (code.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Mã không được để trống.'), backgroundColor: AppColors.error),
                  );
                  return;
                }
                Navigator.of(dialogContext).pop(); 

                final teamInvitationService = TeamInvitationService();
                final success = await teamInvitationService.joinTeamByCode(code);

                if (success) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Tham gia nhóm thành công!'), backgroundColor: AppColors.success),
                    );
                    _refreshData(); 
                  }
                } else {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Tham gia nhóm thất bại. Mã không hợp lệ hoặc đã hết hạn.'), backgroundColor: AppColors.error),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: AppColors.white),
              child: const Text('Tham gia'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.white, 
        elevation: 0,
        title: const Text(
          'zone',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: AppColors.black),
            onPressed: () {
            },
          ),
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: AppColors.black),
            onPressed: () {
            },
          ),
          IconButton(
            icon: const Icon(Icons.group, color: AppColors.black),
            onPressed: _showTeamOptions,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : RefreshIndicator(
              onRefresh: _refreshData,
              color: AppColors.primary,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.waving_hand, color: Colors.orange, size: 24),
                          const SizedBox(width: 8),
                          const Text(
                            'HELLO',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: AppColors.black,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        _currentUser!.fullName?.toUpperCase() ?? 'BẠN', 
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppColors.black,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Work Hard, Succeed Together!',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.grey,
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      _buildTeamSelector(),
                      const SizedBox(height: 24),
                      
                      Row(
                        children: [
                          _buildTabButton('Hôm nay', 0),
                          const SizedBox(width: 8),
                          _buildTabButton('Hôm sau', 1),
                          const SizedBox(width: 8),
                          _buildTabButton('Calendar', 2),
                        ],
                      ),
                      const SizedBox(height: 24),
                      
                      if (_selectedTeam != null) _buildTeamStatsCard(),
                      if (_selectedTeam != null) const SizedBox(height: 24),

                      if (_selectedTeam != null && _recentProjects.isNotEmpty) ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Dự án gần đây',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.black,
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                if (_selectedTeam != null) {
                                  context.push('/team_detail/${_selectedTeam!.id}/projects');
                                }
                              },
                              child: const Text(
                                'Xem tất cả >',
                                style: TextStyle(color: AppColors.grey),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildRecentProjectsList(), 
                        const SizedBox(height: 24),
                      ],
                      
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _selectedTeam != null && _selectedIndex == 0
                                ? 'Công việc hôm nay của ${_selectedTeam!.name}'
                                : (_selectedTeam != null && _selectedIndex == 1
                                    ? 'Công việc sắp tới của ${_selectedTeam!.name}'
                                    : 'Công việc cá nhân'),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.black,
                            ),
                          ),
                          if (_selectedTeam != null) 
                            TextButton(
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Chức năng xem tất cả công việc chưa được triển khai.'), backgroundColor: AppColors.info),
                                );
                              },
                              child: const Text(
                                'Xem tất cả >',
                                style: TextStyle(color: AppColors.grey),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      Expanded(
                        child: _userTeams.isEmpty
                            ? _buildNoTeamView()
                            : _buildTasksList(), 
                      ),
                    ],
                  ),
                ),
              ),
            ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.black, 
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: BottomNavigationBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          type: BottomNavigationBarType.fixed,
          currentIndex: _selectedIndex,
          onTap: _onNavTap,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.grey, 
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: '',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.access_time),
              label: '',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.calendar_today),
              label: '',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person),
              label: '',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTeamSelector() {
    if (_userTeams.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.white, 
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.lightGrey),
        ),
        child: Row(
          children: [
            const Icon(Icons.info_outline, color: AppColors.grey),
            const SizedBox(width: 8),
            const Text(
              'Bạn chưa tham gia nhóm nào',
              style: TextStyle(color: AppColors.grey),
            ),
            const Spacer(),
            TextButton(
              onPressed: () async {
                 final result = await context.push('/create_team');
                 if (result == true) { 
                   _refreshData();
                 }
              },
              child: const Text('Tạo nhóm', style: TextStyle(color: AppColors.primary)),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.lightGrey),
      ),
      child: DropdownButton<TeamModel>(
        value: _selectedTeam,
        isExpanded: true,
        underline: Container(),
        icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.grey), // Màu icon dropdown
        items: _userTeams.map((team) {
          return DropdownMenuItem<TeamModel>(
            value: team,
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        team.name,
                        style: const TextStyle(fontWeight: FontWeight.w500, color: AppColors.black),
                      ),
                      if (team.ownerName != null && team.ownerName!.isNotEmpty)
                        Text(
                          'Owner: ${team.ownerName}',
                          style: const TextStyle(fontSize: 12, color: AppColors.grey),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
        onChanged: (TeamModel? newTeam) {
          if (newTeam != null) {
            setState(() {
              _selectedTeam = newTeam;
              _recentProjects = []; 
              _isLoading = true; 
            });
            _projectService.getProjectsByTeam(newTeam.id).then((projects) {
              if (mounted) {
                setState(() {
                  _recentProjects = projects.take(3).toList();
                  _isLoading = false;
                });
              }
            }).catchError((e) {
              print('Error loading projects for new team: $e');
              if (mounted) {
                setState(() {
                  _isLoading = false;
                });
              }
            });
          }
        },
      ),
    );
  }

  Widget _buildTeamStatsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.group, color: AppColors.white),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Team: ${_selectedTeam!.name}',
                  style: const TextStyle(
                    color: AppColors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                if (_selectedTeam!.ownerName != null && _selectedTeam!.ownerName!.isNotEmpty)
                  Text(
                    'Owner: ${_selectedTeam!.ownerName}',
                    style: TextStyle(
                      color: AppColors.white.withOpacity(0.8),
                      fontSize: 12,
                    ),
                  ),
                Text(
                  'Bạn có 4 việc trong hôm nay', 
                  style: TextStyle(
                    color: AppColors.white.withOpacity(0.8), 
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.arrow_forward_ios, color: AppColors.white),
            onPressed: () => context.push('/team_detail/${_selectedTeam!.id}'), // Sử dụng push
          ),
        ],
      ),
    );
  }

  Widget _buildNoTeamView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.group_add,
            size: 64,
            color: AppColors.grey,
          ),
          const SizedBox(height: 16),
          const Text(
            'Chưa có nhóm nào',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.grey,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Tạo nhóm mới hoặc tham gia nhóm\nđể bắt đầu làm việc cùng nhau',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.grey,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: () async {
                  final result = await context.push('/create_team');
                  if (result == true) {
                    _refreshData();
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.white,
                ),
                child: const Text('Tạo nhóm'),
              ),
              const SizedBox(width: 12),
              OutlinedButton(
                onPressed: () => _showJoinTeamDialog(),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                ),
                child: const Text('Tham gia nhóm'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(String title, int index) {
    bool isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedIndex = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.white, 
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.lightGrey,
          ),
        ),
        child: Text(
          title,
          style: TextStyle(
            color: isSelected ? AppColors.white : AppColors.black, 
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildTaskCard(
    String title,
    String description,
    String time,
    Color statusColor,
    List<String> avatars,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.grey.withOpacity(0.1), 
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentProjectsList() {
    if (_recentProjects.isEmpty) {
      return const SizedBox.shrink(); 
    }

    return Column(
      children: _recentProjects.map((project) {
        IconData statusIcon;
        Color statusColor;
        String statusText;

        switch (project.status) {
          case AppConstants.projectActive:
            statusIcon = Icons.play_arrow_rounded;
            statusColor = AppColors.success;
            statusText = 'Đang hoạt động';
            break;
          case AppConstants.projectCompleted:
            statusIcon = Icons.check_circle_outline;
            statusColor = AppColors.info;
            statusText = 'Hoàn thành';
            break;
          case AppConstants.projectPaused:
            statusIcon = Icons.pause_circle_outline;
            statusColor = AppColors.warning;
            statusText = 'Tạm dừng';
            break;
          default:
            statusIcon = Icons.info_outline;
            statusColor = AppColors.grey;
            statusText = 'Không xác định';
        }

        return Card(
          margin: const EdgeInsets.only(bottom: 12), 
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          elevation: 2,
          child: InkWell(
            onTap: () => context.push('/projects/${project.id}'), 
            borderRadius: BorderRadius.circular(10),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(statusIcon, color: statusColor, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          project.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.black,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        statusText,
                        style: TextStyle(
                          fontSize: 12,
                          color: statusColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  if (project.description != null && project.description!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      project.description!,
                      style: const TextStyle(fontSize: 13, color: AppColors.grey),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Icon(Icons.calendar_today, color: AppColors.grey, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        'Tạo: ${project.createdAt.day}/${project.createdAt.month}/${project.createdAt.year}',
                        style: const TextStyle(fontSize: 11, color: AppColors.grey),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }


  Widget _buildTasksList() {
    return ListView(
      children: [
        _buildTaskCard(
          'Phát triển (Dev Team)',
          'Fix bug không hiển thị avatar trong comment\nTích hợp công cụ testing Google\nTriển khai animation UI tốt hơn trong mobile app',
          '7:00 am - 8:00 am',
          AppColors.error,
          ['A1', 'A2', 'A3', '+2'],
        ),
        const SizedBox(height: 12),
        _buildTaskCard(
          'Marketing',
          'Viết nội dung email cho chiến dịch user mới\nChuẩn bị báo cáo hiệu suất Facebook Ads\nLên kịch bản video về sản phẩm mới',
          '9:30 am - 11:00 am',
          AppColors.success,
          ['M1', 'M2', 'M3'],
        ),
        const SizedBox(height: 12),
        _buildTaskCard(
          'Team Meeting',
          'Daily standup meeting\nReview sprint progress\nPlan next sprint tasks',
          '2:00 pm - 3:00 pm',
          AppColors.primary,
          ['T1', 'T2', 'T3', 'T4'],
        ),
      ],
    );
  }
}