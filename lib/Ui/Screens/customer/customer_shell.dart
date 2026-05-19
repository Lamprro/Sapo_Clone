import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../Providers/auth_provider.dart';
import '../common/profile_screen.dart';
import '../common/change_password_screen.dart';
import 'my_ratings_screen.dart';
import 'customer_home_screen.dart';
import 'cart_screen.dart';
import 'my_orders_screen.dart';
import '../notification_screen.dart';
import '../../Widgets/notification_badge.dart';
import '../../../Providers/notification_provider.dart';

class CustomerShell extends StatefulWidget {
  const CustomerShell({super.key});

  @override
  State<CustomerShell> createState() => _CustomerShellState();
}

class _CustomerShellState extends State<CustomerShell> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const CustomerHomeScreen(),
    const CartScreen(),
    const MyOrdersScreen(),
    const NotificationScreen(),
    const _CustomerProfileMenu(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sapo Clone'),
        actions: [
          Consumer<NotificationProvider>(
            builder: (context, provider, child) {
              return NotificationBadge(
                count: provider.unreadCount,
                onTap: () => setState(() => _currentIndex = 3),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.shopping_cart), label: 'Cart'),
          BottomNavigationBarItem(icon: Icon(Icons.receipt_long), label: 'Orders'),
          BottomNavigationBarItem(icon: Icon(Icons.notifications), label: 'Alerts'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}

class _CustomerProfileMenu extends StatelessWidget {
  const _CustomerProfileMenu();

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        CircleAvatar(
          radius: 40,
          child: Text(user?.fullName[0].toUpperCase() ?? 'U', style: const TextStyle(fontSize: 32)),
        ),
        const SizedBox(height: 16),
        Text(user?.fullName ?? 'User', textAlign: TextAlign.center, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        Text(user?.email ?? '', textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey)),
        const SizedBox(height: 32),
        ListTile(
          leading: const Icon(Icons.person),
          title: const Text('Edit Profile'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen())),
        ),
        ListTile(
          leading: const Icon(Icons.lock),
          title: const Text('Change Password'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ChangePasswordScreen())),
        ),
        ListTile(
          leading: const Icon(Icons.star_border),
          title: const Text('My Ratings'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MyRatingsScreen())),
        ),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.logout, color: Colors.red),
          title: const Text('Logout', style: TextStyle(color: Colors.red)),
          onTap: () => context.read<AuthProvider>().logout(),
        ),
      ],
    );
  }
}
