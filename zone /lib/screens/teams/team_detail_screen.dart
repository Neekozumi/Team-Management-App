import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; 
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../services/team_service.dart';
import '../../services/team_invitation_service.dart';
import '../../models/team_model.dart';
import '../../models/team_member_model.dart';
import '../../models/user_model.dart'; 
import '../../services/auth_service.dart';

class TeamDetailScreen extends StatefulWidget {
  final String teamId;
  const TeamDetailScreen({Key? key, required this.teamId}) : super(key: key);

  @override
  State<TeamDetailScreen> createState() => _TeamDetailScreenState();
}

class _TeamDetailScreenState extends State<TeamDetailScreen> {
  final TeamService _teamService = TeamService();
  final TeamInvitationService _invitationService = TeamInvitationService();
  final AuthService _authService = AuthService();
  final TextEditingController _emailCtrl = TextEditingController();

  TeamModel? _currentTeam;
  List<TeamMemberModel> _members = [];
  String? _myRole;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTeamDetails();
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadTeamDetails() async {
    setState(() => _isLoading = true);
    try {
      final currentUserId = Supabase.instance.client.auth.currentUser?.id;
      if (currentUserId == null) {
        if (mounted) context.go('/login');
        return;
      }

      _currentTeam = await _teamService.getTeamById(widget.teamId);
      if (_currentTeam == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Không tìm thấy nhóm này.'), backgroundColor: AppColors.error),
          );
          context.go('/teams');
        }
        return;
      }

      _members = await _teamService.getTeamMembers(widget.teamId);

