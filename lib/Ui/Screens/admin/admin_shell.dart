import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/auth.dart';
import '../../../models/company.dart';
import '../../../models/page_response.dart';
import '../../../models/store.dart';
import '../../../Providers/auth_provider.dart';
import '../../../services/company_service.dart';
import '../../../services/store_service.dart';
import '../../../services/user_service.dart';
import '../notification_screen.dart';
import '../../Widgets/notification_badge.dart';
import '../../../Providers/notification_provider.dart';

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
    final titles = ['Companies', 'Stores', 'Users', 'Notifications'];

    return Scaffold(
      appBar: AppBar(
        title: Text('Admin Dashboard - ${titles[_selectedIndex]}'),
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
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.redAccent),
              child: Text('Admin Menu', style: TextStyle(color: Colors.white, fontSize: 24)),
            ),
            ListTile(
              leading: const Icon(Icons.business),
              title: const Text('Companies'),
              onTap: () { setState(() => _selectedIndex = 0); Navigator.pop(context); },
            ),
            ListTile(
              leading: const Icon(Icons.notifications),
              title: const Text('Notifications'),
              onTap: () { setState(() => _selectedIndex = 3); Navigator.pop(context); },
            ),
            ListTile(
              leading: const Icon(Icons.store),
              title: const Text('Stores'),
              onTap: () { setState(() => _selectedIndex = 1); Navigator.pop(context); },
            ),
            ListTile(
              leading: const Icon(Icons.people),
              title: const Text('Users'),
              onTap: () { setState(() => _selectedIndex = 2); Navigator.pop(context); },
            ),
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

class CompaniesPanel extends StatefulWidget {
  final int refreshToken;
  final VoidCallback onRefreshRequested;

  const CompaniesPanel({super.key, required this.refreshToken, required this.onRefreshRequested});

  @override
  State<CompaniesPanel> createState() => _CompaniesPanelState();
}

class _CompaniesPanelState extends State<CompaniesPanel> {
  final CompanyService _service = CompanyService();
  Future<PageResponse<CompanyResponse>>? _future;

  @override
  void initState() {
    super.initState();
    _future = _service.getList();
  }

