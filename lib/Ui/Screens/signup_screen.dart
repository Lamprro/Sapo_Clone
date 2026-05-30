import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../Providers/auth_provider.dart';
import '../../models/company.dart';
import '../../services/company_service.dart';
import '../Widgets/custom_text_field.dart';
import '../Widgets/custom_button.dart';
import 'email_verification_screen.dart';

import '../../utils/error_handler.dart';

/// Signup screen for PUBLIC registration (always CUSTOMER role).
///
/// Backend: POST /api/auth/signup
/// Fields sent: fullName, phone, email, username, password,
/// repeatPassword, companyId, address.
///
/// roleId and storeId are NOT shown — backend defaults to CUSTOMER role.
/// Internal user creation (ADMIN→MANAGER, MANAGER→EMPLOYEE, etc.)
/// is handled in a separate screen (create_user_screen.dart).
class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers for each form field
  final _fullNameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _repeatPasswordCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureRepeat = true;

  // Company selection (same as login screen)
  final CompanyService _companyService = CompanyService();
  List<CompanyResponse> _companies = [];
  List<CompanyResponse> _filteredCompanies = [];
  CompanyResponse? _selectedCompany;
  bool _isLoadingCompanies = true;
  String? _companyError;
  final _companySearchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadCompanies();
  }

  @override
  void dispose() {
    _fullNameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    _repeatPasswordCtrl.dispose();
    _addressCtrl.dispose();
    _companySearchCtrl.dispose();
    super.dispose();
  }

  /// Load company list from backend.
  Future<void> _loadCompanies() async {
    try {
      final page = await _companyService.getList(size: 100);
      setState(() {
        _companies = page.content;
        _filteredCompanies = page.content;
        _isLoadingCompanies = false;
      });
    } catch (e) {
      setState(() {
        _companyError = 'Failed to load companies';
        _isLoadingCompanies = false;
      });
    }
  }

  /// Filter company list based on search keyword.
  void _onCompanySearch(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredCompanies = _companies;
      } else {
        _filteredCompanies = _companies
            .where((c) =>
                c.companyName.toLowerCase().contains(query.toLowerCase()) ||
                (c.companyAddress ?? '')
                    .toLowerCase()
                    .contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  /// Show bottom sheet with searchable company list.
  void _showCompanyPicker() {
    _companySearchCtrl.clear();
    _filteredCompanies = _companies;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return DraggableScrollableSheet(
              initialChildSize: 0.7,
              minChildSize: 0.4,
              maxChildSize: 0.9,
              expand: false,
              builder: (context, scrollController) {
                return Column(
                  children: [
                    // Handle bar
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    // Title
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        'Select Company',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ),
                    // Search bar
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: TextField(
                        controller: _companySearchCtrl,
                        decoration: InputDecoration(
                          hintText: 'Search by name or address...',
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onChanged: (query) {
                          _onCompanySearch(query);
                          setModalState(() {});
                        },
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Company list
                    Expanded(
                      child: _filteredCompanies.isEmpty
                          ? Center(
                              child: Text(
                                'No companies found',
                                style: TextStyle(color: Colors.grey[500]),
                              ),
                            )
                          : ListView.separated(
                              controller: scrollController,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 8),
                              itemCount: _filteredCompanies.length,
                              separatorBuilder: (_, __) =>
                                  const Divider(height: 1),
                              itemBuilder: (context, index) {
                                final company = _filteredCompanies[index];
                                final isSelected =
                                    _selectedCompany?.id == company.id;
                                return ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: isSelected
                                        ? Theme.of(context).colorScheme.primary
                                        : Colors.grey[200],
                                    child: Text(
                                      (company.companyName.isNotEmpty ? company.companyName[0] : '?').toUpperCase(),
                                      style: TextStyle(
                                        color: isSelected
                                            ? Colors.white
                                            : Colors.grey[600],
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  title: Text(company.companyName),
                                  subtitle: company.companyAddress != null
                                      ? Text(company.companyAddress!,
                                          style: TextStyle(
                                              color: Colors.grey[600],
                                              fontSize: 13))
                                      : null,
                                  trailing: isSelected
                                      ? Icon(Icons.check_circle,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primary)
                                      : Text('ID: ${company.id}',
                                          style: TextStyle(
                                              color: Colors.grey[400],
                                              fontSize: 12)),
                                  onTap: () {
                                    setState(() =>
                                        _selectedCompany = company);
                                    Navigator.pop(context);
                                  },
                                );
                              },
                            ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  /// Submit signup form → calls AuthProvider.signup()
  /// Public signup always uses CUSTOMER defaults (no roleId/storeId).
  Future<void> _handleSignup() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCompany == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a company'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final auth = context.read<AuthProvider>();
    final success = await auth.signup(
      fullName: _fullNameCtrl.text.trim(),
      phone: _phoneCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      username: _usernameCtrl.text.trim(),
      password: _passwordCtrl.text,
      repeatPassword: _repeatPasswordCtrl.text,
      companyId: _selectedCompany!.id,
      address: _addressCtrl.text.trim(),
    );

    if (success && mounted) {
      ErrorHandler.showSuccess(context, 'Account registered successfully! Please verify your email.');
      // Navigate to email verification screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => EmailVerificationScreen(
            email: _emailCtrl.text.trim(),
            companyId: _selectedCompany!.id,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Account'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // --- Section: Select Company ---
              Text(
                'Company',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              _buildCompanySelector(theme),
              const SizedBox(height: 20),

              // --- Section: Personal Information ---
              Text(
                'Personal Information',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              CustomTextField(
                controller: _fullNameCtrl,
                label: 'Full Name',
                prefixIcon: Icons.person_outline,
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Full name is required' : null,
              ),
              CustomTextField(
                controller: _phoneCtrl,
                label: 'Phone Number',
                prefixIcon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                hintText: '0912345678',
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Phone is required';
                  final regex = RegExp(r'^(0[35789][0-9]{8})$');
                  if (!regex.hasMatch(v.trim())) {
                    return 'Invalid Vietnamese phone number';
                  }
                  return null;
                },
              ),
              CustomTextField(
                controller: _emailCtrl,
                label: 'Email',
                prefixIcon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Email is required';
                  if (!v.contains('@')) return 'Invalid email format';
                  return null;
                },
              ),
              CustomTextField(
                controller: _addressCtrl,
                label: 'Address',
                prefixIcon: Icons.location_on_outlined,
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Address is required' : null,
              ),

              const SizedBox(height: 8),

              // --- Section: Account Information ---
              Text(
                'Account Information',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              CustomTextField(
                controller: _usernameCtrl,
                label: 'Username',
                prefixIcon: Icons.account_circle_outlined,
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Username is required' : null,
              ),
              CustomTextField(
                controller: _passwordCtrl,
                label: 'Password',
                prefixIcon: Icons.lock_outline,
                obscureText: _obscurePassword,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_off : Icons.visibility,
                  ),
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Password is required';
                  return null;
                },
              ),
              CustomTextField(
                controller: _repeatPasswordCtrl,
                label: 'Confirm Password',
                prefixIcon: Icons.lock_outline,
                obscureText: _obscureRepeat,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureRepeat ? Icons.visibility_off : Icons.visibility,
                  ),
                  onPressed: () =>
                      setState(() => _obscureRepeat = !_obscureRepeat),
                ),
                validator: (v) {
                  if (v != _passwordCtrl.text) return 'Passwords do not match';
                  return null;
                },
              ),

              // --- Error message ---
              if (auth.errorMessage != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red[200]!),
                  ),
                  child: Text(
                    auth.errorMessage!,
                    style: TextStyle(color: Colors.red[700], fontSize: 14),
                  ),
                ),
              ],

              const SizedBox(height: 24),

              // --- Submit button ---
              CustomButton(
                label: 'Create Account',
                onPressed: _handleSignup,
                isLoading: auth.isLoading,
                icon: Icons.person_add,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build the company selector widget (same as login screen).
  Widget _buildCompanySelector(ThemeData theme) {
    if (_isLoadingCompanies) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Row(
          children: [
            SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
            SizedBox(width: 12),
            Text('Loading companies...'),
          ],
        ),
      );
    }
    if (_companyError != null) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.orange[50],
          border: Border.all(color: Colors.orange[200]!),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(Icons.warning_amber, color: Colors.orange[600], size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(_companyError!)),
            TextButton(
              onPressed: () {
                setState(() { _isLoadingCompanies = true; _companyError = null; });
                _loadCompanies();
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }
    return InkWell(
      onTap: _showCompanyPicker,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: _selectedCompany != null
                ? theme.colorScheme.primary
                : Colors.grey[400]!,
          ),
          borderRadius: BorderRadius.circular(8),
          color: _selectedCompany != null
              ? theme.colorScheme.primary.withValues(alpha: 0.05)
              : null,
        ),
        child: Row(
          children: [
            Icon(Icons.business,
                color: _selectedCompany != null
                    ? theme.colorScheme.primary
                    : Colors.grey[500]),
            const SizedBox(width: 12),
            Expanded(
              child: _selectedCompany != null
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_selectedCompany!.companyName,
                            style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: theme.colorScheme.primary,
                                fontSize: 15)),
                        if (_selectedCompany!.companyAddress != null)
                          Text(_selectedCompany!.companyAddress!,
                              style: TextStyle(
                                  color: Colors.grey[600], fontSize: 13)),
                      ],
                    )
                  : Text('Select a Company',
                      style:
                          TextStyle(color: Colors.grey[500], fontSize: 15)),
            ),
            Icon(Icons.arrow_drop_down, color: Colors.grey[500]),
          ],
        ),
      ),
    );
  }
}
