import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../Providers/auth_provider.dart';
import '../../../Providers/notification_provider.dart';
import '../../Widgets/notification_badge.dart';
import '../notification_screen.dart';
import 'companies_panel.dart';
import 'stores_panel.dart';
import 'users_panel.dart';

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
    final titles = ['Companies', 'Stores', 'Users', 'Notifications'];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          titles[_selectedIndex],
          style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5),
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
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh list',
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
            DrawerHeader(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [theme.colorScheme.primary, theme.colorScheme.primary.withOpacity(0.8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: const Align(
                alignment: Alignment.bottomLeft,
                child: Padding(
                  padding: EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Icon(Icons.admin_panel_settings, size: 36, color: Colors.white),
                      SizedBox(width: 12),
                      Text(
                        'Admin Portal',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                children: [
                  _buildDrawerItem(
                    index: 0,
                    icon: Icons.business,
                    label: 'Companies',
                  ),
                  _buildDrawerItem(
                    index: 1,
                    icon: Icons.storefront,
                    label: 'Stores',
                  ),
                  _buildDrawerItem(
                    index: 2,
                    icon: Icons.people_outline,
                    label: 'Users',
                  ),
                  _buildDrawerItem(
                    index: 3,
                    icon: Icons.notifications_none,
                    label: 'Notifications',
                  ),
                  const Divider(height: 32),
                  ListTile(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    leading: const Icon(Icons.logout, color: Colors.redAccent),
                    title: const Text(
                      'Logout',
                      style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
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
    );
  }

  Widget _buildDrawerItem({required int index, required IconData icon, required String label}) {
    final isSelected = _selectedIndex == index;
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        selected: isSelected,
        selectedTileColor: theme.colorScheme.primary.withOpacity(0.1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        leading: Icon(
          icon,
          color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurface.withOpacity(0.65),
        ),
        title: Text(
          label,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurface,
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
