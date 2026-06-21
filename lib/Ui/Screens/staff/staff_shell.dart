import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../Providers/auth_provider.dart';
import 'product_list_screen.dart';
import 'orders_management_screen.dart';
import 'po_list_screen.dart';
import 'inventory_screen.dart';
import 'user_management_screen.dart';
import 'financial_report_screen.dart';
import 'promotion_management_screen.dart';
import 'employee_pos_screen.dart';
import 'provider_management_screen.dart';
import '../notification_screen.dart';
import '../../Widgets/notification_badge.dart';
import '../../../Providers/notification_provider.dart';
import '../common/profile_screen.dart';
import '../common/change_password_screen.dart';

import 'package:flutter/services.dart';

class StaffShell extends StatefulWidget {
  const StaffShell({super.key});

  @override
  State<StaffShell> createState() => _StaffShellState();
}

class _StaffShellState extends State<StaffShell> {
  int _selectedIndex = 0;

  Widget _buildBody(int index) {
    switch (index) {
      case 0:
        return _StaffDashboardView(onNavigate: (newIndex) {
          setState(() => _selectedIndex = newIndex);
        });
      case 1:
        return const ProductListStaffScreen();
      case 2:
        return const OrdersManagementScreen();
      case 3:
        return const POListScreen();
      case 4:
        return const InventoryScreen();
      case 5:
        return const UserManagementScreen();
      case 6:
        return const FinancialReportScreen();
      case 7:
        return const PromotionManagementScreen();
      case 8:
        return const EmployeePosScreen();
      case 9:
        return const ProviderManagementScreen();
      case 10:
        return const NotificationScreen();
      default:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isManager = auth.isManager;
    final theme = Theme.of(context);

    final titles = [
      'System Overview',
      'Product List',
      'Order Management',
      'Purchase Orders (PO)',
      'Inventory Control',
      'Employee Management',
      'Financial Reports',
      'Promotions',
      'Cashier POS',
      'Suppliers',
      'Internal Notifications'
    ];

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
          actions: [
            Consumer<NotificationProvider>(
              builder: (context, provider, child) {
                return NotificationBadge(
                  count: provider.unreadCount,
                  onTap: () => setState(() => _selectedIndex = 10),
                );
              },
            ),
            const SizedBox(width: 16),
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
                    backgroundColor: Colors.teal.shade400,
                    child: Text(
                      auth.user?.fullName.isNotEmpty == true ? auth.user!.fullName[0].toUpperCase() : 'S',
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                ),
                accountName: Text(
                  auth.user?.fullName ?? 'Sapo Staff',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                accountEmail: Text(
                  isManager ? 'Permission: Store Manager' : 'Permission: Cashier/Staff',
                  style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 13),
                ),
              ),

              // Sidebar Navigation Scroll
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  children: [
                    _buildDrawerItem(0, Icons.dashboard_rounded, 'System Overview'),
                    _buildDrawerItem(10, Icons.notifications_rounded, 'Internal Notifications'),
                    const Divider(height: 16),
                    _buildDrawerItem(1, Icons.inventory_2_rounded, 'Product List'),
                    _buildDrawerItem(2, Icons.receipt_long_rounded, 'Order Management'),
                    _buildDrawerItem(3, Icons.local_shipping_rounded, 'Purchase Orders (PO)'),
                    _buildDrawerItem(4, Icons.warehouse_rounded, 'Inventory Control'),
                    _buildDrawerItem(9, Icons.storefront_rounded, 'Suppliers'),
                    if (auth.isStaff) ...[
                      _buildDrawerItem(8, Icons.point_of_sale_rounded, 'Cashier POS'),
                    ],
                    if (isManager) ...[
                      const Divider(height: 16),
                      _buildDrawerItem(7, Icons.local_offer_rounded, 'Promotions'),
                      _buildDrawerItem(5, Icons.people_rounded, 'Employee Management'),
                      _buildDrawerItem(6, Icons.bar_chart_rounded, 'Financial Reports'),
                    ],
                    const Divider(height: 16),
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
                    const Divider(height: 16),
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
        body: _buildBody(_selectedIndex),
      ),
    );
  }

  Widget _buildDrawerItem(int index, IconData icon, String label) {
    final isSelected = _selectedIndex == index;
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
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

class _StaffDashboardView extends StatelessWidget {
  final ValueChanged<int> onNavigate;
  const _StaffDashboardView({required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final auth = context.watch<AuthProvider>();
    final isManager = auth.isManager;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Welcome Premium Header
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hello, ${auth.user?.fullName ?? "Staff"} 👋',
                    style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Welcome back to the Sapo Management System.',
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Quick Stats Cards Grid
        Text(
          'TODAY\'S ACTIVITIES',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w900,
            color: Colors.grey[500],
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.4,
          children: [
            _buildStatCard(
              title: 'Products',
              subtitle: 'Product Inventory',
              color: Colors.blue.shade600,
              icon: Icons.inventory_2_rounded,
              onTap: () => onNavigate(1),
            ),
            _buildStatCard(
              title: 'Orders',
              subtitle: 'Retail & Online',
              color: Colors.teal.shade600,
              icon: Icons.receipt_long_rounded,
              onTap: () => onNavigate(2),
            ),
            _buildStatCard(
              title: 'Suppliers',
              subtitle: 'Supply Partners',
              color: Colors.orange.shade600,
              icon: Icons.storefront_rounded,
              onTap: () => onNavigate(9),
            ),
            _buildStatCard(
              title: 'Inventory',
              subtitle: 'Check stock levels',
              color: Colors.purple.shade600,
              icon: Icons.warehouse_rounded,
              onTap: () => onNavigate(4),
            ),
          ],
        ),
        const SizedBox(height: 28),

        // Quick Actions Panels
        Text(
          'FREQUENTLY USED FUNCTIONS',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w900,
            color: Colors.grey[500],
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 12),
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.grey.shade100),
          ),
          color: Colors.white,
          child: Column(
            children: [
              if (auth.isStaff)
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: Colors.indigo.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.point_of_sale_rounded, color: Colors.indigo, size: 20),
                  ),
                  title: const Text('Cashier POS Screen', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  subtitle: const Text('Create retail bills instantly at counter', style: TextStyle(fontSize: 12)),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => onNavigate(8),
                ),
              if (auth.isStaff && isManager) const Divider(height: 1, indent: 56),
              if (isManager) ...[
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: Colors.teal.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.bar_chart_rounded, color: Colors.teal, size: 20),
                  ),
                  title: const Text('Financial Reports', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  subtitle: const Text('View detailed sales and profits', style: TextStyle(fontSize: 12)),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => onNavigate(6),
                ),
                const Divider(height: 1, indent: 56),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.local_offer_rounded, color: Colors.orange, size: 20),
                  ),
                  title: const Text('Promotions', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  subtitle: const Text('Manage discount codes and vouchers', style: TextStyle(fontSize: 12)),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => onNavigate(7),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String subtitle,
    required Color color,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade100),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(color: Colors.grey.shade400, fontSize: 11, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