  @override
  void didUpdateWidget(covariant CompaniesPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshToken != widget.refreshToken) {
      _future = _service.getList();
    }
  }

  Future<void> _createOrEdit({CompanyResponse? company}) async {
    final nameController = TextEditingController(text: company?.companyName ?? '');
    final addressController = TextEditingController(text: company?.companyAddress ?? '');

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(company == null ? 'Create company' : 'Edit company'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Company name')),
            TextField(controller: addressController, decoration: const InputDecoration(labelText: 'Company address')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.trim().isEmpty) return;
              if (company == null) {
                await _service.createCompany(
                  companyName: nameController.text.trim(),
                  companyAddress: addressController.text.trim().isEmpty ? null : addressController.text.trim(),
                );
              } else {
                await _service.updateCompany(
                  id: company.id,
                  companyName: nameController.text.trim(),
                  companyAddress: addressController.text.trim().isEmpty ? null : addressController.text.trim(),
                );
              }
              if (!mounted) return;
              Navigator.pop(dialogContext);
              setState(() => _future = _service.getList());
              widget.onRefreshRequested();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: FutureBuilder<PageResponse<CompanyResponse>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const CircularProgressIndicator();
          }

          final companies = snapshot.data?.content ?? [];
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton.icon(
                    onPressed: () => _createOrEdit(),
                    icon: const Icon(Icons.add),
                    label: const Text('New company'),
                  ),
                ),
              ),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async {
                    setState(() => _future = _service.getList());
                    widget.onRefreshRequested();
                  },
                  child: ListView.builder(
                    itemCount: companies.length,
                    itemBuilder: (context, index) {
                      final company = companies[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: ListTile(
                          title: Text(company.companyName),
                          subtitle: Text(company.companyAddress ?? '-'),
                          trailing: IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () => _createOrEdit(company: company),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

}

class StoresPanel extends StatefulWidget {
  final int refreshToken;
  final VoidCallback onRefreshRequested;

  const StoresPanel({super.key, required this.refreshToken, required this.onRefreshRequested});

  @override
  State<StoresPanel> createState() => _StoresPanelState();
}

class _StoresPanelState extends State<StoresPanel> {
  final StoreService _service = StoreService();
  Future<PageResponse<StoreResponse>>? _future;

  @override
  void initState() {
    super.initState();
    _future = _service.getList();
  }

  @override
  void didUpdateWidget(covariant StoresPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshToken != widget.refreshToken) {
      _future = _service.getList();
    }
  }

  Future<void> _createOrEdit({StoreResponse? store}) async {
    final nameController = TextEditingController(text: store?.storeName ?? '');
    final addressController = TextEditingController(text: store?.storeAddress ?? '');

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(store == null ? 'Create store' : 'Edit store'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Store name')),
            TextField(controller: addressController, decoration: const InputDecoration(labelText: 'Store address')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.trim().isEmpty || addressController.text.trim().isEmpty) return;
              if (store == null) {
                await _service.createStore(
                  storeName: nameController.text.trim(),
                  storeAddress: addressController.text.trim(),
                );
              } else {
                await _service.updateStore(
                  id: store.id,
                  storeName: nameController.text.trim(),
                  storeAddress: addressController.text.trim(),
                );
              }
              if (!mounted) return;
              Navigator.pop(dialogContext);
              setState(() => _future = _service.getList());
              widget.onRefreshRequested();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<PageResponse<StoreResponse>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final stores = snapshot.data?.content ?? [];
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton.icon(
                  onPressed: () => _createOrEdit(),
                  icon: const Icon(Icons.add),
                  label: const Text('New store'),
                ),
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  setState(() => _future = _service.getList());
                  widget.onRefreshRequested();
                },
                child: ListView.builder(
                  itemCount: stores.length,
                  itemBuilder: (context, index) {
                    final store = stores[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: ListTile(
                        title: Text(store.storeName),
                        subtitle: Text(store.storeAddress),
                        trailing: IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () => _createOrEdit(store: store),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class UsersPanel extends StatefulWidget {
  final int refreshToken;
  final VoidCallback onRefreshRequested;

  const UsersPanel({super.key, required this.refreshToken, required this.onRefreshRequested});

  @override
  State<UsersPanel> createState() => _UsersPanelState();
}

class _UsersPanelState extends State<UsersPanel> {
  final UserService _service = UserService();
  Future<PageResponse<UserResponse>>? _future;

  @override
  void initState() {
    super.initState();
    _future = _service.getList();
  }

  @override
  void didUpdateWidget(covariant UsersPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshToken != widget.refreshToken) {
      _future = _service.getList();
    }
  }

  Future<void> _createUser() async {
    final fullNameController = TextEditingController();
    final phoneController = TextEditingController();
    final emailController = TextEditingController();
    final usernameController = TextEditingController();
    final passwordController = TextEditingController();
    final companyIdController = TextEditingController();
    final addressController = TextEditingController();
    final roleIdController = TextEditingController();
    final storeIdController = TextEditingController();

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Create user'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: fullNameController, decoration: const InputDecoration(labelText: 'Full name')),
              TextField(controller: phoneController, decoration: const InputDecoration(labelText: 'Phone')),
              TextField(controller: emailController, decoration: const InputDecoration(labelText: 'Email')),
              TextField(controller: usernameController, decoration: const InputDecoration(labelText: 'Username')),
              TextField(controller: passwordController, decoration: const InputDecoration(labelText: 'Password')),
              TextField(controller: companyIdController, decoration: const InputDecoration(labelText: 'Company ID'), keyboardType: TextInputType.number),
              TextField(controller: addressController, decoration: const InputDecoration(labelText: 'Address')),
              TextField(controller: roleIdController, decoration: const InputDecoration(labelText: 'Role ID'), keyboardType: TextInputType.number),
              TextField(controller: storeIdController, decoration: const InputDecoration(labelText: 'Store ID (optional)'), keyboardType: TextInputType.number),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              await _service.createUser(
                fullName: fullNameController.text.trim(),
                phone: phoneController.text.trim(),
                email: emailController.text.trim(),
                username: usernameController.text.trim(),
                password: passwordController.text.trim(),
                repeatPassword: passwordController.text.trim(),
                companyId: int.tryParse(companyIdController.text.trim()) ?? 0,
                address: addressController.text.trim(),
                roleId: int.tryParse(roleIdController.text.trim()) ?? 0,
                storeId: int.tryParse(storeIdController.text.trim()) ?? 0,
              );
              if (!mounted) return;
              Navigator.pop(dialogContext);
              setState(() => _future = _service.getList());
              widget.onRefreshRequested();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleStatus(UserResponse user) async {
    await _service.updateStatus(user.id, user.status == 1 ? 0 : 1);
    if (!mounted) return;
    setState(() => _future = _service.getList());
    widget.onRefreshRequested();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<PageResponse<UserResponse>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final users = snapshot.data?.content ?? [];
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton.icon(
                  onPressed: _createUser,
                  icon: const Icon(Icons.add),
                  label: const Text('New user'),
                ),
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  setState(() => _future = _service.getList());
                  widget.onRefreshRequested();
                },
                child: ListView.builder(
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    final user = users[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: ListTile(
                        title: Text(user.fullName),
                        subtitle: Text('${user.roleName ?? '-'} • ${user.username ?? '-'}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(user.status == 1 ? 'Active' : 'Inactive'),
                            IconButton(
                              icon: const Icon(Icons.swap_horiz),
                              onPressed: () => _toggleStatus(user),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
