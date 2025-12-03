import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/admin_user.dart';
import '../models/api_models.dart';
import '../services/auth_service.dart';
import '../viewmodels/admin_viewmodel.dart';

class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Get auth token and set it to AdminViewModel
      final token = await AuthService().getToken();
      if (token != null && mounted) {
        context.read<AdminViewModel>().setAuthToken(token);
        // Now load data
        context.read<AdminViewModel>().refresh();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width > 1024;
    final isTablet = width > 768;

    final List<Widget> screens = [
      // Users Tab
      RefreshIndicator(
        onRefresh: () => context.read<AdminViewModel>().refresh(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.all(isDesktop ? 32 : 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Statistics Cards
              _buildStatsSection(isDesktop, isTablet),
              const SizedBox(height: 24),

              // Search Bar
              _buildSearchBar(),
              const SizedBox(height: 24),

              // Users Table
              _buildUsersTable(isDesktop, isTablet),
              const SizedBox(height: 24),

              // Pagination
              _buildPagination(),
            ],
          ),
        ),
      ),

      // Farms Tab
      _buildFarmsTab(isDesktop, isTablet),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF5F8F6),
      appBar: AppBar(
        title: const Text(
          'Quản Trị Hệ Thống',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<AdminViewModel>().refresh();
            },
            tooltip: 'Làm mới',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              // Show confirmation dialog
              final shouldLogout = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Đăng xuất'),
                  content: const Text('Bạn có chắc chắn muốn đăng xuất?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Hủy'),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFEF4444),
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Đăng xuất'),
                    ),
                  ],
                ),
              );

              if (shouldLogout == true && context.mounted) {
                // Import AuthService at the top if not already imported
                await AuthService().logout();
                if (context.mounted) {
                  Navigator.pushReplacementNamed(context, '/login');
                }
              }
            },
            tooltip: 'Đăng xuất',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.people_outline),
            selectedIcon: Icon(Icons.people),
            label: 'Người Dùng',
          ),
          NavigationDestination(
            icon: Icon(Icons.landscape_outlined),
            selectedIcon: Icon(Icons.landscape),
            label: 'Vùng Trồng',
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection(bool isDesktop, bool isTablet) {
    return Consumer<AdminViewModel>(
      builder: (context, viewModel, child) {
        if (viewModel.isLoadingStats) {
          return const Center(child: CircularProgressIndicator());
        }

        final stats = viewModel.stats;
        if (stats == null) {
          return const SizedBox.shrink();
        }

        final statCards = [
          _StatCard(
            title: 'Tổng Người Dùng',
            value: stats.totalUsers.toString(),
            icon: Icons.people,
            color: const Color(0xFF0BDA50),
          ),
          _StatCard(
            title: 'Đang Hoạt Động',
            value: stats.activeUsers.toString(),
            icon: Icons.check_circle,
            color: const Color(0xFF10B981),
          ),
          _StatCard(
            title: 'Không Hoạt Động',
            value: stats.inactiveUsers.toString(),
            icon: Icons.cancel,
            color: const Color(0xFFEF4444),
          ),
          _StatCard(
            title: 'Quản Trị Viên',
            value: stats.superusers.toString(),
            icon: Icons.admin_panel_settings,
            color: const Color(0xFF608a6e),
          ),
        ];

        if (isDesktop) {
          return Row(
            children: statCards
                .map((card) => Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: card,
                      ),
                    ))
                .toList(),
          );
        } else if (isTablet) {
          return Wrap(
            spacing: 16,
            runSpacing: 16,
            children: statCards
                .map((card) => SizedBox(
                      width: (MediaQuery.of(context).size.width - 48) / 2,
                      child: card,
                    ))
                .toList(),
          );
        } else {
          return Column(
            children: statCards
                .map((card) => Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: card,
                    ))
                .toList(),
          );
        }
      },
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF0F5F1)),
      ),
      child: Row(
        children: [
          const Icon(Icons.search, color: Color(0xFF608a6e)),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Tìm kiếm theo email, tên người dùng...',
                border: InputBorder.none,
                hintStyle: TextStyle(color: Color(0xFF9ca3af)),
              ),
              onSubmitted: (value) {
                context.read<AdminViewModel>().searchUsers(value);
              },
            ),
          ),
          if (_searchController.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear, color: Color(0xFF608a6e)),
              onPressed: () {
                _searchController.clear();
                context.read<AdminViewModel>().clearSearch();
              },
            ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () {
              context
                  .read<AdminViewModel>()
                  .searchUsers(_searchController.text);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0BDA50),
              foregroundColor: const Color(0xFF111813),
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Tìm kiếm',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUsersTable(bool isDesktop, bool isTablet) {
    return Consumer<AdminViewModel>(
      builder: (context, viewModel, child) {
        if (viewModel.isLoading) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(
                color: Color(0xFF0BDA50),
              ),
            ),
          );
        }

        if (viewModel.errorMessage != null) {
          return Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFF0F5F1)),
            ),
            child: Column(
              children: [
                const Icon(Icons.error_outline,
                    size: 48, color: Color(0xFFEF4444)),
                const SizedBox(height: 16),
                Text(
                  viewModel.errorMessage!,
                  style: const TextStyle(color: Color(0xFFEF4444)),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => viewModel.refresh(),
                  child: const Text('Thử lại'),
                ),
              ],
            ),
          );
        }

        if (viewModel.users.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(48),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFF0F5F1)),
            ),
            child: const Center(
              child: Column(
                children: [
                  Icon(Icons.people_outline,
                      size: 64, color: Color(0xFF9ca3af)),
                  SizedBox(height: 16),
                  Text(
                    'Không tìm thấy người dùng',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF4B5563),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        if (isDesktop || isTablet) {
          return _buildDesktopTable(viewModel.users);
        } else {
          return _buildMobileList(viewModel.users);
        }
      },
    );
  }

  Widget _buildDesktopTable(List<AdminUser> users) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF0F5F1)),
      ),
      child: Column(
        children: [
          // Table Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Color(0xFFF5F8F6),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: _buildHeaderCell('Email'),
                ),
                Expanded(
                  flex: 2,
                  child: _buildHeaderCell('Tên người dùng'),
                ),
                Expanded(
                  flex: 2,
                  child: _buildHeaderCell('Họ và tên'),
                ),
                Expanded(
                  flex: 1,
                  child: _buildHeaderCell('Trạng thái'),
                ),
                Expanded(
                  flex: 1,
                  child: _buildHeaderCell('Ngày tạo'),
                ),
                const SizedBox(
                    width: 120, child: Center(child: Text('Hành động'))),
              ],
            ),
          ),
          // Table Body
          ...users.map((user) => _buildUserRow(user)),
        ],
      ),
    );
  }

  Widget _buildHeaderCell(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontWeight: FontWeight.bold,
        color: Color(0xFF111813),
        fontSize: 14,
      ),
    );
  }

  Widget _buildUserRow(AdminUser user) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Color(0xFFF0F5F1)),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              user.email,
              style: const TextStyle(fontSize: 14),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            flex: 2,
            child: Row(
              children: [
                Text(
                  user.username,
                  style: const TextStyle(fontSize: 14),
                  overflow: TextOverflow.ellipsis,
                ),
                if (user.isSuperuser) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0BDA50).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'Admin',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0BDA50),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              user.fullName ?? '-',
              style: const TextStyle(fontSize: 14),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            flex: 1,
            child: _buildStatusBadge(user.isActive),
          ),
          Expanded(
            flex: 1,
            child: Text(
              DateFormat('dd/MM/yyyy').format(user.createdAt),
              style: const TextStyle(fontSize: 14, color: Color(0xFF608a6e)),
            ),
          ),
          SizedBox(
            width: 120,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: Icon(
                    user.isActive ? Icons.block : Icons.check_circle,
                    color: user.isActive
                        ? const Color(0xFFEF4444)
                        : const Color(0xFF0BDA50),
                    size: 20,
                  ),
                  onPressed: () => _showStatusDialog(user),
                  tooltip: user.isActive ? 'Vô hiệu hóa' : 'Kích hoạt',
                ),
                IconButton(
                  icon: const Icon(Icons.delete,
                      color: Color(0xFFEF4444), size: 20),
                  onPressed: () => _showDeleteDialog(user),
                  tooltip: 'Xóa',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileList(List<AdminUser> users) {
    return Column(
      children: users.map((user) => _buildMobileUserCard(user)).toList(),
    );
  }

  Widget _buildMobileUserCard(AdminUser user) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF0F5F1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.username,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user.email,
                      style: const TextStyle(
                        color: Color(0xFF608a6e),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              _buildStatusBadge(user.isActive),
            ],
          ),
          if (user.fullName != null) ...[
            const SizedBox(height: 8),
            Text(
              user.fullName!,
              style: const TextStyle(fontSize: 14),
            ),
          ],
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.calendar_today,
                  size: 14, color: Color(0xFF608a6e)),
              const SizedBox(width: 4),
              Text(
                DateFormat('dd/MM/yyyy').format(user.createdAt),
                style: const TextStyle(fontSize: 12, color: Color(0xFF608a6e)),
              ),
              if (user.isSuperuser) ...[
                const SizedBox(width: 12),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0BDA50).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'Admin',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0BDA50),
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: () => _showStatusDialog(user),
                icon: Icon(
                  user.isActive ? Icons.block : Icons.check_circle,
                  size: 18,
                ),
                label: Text(user.isActive ? 'Vô hiệu hóa' : 'Kích hoạt'),
                style: TextButton.styleFrom(
                  foregroundColor: user.isActive
                      ? const Color(0xFFEF4444)
                      : const Color(0xFF0BDA50),
                ),
              ),
              const SizedBox(width: 8),
              TextButton.icon(
                onPressed: () => _showDeleteDialog(user),
                icon: const Icon(Icons.delete, size: 18),
                label: const Text('Xóa'),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFFEF4444),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(bool isActive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isActive
            ? const Color(0xFF10B981).withValues(alpha: 0.1)
            : const Color(0xFFEF4444).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        isActive ? 'Hoạt động' : 'Không hoạt động',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: isActive ? const Color(0xFF10B981) : const Color(0xFFEF4444),
        ),
      ),
    );
  }

  Widget _buildPagination() {
    return Consumer<AdminViewModel>(
      builder: (context, viewModel, child) {
        if (viewModel.totalPages <= 1) {
          return const SizedBox.shrink();
        }

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFF0F5F1)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Trang ${viewModel.currentPage} / ${viewModel.totalPages} (${viewModel.total} người dùng)',
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF608a6e),
                ),
              ),
              Row(
                children: [
                  IconButton(
                    onPressed: viewModel.currentPage > 1
                        ? () => viewModel.previousPage()
                        : null,
                    icon: const Icon(Icons.chevron_left),
                    color: const Color(0xFF0BDA50),
                  ),
                  ...List.generate(
                    viewModel.totalPages > 5 ? 5 : viewModel.totalPages,
                    (index) {
                      int pageNumber;
                      if (viewModel.totalPages <= 5) {
                        pageNumber = index + 1;
                      } else if (viewModel.currentPage <= 3) {
                        pageNumber = index + 1;
                      } else if (viewModel.currentPage >=
                          viewModel.totalPages - 2) {
                        pageNumber = viewModel.totalPages - 4 + index;
                      } else {
                        pageNumber = viewModel.currentPage - 2 + index;
                      }

                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: InkWell(
                          onTap: () => viewModel.goToPage(pageNumber),
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: viewModel.currentPage == pageNumber
                                  ? const Color(0xFF0BDA50)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: viewModel.currentPage == pageNumber
                                    ? const Color(0xFF0BDA50)
                                    : const Color(0xFFF0F5F1),
                              ),
                            ),
                            child: Center(
                              child: Text(
                                pageNumber.toString(),
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: viewModel.currentPage == pageNumber
                                      ? const Color(0xFF111813)
                                      : const Color(0xFF608a6e),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  IconButton(
                    onPressed: viewModel.currentPage < viewModel.totalPages
                        ? () => viewModel.nextPage()
                        : null,
                    icon: const Icon(Icons.chevron_right),
                    color: const Color(0xFF0BDA50),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _showDeleteDialog(AdminUser user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text(
          'Bạn có chắc chắn muốn xóa người dùng "${user.username}"?\n\nHành động này không thể hoàn tác.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final success =
                  await context.read<AdminViewModel>().deleteUser(user.id);
              if (!context.mounted) return;
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success
                          ? 'Đã xóa người dùng thành công'
                          : 'Không thể xóa người dùng',
                    ),
                    backgroundColor: success
                        ? const Color(0xFF10B981)
                        : const Color(0xFFEF4444),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
            ),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }

  void _showStatusDialog(AdminUser user) {
    final newStatus = !user.isActive;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title:
            Text(newStatus ? 'Kích hoạt người dùng' : 'Vô hiệu hóa người dùng'),
        content: Text(
          newStatus
              ? 'Bạn có muốn kích hoạt người dùng "${user.username}"?'
              : 'Bạn có muốn vô hiệu hóa người dùng "${user.username}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final success =
                  await context.read<AdminViewModel>().updateUserStatus(
                        user.id,
                        newStatus,
                      );
              if (!context.mounted) return;
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success
                          ? 'Đã cập nhật trạng thái thành công'
                          : 'Không thể cập nhật trạng thái',
                    ),
                    backgroundColor: success
                        ? const Color(0xFF10B981)
                        : const Color(0xFFEF4444),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0BDA50),
              foregroundColor: const Color(0xFF111813),
            ),
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );
  }

  Widget _buildFarmsTab(bool isDesktop, bool isTablet) {
    return Consumer<AdminViewModel>(
      builder: (context, viewModel, child) {
        if (viewModel.isLoadingFarms && viewModel.farms.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (viewModel.farms.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.landscape, size: 64, color: Color(0xFF9ca3af)),
                const SizedBox(height: 16),
                const Text(
                  'Chưa có vùng trồng nào',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF4B5563),
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => viewModel.loadFarms(refresh: true),
                  child: const Text('Tải lại'),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => viewModel.loadFarms(refresh: true),
          child: ListView.builder(
            padding: EdgeInsets.all(isDesktop ? 32 : 16),
            itemCount:
                viewModel.farms.length + (viewModel.hasMoreFarms ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == viewModel.farms.length) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Center(
                    child: viewModel.isLoadingFarms
                        ? const CircularProgressIndicator()
                        : TextButton(
                            onPressed: () => viewModel.loadFarms(),
                            child: const Text('Tải thêm'),
                          ),
                  ),
                );
              }

              final farm = viewModel.farms[index];
              return _buildFarmCard(farm);
            },
          ),
        );
      },
    );
  }

  Widget _buildFarmCard(AdminFarmAreaResponseDTO farm) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF0F5F1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  farm.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Color(0xFF111813),
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF0BDA50).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  farm.cropType ?? 'Chưa xác định',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0BDA50),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (farm.description != null && farm.description!.isNotEmpty) ...[
            Text(
              farm.description!,
              style: const TextStyle(color: Color(0xFF4B5563)),
            ),
            const SizedBox(height: 12),
          ],
          const Divider(),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.person, size: 16, color: Color(0xFF608a6e)),
              const SizedBox(width: 8),
              const Text(
                'Chủ sở hữu: ',
                style: TextStyle(color: Color(0xFF608a6e)),
              ),
              Text(
                farm.userFullName ?? farm.username,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 8),
              Text(
                '(${farm.userEmail})',
                style: const TextStyle(color: Color(0xFF9ca3af), fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.straighten, size: 16, color: Color(0xFF608a6e)),
              const SizedBox(width: 8),
              const Text(
                'Diện tích: ',
                style: TextStyle(color: Color(0xFF608a6e)),
              ),
              Text(
                farm.areaSize != null ? '${farm.areaSize} m²' : 'Chưa xác định',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF0F5F1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Color(0xFF111813),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF608a6e),
            ),
          ),
        ],
      ),
    );
  }
}
