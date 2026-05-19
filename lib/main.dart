import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'Providers/auth_provider.dart';
import 'Providers/product_provider.dart';
import 'Providers/cart_provider.dart';
import 'Providers/order_provider.dart';
import 'Providers/rating_provider.dart';
import 'Providers/promotion_provider.dart';
import 'Providers/inventory_provider.dart';
import 'Providers/purchase_order_provider.dart';
import 'Providers/user_provider.dart';
import 'Providers/supplier_provider.dart';
import 'Providers/notification_provider.dart';
import 'Ui/Screens/login_screen.dart';
import 'Ui/Screens/customer/customer_shell.dart';
import 'Ui/Screens/staff/staff_shell.dart';
import 'Ui/Screens/admin/admin_shell.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ProductProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => OrderProvider()),
        ChangeNotifierProvider(create: (_) => RatingProvider()),
        ChangeNotifierProvider(create: (_) => PromotionProvider()),
        ChangeNotifierProvider(create: (_) => InventoryProvider()),
        ChangeNotifierProvider(create: (_) => PurchaseOrderProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => SupplierProvider()),
        ChangeNotifierProxyProvider<AuthProvider, NotificationProvider>(
          create: (context) => NotificationProvider(context.read<AuthProvider>()),
          update: (context, auth, previous) => previous ?? NotificationProvider(auth),
        ),
      ],
      child: MaterialApp(
        title: 'Sapo Clone',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF1976D2), // A professional blue
            brightness: Brightness.light,
          ),
          textTheme: const TextTheme(
            bodyLarge: TextStyle(fontSize: 16),
            bodyMedium: TextStyle(fontSize: 14),
          ),
        ),
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('vi', 'VN'),
          Locale('en', 'US'),
        ],
        locale: const Locale('vi', 'VN'),
        home: const RootNavigator(),
      ),
    );
  }
}

class RootNavigator extends StatelessWidget {
  const RootNavigator({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    
    if (auth.isAuthenticated) {
      if (auth.isAdmin) {
        return const AdminShell();
      } else if (auth.isStaff) {
        return const StaffShell();
      } else {
        return const CustomerShell();
      }
    }
    
    return const LoginScreen();
  }
}
