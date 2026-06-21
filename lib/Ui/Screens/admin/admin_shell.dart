import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../Providers/auth_provider.dart';
import '../../../Providers/notification_provider.dart';
import '../../Widgets/notification_badge.dart';
import '../notification_screen.dart';
import 'companies_panel.dart';
import 'stores_panel.dart';
import 'users_panel.dart';
import '../common/profile_screen.dart';
import '../common/change_password_screen.dart';

import 'package:flutter/services.dart';

class AdminShell extends StatefulWidget {
  const AdminShell({super.key});

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int _selectedIndex = 0;
  int _reloadToken = 0;

  void _refreshCurrent() {
    setState(() {
      _reloadToken++;
    });
  }

  Widget _buildBody(int index) {
    switch (index) {
      case 0:
        return CompaniesPanel(
          refreshToken: _reloadToken,
          onRefreshRequested: _refreshCurrent,
        );
      case 1:
        return StoresPanel(
          refreshToken: _reloadToken,
          onRefreshRequested: _refreshCurrent,
        );
      case 2:
        return UsersPanel(
          refreshToken: _reloadToken,
          onRefreshRequested: _refreshCurrent,
        );
      case 3:
        return const NotificationScreen();
      default:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthProvider>();
    final theme = Theme.of(context);
    final titles = ['Company Management', 'Store Management', 'Account Management', 'System Notifications'];

    return PopScope(
      canPop: false,
      onPopInvoked: (bool didPop) async {
        if (didPop) return;
        if (_selectedIndex != 0) {
          setState(() => _selectedIndex = 0);
        } else {
          final shouldExit = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Exit Application'),
              content: const Text('Are you sure you want to exit the application?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                  ),
                  child: const Text('Exit'),
                ),
              ],
            ),
          );
          if (shouldExit == true) {
            SystemNavigator.pop();
          }
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            titles[_selectedIndex],
            style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.2),
          ),
          elevation: 0,
          actions: [
            Consumer<NotificationProvider>(
              builder: (context, provider, child) {
                return NotificationBadge(
                  count: provider.unreadCount,
                  onTap: () => setState(() => _selectedIndex = 3),
                );
              },
            ),
            IconButton(
              onPressed: _refreshCurrent,
              icon: const Icon(Icons.refresh_rounded),
              tooltip: 'Reload list',
            ),
            const SizedBox(width: 8),
          ],
        ),
        drawer: Drawer(
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
              topRight: Radius.circular(24),
              bottomRight: Radius.circular(24),
            ),
          ),
          child: Column(
            children: [
              // Premium Sidebar Profile Header
              UserAccountsDrawerHeader(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [theme.colorScheme.primary, theme.colorScheme.secondary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                currentAccountPicture: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: CircleAvatar(
                    backgroundColor: Colors.indigo.shade800,
                    child: Text(
                      auth.user?.fullName.isNotEmpty == true ? auth.user!.fullName[0].toUpperCase() : 'A',
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                ),
                accountName: Text(
                  auth.user?.fullName ?? 'System Admin',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                accountEmail: const Text(
                  'Role: Super Administrator',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  children: [
                    _buildDrawerItem(
                      index: 0,
                      icon: Icons.business_rounded,
                      label: 'Company Management',
                    ),
                    _buildDrawerItem(
                      index: 1,
                      icon: Icons.storefront_rounded,
                      label: 'Store Management',
                    ),
                    _buildDrawerItem(
                      index: 2,
                      icon: Icons.people_outline_rounded,
                      label: 'Account Management',
                    ),
                    _buildDrawerItem(
                      index: 3,
                      icon: Icons.notifications_none_rounded,
                      label: 'System Notifications',
                    ),
                    const Divider(height: 32),
                    ListTile(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      leading: const Icon(Icons.person_outline_rounded),
                      title: const Text('Personal Information', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen()));
                      },
                    ),
                    ListTile(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      leading: const Icon(Icons.lock_outline_rounded),
                      title: const Text('Change Password', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const ChangePasswordScreen()));
                      },
                    ),
                    const Divider(height: 32),
                    ListTile(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      leading: const Icon(Icons.logout_rounded, color: Colors.redAccent),
                      title: const Text(
                        'Log out',
                        style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      onTap: () {
                        auth.logout();
                      },
                    )
                  ],
                ),
              ),
            ],
          ),
        ),
        body: Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface.withOpacity(0.95),
          ),
          child: _buildBody(_selectedIndex),
        ),
      ),
    );
  }

  Widget _buildDrawerItem({required int index, required IconData icon, required String label}) {
    final isSelected = _selectedIndex == index;
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        selected: isSelected,
        selectedTileColor: theme.colorScheme.primary.withOpacity(0.08),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        leading: Icon(
          icon,
          color: isSelected ? theme.colorScheme.primary : Colors.grey.shade600,
          size: 22,
        ),
        title: Text(
          label,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
            fontSize: 14,
            color: isSelected ? theme.colorScheme.primary : Colors.grey.shade800,
          ),
        ),
        onTap: () {
          setState(() => _selectedIndex = index);
          Navigator.pop(context);
        },
      ),
    );
  }
}
