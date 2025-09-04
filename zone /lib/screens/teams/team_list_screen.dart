import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; 
import '../../core/constants/app_colors.dart';
import '../../services/team_service.dart';
import '../../services/team_invitation_service.dart'; 
import '../../models/team_model.dart';

class TeamListScreen extends StatefulWidget {
  const TeamListScreen({Key? key}) : super(key: key);

  @override
  State<TeamListScreen> createState() => _TeamListScreenState();
}

class _TeamListScreenState extends State<TeamListScreen> with SingleTickerProviderStateMixin {
  final TeamService _teamService = TeamService(); 
  List<TeamModel> _ownedTeams = [], _joinedTeams = []; 
  bool _isLoading = true; 
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadTeams(); 
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadTeams() async {
    setState(() => _isLoading = true);
    try {
      final allTeams = await _teamService.getUserTeams();
      final currentUserId = Supabase.instance.client.auth.currentUser!.id;

      _ownedTeams = allTeams.where((t) => t.ownerId == currentUserId).toList();
      _joinedTeams = allTeams.where((t) => t.ownerId != currentUserId).toList();
    } catch (e) {
      if (mounted) {
        print('Error loading teams: $e'); 
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Không thể tải danh sách nhóm: ${e.toString().split(':')[0]}'), 
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

  void _showJoinTeamDialog() {
    final TextEditingController _codeController = TextEditingController();
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Tham gia nhóm'),
          content: TextField(
            controller: _codeController,
            decoration: const InputDecoration(
              hintText: 'Nhập mã tham gia nhóm',
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Hủy'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            ElevatedButton(
              child: const Text('Tham gia'),
              onPressed: () async {
                final code = _codeController.text.trim();
                if (code.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Mã không được để trống.'), backgroundColor: AppColors.error),
                  );
                  return;
                }
                Navigator.of(dialogContext).pop(); // Đóng dialog

                final teamInvitationService = TeamInvitationService();
                final success = await teamInvitationService.joinTeamByCode(code);

                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Tham gia nhóm thành công!'), backgroundColor: AppColors.success),
                  );
                  _loadTeams();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Tham gia nhóm thất bại. Mã không hợp lệ hoặc đã hết hạn.'), backgroundColor: AppColors.error),
                  );
                }
              },
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
        title: const Text(
          'Các nhóm của tôi', 
          style: TextStyle(
            color: AppColors.black,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.black),
          onPressed: () => context.go('/home'), 
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            child: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.add, color: Colors.white, size: 20),
              ),
              onPressed: () => context.push('/create_team'), 
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          indicatorWeight: 3,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.grey,
          labelStyle: const TextStyle(fontWeight: FontWeight.w600),
          tabs: [
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.star, size: 16), 
                  const SizedBox(width: 4),
                  Text('Nhóm của tôi (${_ownedTeams.length})'), 
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.group, size: 16), 
                  const SizedBox(width: 4),
                  Text('Đã tham gia (${_joinedTeams.length})'), 
                ],
              ),
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: AppColors.primary),
                  SizedBox(height: 16),
                  Text(
                    'Đang tải danh sách nhóm...',
                    style: TextStyle(color: AppColors.grey),
                  ),
                ],
              ),
            )
          : TabBarView(
              controller: _tabController,
              children: [
                _buildTeamList(_ownedTeams, true), 
                _buildTeamList(_joinedTeams, false), 
              ],
            ),
    );
  }

  Widget _buildTeamList(List<TeamModel> teams, bool isOwnerTab) { 
    if (teams.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isOwnerTab ? Icons.create_new_folder : Icons.group_add,
              size: 64,
              color: AppColors.grey.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              isOwnerTab ? 'Bạn chưa tạo nhóm nào' : 'Bạn chưa tham gia nhóm nào',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: AppColors.grey,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isOwnerTab
                  ? 'Tạo nhóm đầu tiên của bạn để bắt đầu'
                  : 'Tham gia một nhóm để hợp tác với người khác',
              textAlign: TextAlign.center, 
              style: TextStyle(
                fontSize: 14,
                color: AppColors.grey.withOpacity(0.8),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isOwnerTab) 
                  ElevatedButton.icon(
                    onPressed: () => context.push('/create_team'), 
                    icon: const Icon(Icons.add),
                    label: const Text('Tạo nhóm mới'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                if (!isOwnerTab) 
                  ElevatedButton.icon(
                    onPressed: () => _showJoinTeamDialog(), 
                    icon: const Icon(Icons.person_add),
                    label: const Text('Tham gia nhóm'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadTeams, 
      color: AppColors.primary,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: teams.length,
        itemBuilder: (context, index) {
          final team = teams[index];
          return _buildTeamCard(team, isOwnerTab); 
        },
      ),
    );
  }

  Widget _buildTeamCard(TeamModel team, bool isOwnerTab) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => context.push('/team_detail/${team.id}'),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isOwnerTab ? AppColors.primary.withOpacity(0.1) : AppColors.secondary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  isOwnerTab ? Icons.star : Icons.group,
                  color: isOwnerTab ? AppColors.primary : AppColors.secondary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      team.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.black,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: isOwnerTab ? AppColors.primary : AppColors.secondary,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            isOwnerTab ? 'Chủ sở hữu' : 'Thành viên', 
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (!isOwnerTab && team.ownerName != null)
                          Expanded( 
                            child: Text(
                              '(${team.ownerName})', 
                              overflow: TextOverflow.ellipsis, 
                              style: TextStyle(
                                color: AppColors.grey.withOpacity(0.8),
                                fontSize: 12,
                              ),
                            ),
                          ),
                        const Spacer(),
                        Text(
                          'Xem chi tiết', 
                          style: TextStyle(
                            color: AppColors.grey.withOpacity(0.8),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: AppColors.grey.withOpacity(0.6),
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}