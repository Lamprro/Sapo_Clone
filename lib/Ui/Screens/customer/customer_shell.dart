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

import 'package:flutter/services.dart';

class CustomerShell extends StatefulWidget {
  const CustomerShell({super.key});

  @override
  State<CustomerShell> createState() => CustomerShellState();
}

class CustomerShellState extends State<CustomerShell> {
  int _currentIndex = 0;

  void setIndex(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  final List<Widget> _screens = [
    const CustomerHomeScreen(),
    const CartScreen(),
    const MyOrdersScreen(),
    const NotificationScreen(),
    const _CustomerProfileMenu(),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return PopScope(
      canPop: false,
      onPopInvoked: (bool didPop) async {
        if (didPop) return;
        if (_currentIndex != 0) {
          setState(() => _currentIndex = 0);
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
            'Sapo Retail',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              color: theme.colorScheme.primary,
              letterSpacing: -0.5,
            ),
          ),
          actions: [
            Consumer<NotificationProvider>(
              builder: (context, provider, child) {
                return NotificationBadge(
                  count: provider.unreadCount,
                  onTap: () => setState(() => _currentIndex = 3),
                );
              },
            ),
            const SizedBox(width: 16),
          ],
        ),
        body: _screens[_currentIndex],
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: Colors.grey.shade100, width: 1)),
          ),
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) => setState(() => _currentIndex = index),
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.white,
            selectedItemColor: theme.colorScheme.primary,
            unselectedItemColor: Colors.grey[400],
            selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
            unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 11),
            elevation: 0,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home_rounded),
                activeIcon: Icon(Icons.home_rounded),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.shopping_cart_rounded),
                activeIcon: Icon(Icons.shopping_cart_rounded),
                label: 'Cart',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.receipt_long_rounded),
                activeIcon: Icon(Icons.receipt_long_rounded),
                label: 'Orders',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.notifications_rounded),
                activeIcon: Icon(Icons.notifications_rounded),
                label: 'Notifications',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person_rounded),
                activeIcon: Icon(Icons.person_rounded),
                label: 'Profile',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CustomerProfileMenu extends StatelessWidget {
  const _CustomerProfileMenu();

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Premium Profile Card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                theme.colorScheme.primary,
                theme.colorScheme.primary.withAlpha(200),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.primary.withOpacity(0.2),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(3),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: CircleAvatar(
                  radius: 36,
                  backgroundColor: theme.colorScheme.secondary,
                  child: Text(
                    user?.fullName.isNotEmpty == true ? user!.fullName[0].toUpperCase() : 'U',
                    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user?.fullName ?? 'Customer',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user?.email ?? 'Email not updated',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withOpacity(0.85),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Role: Customer',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.white.withOpacity(0.7),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),

        // Grouped Settings Menu
        Text(
          'ACCOUNT & UTILITIES',
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
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: theme.colorScheme.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                  child: Icon(Icons.person_outline_rounded, color: theme.colorScheme.primary, size: 20),
                ),
                title: const Text('Personal Information', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                trailing: Icon(Icons.chevron_right_rounded, color: Colors.grey[400]),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen())),
              ),
              const Divider(height: 1, indent: 56),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: Colors.purple.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.lock_outline_rounded, color: Colors.purple, size: 20),
                ),
                title: const Text('Change Password', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                trailing: Icon(Icons.chevron_right_rounded, color: Colors.grey[400]),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ChangePasswordScreen())),
              ),
              const Divider(height: 1, indent: 56),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.star_outline_rounded, color: Colors.orange, size: 20),
                ),
                title: const Text('My Ratings', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                trailing: Icon(Icons.chevron_right_rounded, color: Colors.grey[400]),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MyRatingsScreen())),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.grey.shade100),
          ),
          color: Colors.white,
          child: ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.logout_rounded, color: Colors.redAccent, size: 20),
            ),
            title: const Text('Log out', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.redAccent, fontSize: 14)),
            trailing: Icon(Icons.chevron_right_rounded, color: Colors.redAccent.withOpacity(0.4)),
            onTap: () => context.read<AuthProvider>().logout(),
          ),
        ),
      ],
    );
  }
}
