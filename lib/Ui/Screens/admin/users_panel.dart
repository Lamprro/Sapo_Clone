import 'package:flutter/material.dart';
import '../../../models/auth.dart';
import '../../../models/company.dart';
import '../../../models/page_response.dart';
import '../../../models/store.dart';
import '../../../services/company_service.dart';
import '../../../services/store_service.dart';
import '../../../services/user_service.dart';
import '../../Widgets/custom_text_field.dart';
import '../../Widgets/custom_button.dart';
import '../../../utils/error_handler.dart';

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

  List<CompanyResponse> _companies = [];
  List<StoreResponse> _stores = [];
  bool _isLoadingDropdownData = false;

  @override
  void initState() {
    super.initState();
    _future = _service.getList();
    _loadDropdownData();
  }

  @override
  void didUpdateWidget(covariant UsersPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshToken != widget.refreshToken) {
      _future = _service.getList();
    }
  }

  Future<void> _loadDropdownData() async {
    if (!mounted) return;
    setState(() => _isLoadingDropdownData = true);
    try {
      final companiesPage = await CompanyService().getList(size: 100);
      final storesList = await StoreService().getAllStores();
      if (!mounted) return;
      setState(() {
        _companies = companiesPage.content;
        _stores = storesList;
      });
    } catch (e) {
      debugPrint("Error loading admin lists: $e");
    } finally {
      if (mounted) {
        setState(() => _isLoadingDropdownData = false);
      }
    }
  }

  String _getCompanyName(int? companyId) {
    if (companyId == null) return 'N/A';
    final found = _companies.firstWhere((c) => c.id == companyId, orElse: () => CompanyResponse(id: 0, companyName: ''));
    return found.companyName.isNotEmpty ? found.companyName : 'Company #$companyId';
  }

  String _getStoreName(int? storeId) {
    if (storeId == null || storeId == 0) return 'Global Store / None';
    final found = _stores.firstWhere((s) => s.id == storeId, orElse: () => StoreResponse(id: 0, storeName: '', companyId: 0, storeAddress: ''));
    return found.storeName.isNotEmpty ? found.storeName : 'Store #$storeId';
  }

  Future<void> _createUser() async {
    final fullNameController = TextEditingController();
    final phoneController = TextEditingController();
    final emailController = TextEditingController();
    final usernameController = TextEditingController();
    final passwordController = TextEditingController();
    final addressController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    int? selectedCompanyId;
    if (_companies.isNotEmpty) {
      selectedCompanyId = _companies.first.id;
    }
    int selectedStoreId = 0; // Default none
    int selectedRoleId = 2;  // Manager role by default

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) {
          final filteredStores = _stores.where((s) => s.companyId == selectedCompanyId).toList();
          if (selectedStoreId != 0 && !filteredStores.any((s) => s.id == selectedStoreId)) {
            selectedStoreId = 0;
          }

          return Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 450),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        selectedRoleId == 2 
                            ? 'Create Manager (Tạo Manager)' 
                            : (selectedRoleId == 3 ? 'Create Employee (Tạo Nhân viên)' : 'Create Customer (Tạo Khách hàng)'),
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      CustomTextField(
                        controller: fullNameController,
                        label: 'Full Name',
                        prefixIcon: Icons.person_outline,
                        validator: (value) => value == null || value.trim().isEmpty ? 'Full name is required' : null,
                      ),
                      CustomTextField(
                        controller: phoneController,
                        label: 'Phone Number',
                        prefixIcon: Icons.phone,
                        keyboardType: TextInputType.phone,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) return 'Phone is required';
                          if (!RegExp(r'^(0[35789][0-9]{8})$').hasMatch(value.trim())) {
                            return 'Invalid Vietnamese format (03/05/07/08/09)';
                          }
                          return null;
                        },
                      ),
                      CustomTextField(
                        controller: emailController,
                        label: 'Email',
                        prefixIcon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) => value == null || value.trim().isEmpty ? 'Email is required' : null,
                      ),
                      CustomTextField(
                        controller: usernameController,
                        label: 'Username',
                        prefixIcon: Icons.alternate_email,
                        validator: (value) => value == null || value.trim().isEmpty ? 'Username is required' : null,
                      ),
                      CustomTextField(
                        controller: passwordController,
                        label: 'Password',
                        prefixIcon: Icons.lock_outline,
                        obscureText: true,
                        validator: (value) => value == null || value.trim().isEmpty ? 'Password is required' : null,
                      ),
                      CustomTextField(
                        controller: addressController,
                        label: 'Address',
                        prefixIcon: Icons.location_city,
                        validator: (value) => value == null || value.trim().isEmpty ? 'Address is required' : null,
                      ),
                      
                      // Dropdown for Role Selection
                      DropdownButtonFormField<int>(
                        value: selectedRoleId,
                        decoration: const InputDecoration(
                          labelText: 'Select Role',
                          prefixIcon: Icon(Icons.badge_outlined),
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(value: 2, child: Text('Manager')),
                          DropdownMenuItem(value: 3, child: Text('Employee (Nhân viên)')),
                          DropdownMenuItem(value: 4, child: Text('Customer (Khách hàng)')),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            setDialogState(() => selectedRoleId = val);
                          }
                        },
                        validator: (val) => val == null ? 'Role is required' : null,
                      ),
                      const SizedBox(height: 16),

                      // Dropdown for Company selection
                      DropdownButtonFormField<int>(
                        value: selectedCompanyId,
                        decoration: const InputDecoration(
                          labelText: 'Select Company Scope',
                          prefixIcon: Icon(Icons.business),
                          border: OutlineInputBorder(),
                        ),
                        items: _companies.map((c) {
                          return DropdownMenuItem(
                            value: c.id,
                            child: Text(c.companyName),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setDialogState(() {
                              selectedCompanyId = val;
                              selectedStoreId = 0; // reset store when company changes
                            });
                          }
                        },
                        validator: (val) => val == null ? 'Company is required' : null,
                      ),
                      const SizedBox(height: 16),

                      // Dropdown for Store selection (hides if customer)
                      if (selectedRoleId != 4) ...[
                        DropdownButtonFormField<int>(
                          value: selectedStoreId,
                          decoration: const InputDecoration(
                            labelText: 'Assign Store of Company',
                            prefixIcon: Icon(Icons.store),
                            border: OutlineInputBorder(),
                          ),
                          items: [
                            const DropdownMenuItem(value: 0, child: Text('Global Store / None')),
                            ...filteredStores.map((s) {
                              return DropdownMenuItem(
                                value: s.id,
                                child: Text(s.storeName),
                              );
                            })
                          ],
                          onChanged: (val) {
                            if (val != null) {
                              setDialogState(() => selectedStoreId = val);
                            }
                          },
                        ),
                        const SizedBox(height: 24),
                      ],
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(dialogContext),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              child: const Text('Cancel'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: CustomButton(
                              label: 'Save',
                              onPressed: () async {
                                if (formKey.currentState?.validate() ?? false) {
                                  if (selectedCompanyId == null) return;
                                  try {
                                    final createdRoleName = selectedRoleId == 2
                                        ? 'Manager'
                                        : (selectedRoleId == 3 ? 'Employee' : 'Customer');
                                    await _service.createUser(
                                      fullName: fullNameController.text.trim(),
                                      phone: phoneController.text.trim(),
                                      email: emailController.text.trim(),
                                      username: usernameController.text.trim(),
                                      password: passwordController.text.trim(),
                                      repeatPassword: passwordController.text.trim(),
                                      companyId: selectedCompanyId!,
                                      address: addressController.text.trim(),
                                      roleId: selectedRoleId,
                                      storeId: selectedRoleId == 4 ? 0 : selectedStoreId,
                                    );
                                    if (mounted) {
                                      ErrorHandler.showSuccess(context, '$createdRoleName account created successfully!');
                                    }
                                    if (!mounted) return;
                                    Navigator.pop(dialogContext);
                                    widget.onRefreshRequested();
                                  } catch (e) {
                                    if (mounted) {
                                      ErrorHandler.showError(context, ErrorHandler.getErrorMessage(e));
                                    }
                                  }
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _toggleStatus(UserResponse user) async {
    try {
      final newStatus = user.status == 1 ? 0 : 1;
      await _service.updateStatus(user.id, newStatus);
      if (!mounted) return;
      ErrorHandler.showSuccess(context, "User status updated successfully!");
      widget.onRefreshRequested();
    } catch (e) {
      if (!mounted) return;
      ErrorHandler.showError(context, ErrorHandler.getErrorMessage(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return FutureBuilder<PageResponse<UserResponse>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting || _isLoadingDropdownData) {
          return const Center(child: CircularProgressIndicator());
        }

        final users = snapshot.data?.content ?? [];
        if (users.isEmpty && _companies.isEmpty) {
          return _buildEmptyState();
        }

        // Group users by companyId
        final Map<int, List<UserResponse>> groupedUsers = {};
        for (final user in users) {
          if (user.companyId != null) {
            groupedUsers.putIfAbsent(user.companyId!, () => []).add(user);
          }
        }

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton.icon(
                  onPressed: _createUser,
                  icon: const Icon(Icons.add),
                  label: const Text('New Manager'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
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
                  itemCount: _companies.length,
                  padding: const EdgeInsets.only(bottom: 24),
                  itemBuilder: (context, index) {
                    final company = _companies[index];
                    final companyUsers = groupedUsers[company.id] ?? [];

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 2,
                      child: ExpansionTile(
                        leading: const Icon(Icons.business, color: Colors.blue),
                        title: Text(
                          company.companyName,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        subtitle: Text(
                          '${companyUsers.length} users / managers',
                          style: const TextStyle(color: Colors.grey, fontSize: 13),
                        ),
                        children: companyUsers.isEmpty
                            ? [
                                const Padding(
                                  padding: EdgeInsets.all(16.0),
                                  child: Text(
                                    'No users registered under this company yet.',
                                    style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
                                  ),
                                )
                              ]
                            : companyUsers.map((user) {
                                return Container(
                                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: theme.cardColor,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.grey[200]!),
                                  ),
                                  child: ExpansionTile(
                                    shape: const Border(),
                                    leading: _buildRoleAvatar(user.roleName),
                                    title: Text(
                                      user.fullName,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                    ),
                                    subtitle: Text(
                                      '${user.roleName ?? '-'} • ${user.email ?? '-'}',
                                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                                    ),
                                    trailing: Switch.adaptive(
                                      value: user.status == 1,
                                      activeColor: theme.primaryColor,
                                      onChanged: (val) => _toggleStatus(user),
                                    ),
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.all(12),
                                        child: Column(
                                          children: [
                                            _buildDetailRow(Icons.alternate_email, 'Username', user.username ?? '-'),
                                            const Divider(height: 12),
                                            _buildDetailRow(Icons.phone_outlined, 'Phone', user.phone ?? '-'),
                                            const Divider(height: 12),
                                            _buildDetailRow(Icons.location_on_outlined, 'Address', user.address ?? '-'),
                                            const Divider(height: 12),
                                            _buildDetailRow(Icons.business_outlined, 'Company', _getCompanyName(user.companyId)),
                                            const Divider(height: 12),
                                            _buildDetailRow(Icons.storefront_outlined, 'Assigned Store', _getStoreName(user.storeId)),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
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

  Widget _buildRoleAvatar(String? role) {
    Color color;
    IconData icon;
    switch (role?.toUpperCase()) {
      case 'ADMIN':
        color = Colors.redAccent;
        icon = Icons.admin_panel_settings;
        break;
      case 'MANAGER':
        color = Colors.teal;
        icon = Icons.manage_accounts;
        break;
      case 'EMPLOYEE':
        color = Colors.blueAccent;
        icon = Icons.badge_outlined;
        break;
      default:
        color = Colors.grey;
        icon = Icons.person;
    }

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: color, size: 20),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey[600]),
        const SizedBox(width: 12),
        Text(
          '$label:',
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: const TextStyle(fontSize: 13, color: Colors.black87),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.people, size: 64, color: Colors.grey),
        const SizedBox(height: 16),
        const Text(
          'No Users Found',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey),
        ),
        const SizedBox(height: 12),
        ElevatedButton(
          onPressed: _createUser,
          child: const Text('Add First User'),
        ),
      ],
    );
  }
}