      _myRole = _members.firstWhere(
        (m) => m.user.id == currentUserId, 
        orElse: () => TeamMemberModel(
          id: '',
          teamId: widget.teamId,
          user: UserModel( 
            id: currentUserId,
            email: '',
            fullName: 'Bạn',
            createdAt: DateTime.now(),
          ),
          role: '',
          joinedAt: DateTime.now(),
        ),
      ).role;

    } catch (e) {
      if (mounted) {
        print('Error loading team details: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi tải chi tiết nhóm: ${e.toString().split(':')[0]}'),
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

  Future<void> _inviteByEmail() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty || !RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập địa chỉ email hợp lệ.'), backgroundColor: AppColors.error),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final success = await _invitationService.sendEmailInvitation(widget.teamId, email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? 'Lời mời đã được gửi thành công!' : 'Gửi lời mời thất bại.'),
            backgroundColor: success ? AppColors.success : AppColors.error,
          ),
        );
        if (success) {
          Navigator.pop(context);
          _emailCtrl.clear();
        }
      }
    } catch (e) {
      if (mounted) {
        print('Error sending email invitation: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi gửi lời mời: ${e.toString().split(':')[0]}'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _copyInviteLink() async {
    setState(() => _isLoading = true);
    try {
      final link = await _invitationService.generateInviteLink(widget.teamId);
      await Clipboard.setData(ClipboardData(text: link));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã sao chép link mời!'), backgroundColor: AppColors.success),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        print('Error copying invite link: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi sao chép link: ${e.toString().split(':')[0]}'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _changeMemberRole(String memberUserId, String newRole) async {
    setState(() => _isLoading = true);
    try {
      final success = await _teamService.updateMemberRole(widget.teamId, memberUserId, newRole);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? 'Đã cập nhật vai trò thành công!' : 'Cập nhật vai trò thất bại.'),
            backgroundColor: success ? AppColors.success : AppColors.error,
          ),
        );
        if (success) {
          Navigator.pop(context);
          _loadTeamDetails();
        }
      }
    } catch (e) {
      if (mounted) {
        print('Error changing member role: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi thay đổi vai trò: ${e.toString().split(':')[0]}'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _removeMember(String memberUserId) async {
    setState(() => _isLoading = true);
    try {
      final success = await _teamService.removeMember(widget.teamId, memberUserId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? 'Đã xóa thành viên thành công!' : 'Xóa thành viên thất bại.'),
            backgroundColor: success ? AppColors.success : AppColors.error,
          ),
        );
        if (success) _loadTeamDetails();
      }
    } catch (e) {
      if (mounted) {
        print('Error removing member: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi xóa thành viên: ${e.toString().split(':')[0]}'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          _currentTeam?.name ?? 'Chi tiết nhóm',
          style: const TextStyle(
            color: AppColors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.black),
          onPressed: () => context.go('/teams'),
        ),
        actions: [
          if (_myRole == AppConstants.roleOwner || _myRole == AppConstants.roleAdmin)
            IconButton(
              icon: const Icon(Icons.person_add, color: AppColors.black),
              onPressed: () => _showInviteDialog(),
            )
        ],
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: AppColors.primary),
                  SizedBox(height: 16),
                  Text(
                    'Đang tải chi tiết nhóm...',
                    style: TextStyle(color: AppColors.grey),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadTeamDetails,
              color: AppColors.primary,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTeamOverviewCard(),
                    const SizedBox(height: 24),

                    Card(
                      margin: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 2,
                      child: InkWell(
                        onTap: () {
                          context.push('/team_detail/${widget.teamId}/projects');
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          child: Row(
                            children: [
                              Icon(Icons.folder_open, color: AppColors.primary),
                              SizedBox(width: 16),
                              Expanded(
                                child: Text(
                                  'Xem các dự án của nhóm',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.black,
                                  ),
                                ),
                              ),
                              Icon(Icons.arrow_forward_ios, color: AppColors.grey, size: 18),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    const Text(
                      'Thành viên',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.black,
                      ),
                    ),
                    const SizedBox(height: 16),

                    _members.isEmpty
                        ? _buildNoMembersView()
                        : ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _members.length,
                            itemBuilder: (ctx, index) {
                              final member = _members[index];
                              final isSelf = member.user.id == currentUserId; // <-- DÙNG member.user.id
                              final canChangeRole = (_myRole == AppConstants.roleOwner) &&
                                  !isSelf &&
                                  member.role != AppConstants.roleOwner;
                              final canRemoveMember = (_myRole == AppConstants.roleOwner ||
                                      _myRole == AppConstants.roleAdmin) &&
                                  !isSelf &&
                                  member.role != AppConstants.roleOwner;

                              return _buildMemberTile(member, canChangeRole, canRemoveMember);
                            },
                          ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildTeamOverviewCard() {
    if (_currentTeam == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(20),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _currentTeam!.name,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.black,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _currentTeam!.description ?? 'Chưa có mô tả cho nhóm này.',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.grey.withOpacity(0.8),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.person, color: AppColors.primary, size: 18),
              const SizedBox(width: 8),
              Text(
                'Chủ sở hữu: ${_currentTeam!.ownerName ?? 'N/A'}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.people_alt, color: AppColors.grey, size: 18),
              const SizedBox(width: 8),
              Text(
                'Số thành viên: ${_members.length}',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.grey.withOpacity(0.8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.work, color: AppColors.grey, size: 18),
              const SizedBox(width: 8),
              Text(
                'Vai trò của bạn: ${_getRoleDisplay(_myRole)}',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.grey.withOpacity(0.8),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMemberTile(
      TeamMemberModel member, bool canChangeRole, bool canRemoveMember) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.primary.withOpacity(0.1),
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
        title: Text(
          member.user.fullName?.isNotEmpty == true 
              ? member.user.fullName! 
              : member.user.email,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(_getRoleDisplay(member.role)),
        trailing: (canChangeRole || canRemoveMember)
            ? PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'change_role') {
                    _showRoleDialog(member);
                  } else if (value == 'remove_member') {
                    _confirmRemoveMember(member);
                  }
                },
                itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                  if (canChangeRole)
                    const PopupMenuItem<String>(
                      value: 'change_role',
                      child: Text('Thay đổi vai trò'),
                    ),
                  if (canRemoveMember)
                    const PopupMenuItem<String>(
                      value: 'remove_member',
                      child: Text('Xóa thành viên'),
                    ),
                ],
              )
            : null,
      ),
    );
  }

  Widget _buildNoMembersView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_alt_outlined,
              size: 64,
              color: AppColors.grey.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            const Text(
              'Chưa có thành viên nào khác',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: AppColors.grey,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Mời thêm thành viên để cùng cộng tác!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.grey.withOpacity(0.8),
              ),
            ),
            if (_myRole == AppConstants.roleOwner || _myRole == AppConstants.roleAdmin)
              Padding(
                padding: const EdgeInsets.only(top: 24),
                child: ElevatedButton.icon(
                  onPressed: _showInviteDialog,
                  icon: const Icon(Icons.person_add),
                  label: const Text('Mời thành viên'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showInviteDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Mời thành viên mới'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Địa chỉ Email (tùy chọn)',
                hintText: 'nguoidung@example.com',
                prefixIcon: Icon(Icons.email_outlined),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Hoặc chia sẻ link mời:', style: TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _copyInviteLink,
                icon: const Icon(Icons.copy),
                label: const Text('Sao chép link mời'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondary,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
          _emailCtrl.text.isNotEmpty
              ? ElevatedButton(onPressed: _inviteByEmail, child: const Text('Gửi lời mời Email'))
              : const SizedBox.shrink(),
        ],
      ),
    ).then((_) {
      _emailCtrl.clear();
    });
  }

  void _showRoleDialog(TeamMemberModel member) {
    String? tempSelectedRole = member.role;

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              title: Text('Thay đổi vai trò cho ${member.user.fullName ?? member.user.email}'), // <-- DÙNG member.user.fullName
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    title: const Text('Thành viên (Member)'),
                    leading: Radio<String>(
                      value: AppConstants.roleMember,
                      groupValue: tempSelectedRole,
                      onChanged: (String? value) {
                        setState(() {
                          tempSelectedRole = value;
                        });
                      },
                    ),
                  ),
                  ListTile(
                    title: const Text('Quản trị viên (Admin)'),
                    leading: Radio<String>(
                      value: AppConstants.roleAdmin,
                      groupValue: tempSelectedRole,
                      onChanged: (String? value) {
                        setState(() {
                          tempSelectedRole = value;
                        });
                      },
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Hủy'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (tempSelectedRole != null && tempSelectedRole != member.role) {
                      _changeMemberRole(member.user.id, tempSelectedRole!); // <-- DÙNG member.user.id
                    } else {
                      Navigator.pop(dialogContext);
                    }
                  },
                  child: const Text('Lưu'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _confirmRemoveMember(TeamMemberModel member) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận xóa thành viên'),
        content: Text('Bạn có chắc chắn muốn xóa "${member.user.fullName ?? member.user.email}" khỏi nhóm này không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _removeMember(member.user.id); 
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Xóa', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  String _getRoleDisplay(String? role) {
    switch (role) {
      case AppConstants.roleOwner:
        return 'Chủ sở hữu';
      case AppConstants.roleAdmin:
        return 'Quản trị viên';
      case AppConstants.roleMember:
        return 'Thành viên';
      default:
        return 'Không xác định';
    }
  }
}