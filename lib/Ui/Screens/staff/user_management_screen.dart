import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../Providers/auth_provider.dart';
import '../../../Providers/user_provider.dart';
import '../../../models/auth.dart';
import '../../../models/store.dart';
import '../../../services/store_service.dart';
import '../../../utils/error_handler.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  String _searchKeyword = '';
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<UserProvider>().fetchUsers();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Management'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<UserProvider>().fetchUsers(keyword: _searchKeyword),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateUserDialog(context, context.read<UserProvider>()),
        label: const Text('Add User'),
        icon: const Icon(Icons.person_add_alt_1),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Consumer<UserProvider>(
        builder: (context, provider, _) {
          final currentCompanyId = context.read<AuthProvider>().user?.companyId;
          final visibleUsers = currentCompanyId == null
              ? <UserResponse>[]
              : provider.users.where((user) => user.companyId == currentCompanyId).toList();

          return Column(
            children: [
              // Search Header (Blue)
              Container(
                padding: const EdgeInsets.all(16),
                color: Colors.blue,
                child: TextField(
                  onChanged: (value) {
                    setState(() => _searchKeyword = value);
                    context.read<UserProvider>().fetchUsers(keyword: value);
                  },
                  decoration: InputDecoration(
                    hintText: 'Search by name, username or email...',
                    prefixIcon: const Icon(Icons.search, color: Colors.blue),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                  ),
                ),
              ),
              
              if (provider.isLoading && provider.users.isEmpty)
                const Expanded(child: Center(child: CircularProgressIndicator())),
              
              if (provider.errorMessage != null && provider.users.isEmpty)
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
                        const SizedBox(height: 16),
                        Text('Error: ${provider.errorMessage}'),
                        TextButton(
                          onPressed: () => provider.fetchUsers(),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                ),

              if (visibleUsers.isEmpty && !provider.isLoading)
                const Expanded(
                  child: Center(
                    child: Text('No users found'),
                  ),
                ),

              if (visibleUsers.isNotEmpty)
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    itemCount: visibleUsers.length,
                    itemBuilder: (context, index) {
                      final user = visibleUsers[index];
                      return UserCard(
                        user: user,
                        onStatusChange: () => _changeUserStatus(context, provider, user),
                        onEdit: () => _showUserDetailSheet(context, provider, user),
                      );
                    },
                  ),
                ),
              
              // Pagination
              if (provider.totalPages > 1)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border(top: BorderSide(color: Colors.grey[200]!)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        onPressed: provider.currentPage > 0 ? () => provider.previousPage() : null,
                        icon: const Icon(Icons.chevron_left),
                      ),
                      Text('Page ${provider.currentPage + 1} of ${provider.totalPages}', style: const TextStyle(fontWeight: FontWeight.bold)),
                      IconButton(
                        onPressed: provider.currentPage < provider.totalPages - 1 ? () => provider.nextPage() : null,
                        icon: const Icon(Icons.chevron_right),
                      ),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  void _showCreateUserDialog(BuildContext context, UserProvider provider) {
    final auth = context.read<AuthProvider>();
    final currentRole = auth.user?.roleName ?? 'MANAGER';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => UserFormSheet(
        currentRole: currentRole,
        currentUser: auth.user,
        onSave: (
          fullName,
          phone,
          email,
          username,
          password,
          repeatPassword,
          roleId,
          storeId,
          address,
        ) async {
          final auth = context.read<AuthProvider>();
          final sheetNavigator = Navigator.of(context);
          final success = await provider.createUser(
            fullName: fullName,
            phone: phone,
            email: email,
            username: username,
            password: password,
            repeatPassword: repeatPassword,
            companyId: auth.user?.companyId ?? 0,
            address: address,
            roleId: roleId,
            storeId: storeId,
          );

          if (success && mounted) {
            sheetNavigator.pop();
            ErrorHandler.showSuccess(context, 'User account created successfully!');
            provider.fetchUsers();
          } else if (mounted) {
            ErrorHandler.showError(context, provider.errorMessage ?? 'Could not create user');
          }
        },
      ),
    );
  }

  void _showUserDetailSheet(
    BuildContext context,
    UserProvider provider,
    UserResponse user,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.blue[50],
                  child: Text(
                    user.fullName[0].toUpperCase(),
                    style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 24),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.fullName,
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '@${user.username}',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                _buildStatusBadge(user.status != 0),
              ],
            ),
            const Divider(height: 40),
            _buildDetailItem(Icons.badge_outlined, 'Role', _getRoleNameFromName(user.roleName)),
            _buildDetailItem(Icons.email_outlined, 'Email', user.email ?? 'N/A'),
            _buildDetailItem(Icons.phone_android_outlined, 'Phone', user.phone ?? 'N/A'),
            _buildDetailItem(Icons.storefront_outlined, 'Store ID', user.storeId?.toString() ?? 'Main Office'),
            _buildDetailItem(Icons.location_on_outlined, 'Address', user.address ?? 'N/A'),
            if (user.pointValue != null)
              _buildDetailItem(Icons.stars_outlined, 'Points', user.pointValue.toString()),
            const Divider(height: 40),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[100],
                  foregroundColor: Colors.black87,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Close'),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(bool isActive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isActive ? Colors.green[50] : Colors.red[50],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        isActive ? 'Active' : 'Blocked',
        style: TextStyle(color: isActive ? Colors.green : Colors.red, fontWeight: FontWeight.bold, fontSize: 12),
      ),
    );
  }

  Widget _buildDetailItem(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 20, color: Colors.blue),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(color: Colors.grey[500], fontSize: 12)),
              Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
            ],
          ),
        ],
      ),
    );
  }

  void _changeUserStatus(
    BuildContext context,
    UserProvider provider,
    UserResponse user,
  ) {
    final newStatus = user.status == 0 ? 1 : 0;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change User Status'),
        content: Text(
          'Change status to ${newStatus == 0 ? 'Inactive' : 'Active'}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final dialogNavigator = Navigator.of(context);
              final messenger = ScaffoldMessenger.of(context);
              final success = await provider.updateUserStatus(user.id, newStatus);
              if (success && mounted) {
                dialogNavigator.pop();
                ErrorHandler.showSuccess(context, 'User status updated successfully!');
              } else if (mounted) {
                ErrorHandler.showError(context, provider.errorMessage ?? 'Could not update user status');
              }
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  String _getRoleNameFromName(String? roleName) {
    switch (roleName?.toUpperCase()) {
      case 'ADMIN':
        return 'Admin';
      case 'MANAGER':
        return 'Manager';
      case 'EMPLOYEE':
        return 'Employee';
      case 'CUSTOMER':
        return 'Customer';
      default:
        return roleName ?? 'Unknown';
    }
  }
}

class UserCard extends StatelessWidget {
  final UserResponse user;
  final VoidCallback onStatusChange;
  final VoidCallback onEdit;

  const UserCard({
    super.key,
    required this.user,
    required this.onStatusChange,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final roleName = _getRoleNameFromName(user.roleName);
    final isActive = user.status != 0;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: InkWell(
        onTap: onEdit,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.blue[50],
                    child: Text(
                      user.fullName.isNotEmpty ? user.fullName[0].toUpperCase() : 'U',
                      style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.fullName,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        Text(
                          '@${user.username}',
                          style: TextStyle(color: Colors.grey[600], fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  _buildRoleChip(roleName),
                ],
              ),
              const Divider(height: 24),
              Row(
                children: [
                  Icon(Icons.email_outlined, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Text(user.email ?? 'No email', style: TextStyle(color: Colors.grey[700], fontSize: 14)),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        isActive ? Icons.check_circle : Icons.block,
                        size: 16,
                        color: isActive ? Colors.green : Colors.red,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        isActive ? 'Active' : 'Blocked',
                        style: TextStyle(
                          color: isActive ? Colors.green : Colors.red,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  OutlinedButton.icon(
                    onPressed: onStatusChange,
                    icon: Icon(isActive ? Icons.block : Icons.check_circle, size: 16),
                    label: Text(isActive ? 'Block' : 'Unblock'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: isActive ? Colors.red : Colors.green,
                      side: BorderSide(color: isActive ? Colors.red : Colors.green),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoleChip(String role) {
    Color color;
    switch (role.toUpperCase()) {
      case 'ADMIN':
        color = Colors.purple;
        break;
      case 'MANAGER':
        color = Colors.orange;
        break;
      default:
        color = Colors.blue;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        role,
        style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 10),
      ),
    );
  }

  String _getRoleNameFromName(String? roleName) {
    switch (roleName?.toUpperCase()) {
      case 'ADMIN':
        return 'Admin';
      case 'MANAGER':
        return 'Manager';
      case 'EMPLOYEE':
        return 'Employee';
      case 'CUSTOMER':
        return 'Customer';
      default:
        return roleName ?? 'Unknown';
    }
  }
}

class UserFormSheet extends StatefulWidget {
  final String currentRole;
  final UserResponse? currentUser;
  final Function(
    String fullName,
    String phone,
    String email,
    String username,
    String password,
    String repeatPassword,
    int roleId,
    int storeId,
    String address,
  ) onSave;

  const UserFormSheet({
    super.key,
    required this.currentRole,
    required this.currentUser,
    required this.onSave,
  });

  @override
  State<UserFormSheet> createState() => _UserFormSheetState();
}

class _UserFormSheetState extends State<UserFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _fullNameController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _usernameController;
  late TextEditingController _passwordController;
  late TextEditingController _repeatPasswordController;
  late TextEditingController _addressController;
  int _selectedRole = 3; // Default: Employee
  int? _selectedStoreId;
  final StoreService _storeService = StoreService();
  List<StoreResponse> _stores = [];
  bool _isLoadingStores = false;
  String? _storeError;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _fullNameController = TextEditingController();
    _phoneController = TextEditingController();
    _emailController = TextEditingController();
    _usernameController = TextEditingController();
    _passwordController = TextEditingController();
    _repeatPasswordController = TextEditingController();
    _addressController = TextEditingController();

    // Default select based on role
    if (widget.currentRole == 'ADMIN') {
      _selectedRole = 2; // Manager
    } else if (widget.currentRole == 'MANAGER') {
      _selectedRole = 3; // Employee
    } else {
      _selectedRole = 4; // Customer
    }

    final lockedStoreId = widget.currentUser?.storeId;
    if (lockedStoreId != null && lockedStoreId > 0) {
      _selectedStoreId = lockedStoreId;
    }
    _loadStores();
  }

  bool get _requiresStore => _selectedRole == 3;

  bool get _isStoreLocked {
    final storeId = widget.currentUser?.storeId;
    return _requiresStore && storeId != null && storeId > 0;
  }

  Future<void> _loadStores() async {
    setState(() {
      _isLoadingStores = true;
      _storeError = null;
    });
    try {
      final stores = await _storeService.getAllStores();
      if (!mounted) return;
      setState(() {
        _stores = stores;
        _isLoadingStores = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _storeError = ErrorHandler.getErrorMessage(e);
        _isLoadingStores = false;
      });
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _repeatPasswordController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, size: 20),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    );
  }

  List<DropdownMenuItem<int>> _getRoleItems() {
    final items = <DropdownMenuItem<int>>[];
    if (widget.currentRole == 'ADMIN') {
      items.add(const DropdownMenuItem(value: 2, child: Text('Manager')));
      items.add(const DropdownMenuItem(value: 3, child: Text('Employee')));
      items.add(const DropdownMenuItem(value: 4, child: Text('Customer')));
    } else if (widget.currentRole == 'MANAGER') {
      items.add(const DropdownMenuItem(value: 3, child: Text('Employee')));
      items.add(const DropdownMenuItem(value: 4, child: Text('Customer')));
    } else {
      items.add(const DropdownMenuItem(value: 4, child: Text('Customer')));
    }
    return items;
  }

  String _storeName(int? storeId) {
    if (storeId == null || storeId <= 0) return 'No store selected';
    for (final store in _stores) {
      if (store.id == storeId) return store.storeName;
    }
    return 'Store #$storeId';
  }

  Widget _buildStoreSelector() {
    final dropdownValue =
        _selectedStoreId != null && _stores.any((store) => store.id == _selectedStoreId)
            ? _selectedStoreId
            : null;

    if (_isStoreLocked) {
      return InputDecorator(
        decoration: _inputDecoration('Assigned Store', Icons.storefront_outlined).copyWith(
          enabled: false,
          helperText: 'Locked to manager store',
        ),
        child: Text(
          _storeName(_selectedStoreId),
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
      );
    }

    if (_isLoadingStores) {
      return InputDecorator(
        decoration: _inputDecoration('Assigned Store', Icons.storefront_outlined),
        child: const Row(
          children: [
            SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
            SizedBox(width: 12),
            Text('Loading stores...'),
          ],
        ),
      );
    }

    return DropdownButtonFormField<int>(
      value: dropdownValue,
      isExpanded: true,
      decoration: _inputDecoration('Assigned Store', Icons.storefront_outlined).copyWith(
        helperText: _storeError ?? 'Required for employee accounts',
        errorMaxLines: 2,
      ),
      items: _stores.map((store) {
        return DropdownMenuItem<int>(
          value: store.id,
          child: Text(store.storeName, overflow: TextOverflow.ellipsis),
        );
      }).toList(),
      onChanged: (value) => setState(() => _selectedStoreId = value),
      validator: (_) {
        if (!_requiresStore) return null;
        if (_stores.isEmpty) return 'No stores available for this company';
        if (_selectedStoreId == null || _selectedStoreId == 0) {
          return 'Store is required';
        }
        return null;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 24,
        right: 24,
        top: 12,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Create New User',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _fullNameController,
                decoration: _inputDecoration('Full Name', Icons.person_outline),
                validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                decoration: _inputDecoration('Phone Number', Icons.phone_android_outlined),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value?.isEmpty ?? true) return 'Required';
                  if (!RegExp(r'^(0[35789][0-9]{8})$').hasMatch(value!)) {
                    return 'Invalid phone number format (03/05/07/08/09)';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                decoration: _inputDecoration('Email Address', Icons.email_outlined),
                keyboardType: TextInputType.emailAddress,
                validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _addressController,
                decoration: _inputDecoration('Address', Icons.location_on_outlined),
                validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _usernameController,
                decoration: _inputDecoration('Username', Icons.alternate_email),
                validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                decoration: _inputDecoration('Password', Icons.lock_outline).copyWith(
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
                obscureText: _obscurePassword,
                validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _repeatPasswordController,
                decoration: _inputDecoration('Confirm Password', Icons.lock_reset),
                obscureText: _obscurePassword,
                validator: (value) {
                  if (value?.isEmpty ?? true) return 'Required';
                  if (value != _passwordController.text) return 'Passwords do not match';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                value: _selectedRole,
                decoration: _inputDecoration('User Role', Icons.badge_outlined),
                items: _getRoleItems(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedRole = value;
                      final lockedStoreId = widget.currentUser?.storeId;
                      if (_requiresStore && lockedStoreId != null && lockedStoreId > 0) {
                        _selectedStoreId = lockedStoreId;
                      } else if (!_requiresStore) {
                        _selectedStoreId = null;
                      }
                    });
                  }
                },
              ),
              if (_requiresStore) ...[
                const SizedBox(height: 16),
                _buildStoreSelector(),
              ],
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState?.validate() ?? false) {
                    widget.onSave(
                      _fullNameController.text,
                      _phoneController.text,
                      _emailController.text,
                      _usernameController.text,
                      _passwordController.text,
                      _repeatPasswordController.text,
                      _selectedRole,
                      _requiresStore ? (_selectedStoreId ?? 0) : 0,
                      _addressController.text,
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: const Text('CREATE USER', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
