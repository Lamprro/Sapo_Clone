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
        return const _StaffDashboardView();
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Staff Dashboard'),
        actions: [
          Consumer<NotificationProvider>(
            builder: (context, provider, child) {
              return NotificationBadge(
                count: provider.unreadCount,
                onTap: () => setState(() => _selectedIndex = 10),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: Theme.of(context).primaryColor),
              child: const Text('Staff Menu', style: TextStyle(color: Colors.white, fontSize: 24)),
            ),
            ListTile(
              leading: const Icon(Icons.dashboard),
              title: const Text('Dashboard'),
              onTap: () { setState(() => _selectedIndex = 0); Navigator.pop(context); },
            ),
            ListTile(
              leading: const Icon(Icons.notifications),
              title: const Text('Notifications'),
              onTap: () { setState(() => _selectedIndex = 10); Navigator.pop(context); },
            ),
            ListTile(
              leading: const Icon(Icons.inventory),
              title: const Text('Products'),
              onTap: () { setState(() => _selectedIndex = 1); Navigator.pop(context); },
            ),
            ListTile(
              leading: const Icon(Icons.receipt),
              title: const Text('Orders'),
              onTap: () { setState(() => _selectedIndex = 2); Navigator.pop(context); },
            ),
            ListTile(
              leading: const Icon(Icons.local_shipping),
              title: const Text('Purchase Orders'),
              onTap: () { setState(() => _selectedIndex = 3); Navigator.pop(context); },
            ),
            ListTile(
              leading: const Icon(Icons.warehouse),
              title: const Text('Inventory'),
              onTap: () { setState(() => _selectedIndex = 4); Navigator.pop(context); },
            ),
            ListTile(
              leading: const Icon(Icons.business),
              title: const Text('Suppliers'),
              onTap: () { setState(() => _selectedIndex = 9); Navigator.pop(context); },
            ),
            if (auth.isStaff) ...[
              ListTile(
                leading: const Icon(Icons.point_of_sale),
                title: const Text('Cashier'),
                onTap: () { setState(() => _selectedIndex = 8); Navigator.pop(context); },
              ),
            ],
            if (isManager) ...[
              const Divider(),
              ListTile(
                leading: const Icon(Icons.local_offer),
                title: const Text('Promotions'),
                onTap: () { setState(() => _selectedIndex = 7); Navigator.pop(context); },
              ),
              ListTile(
                leading: const Icon(Icons.people),
                title: const Text('User Management'),
                onTap: () { setState(() => _selectedIndex = 5); Navigator.pop(context); },
              ),
              ListTile(
                leading: const Icon(Icons.bar_chart),
                title: const Text('Reports'),
                onTap: () { setState(() => _selectedIndex = 6); Navigator.pop(context); },
              ),
            ],
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              onTap: () { auth.logout(); },
            )
          ],
        ),
      ),
      body: _buildBody(_selectedIndex),
    );
  }
}

class _StaffDashboardView extends StatelessWidget {
  const _StaffDashboardView();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Staff Dashboard',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          'Use the drawer to switch between operational modules.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[700]),
        ),
        const SizedBox(height: 16),
        const _ModulePlaceholder(
          icon: Icons.dashboard_outlined,
          title: 'Operations Overview',
          subtitle: 'KPIs and quick actions can be placed here once backend widgets are ready.',
        ),
      ],
    );
  }
}

class _ModulePlaceholder extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _ModulePlaceholder({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 48, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[700]),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
