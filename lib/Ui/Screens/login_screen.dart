import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../Providers/auth_provider.dart';
import '../../models/company.dart';
import '../../services/company_service.dart';
import '../../services/user_service.dart';
import '../../services/auth_service.dart';
import '../Widgets/custom_text_field.dart';
import '../Widgets/custom_button.dart';
import 'signup_screen.dart';
import 'email_verification_screen.dart';
import '../../utils/error_handler.dart';

class LoginScreen extends StatefulWidget {
  final bool showSignup;
  const LoginScreen({super.key, this.showSignup = true});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscurePassword = true;

  final CompanyService _companyService = CompanyService();
  final UserService _userService = UserService();
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
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    _companySearchCtrl.dispose();
    super.dispose();
  }

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
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        'Select Company',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ),
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
                    Expanded(
                      child: _filteredCompanies.isEmpty
                          ? const Center(child: Text('No companies found'))
                          : ListView.separated(
                              controller: scrollController,
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              itemCount: _filteredCompanies.length,
                              separatorBuilder: (_, __) => const Divider(height: 1),
                              itemBuilder: (context, index) {
                                final company = _filteredCompanies[index];
                                final isSelected = _selectedCompany?.id == company.id;

                                return ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: isSelected
                                        ? Theme.of(context).colorScheme.primary
                                        : Colors.grey[200],
                                    child: Text(
                                      (company.companyName.isNotEmpty ? company.companyName[0] : '?').toUpperCase(),
                                      style: TextStyle(
                                        color: isSelected ? Colors.white : Colors.grey[600],
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  title: Text(
                                    company.companyName,
                                    style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal),
                                  ),
                                  subtitle: company.companyAddress != null ? Text(company.companyAddress!) : null,
                                  trailing: isSelected ? Icon(Icons.check_circle, color: Theme.of(context).colorScheme.primary) : null,
                                  onTap: () {
                                    setState(() => _selectedCompany = company);
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

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCompany == null) {
      ErrorHandler.showInfo(context, 'Please select a company before logging in.');
      return;
    }

    final auth = context.read<AuthProvider>();
    final success = await auth.login(
      username: _usernameCtrl.text.trim(),
      password: _passwordCtrl.text,
      companyId: _selectedCompany!.id,
    );

    if (!success && mounted) {
      if (auth.errorMessage != null && 
         (auth.errorMessage!.contains('not activated') || auth.errorMessage!.contains('verify'))) {
        _showUnverifiedDialog();
      }
    }
  }

  void _showUnverifiedDialog() {
    final emailCtrl = TextEditingController();
    bool isSending = false;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Text('Account Not Verified'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Your account is not activated. Please verify your email to continue.'),
                  const SizedBox(height: 16),
                  CustomTextField(
                    controller: emailCtrl,
                    label: 'Enter your email',
                    prefixIcon: Icons.email_outlined,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isSending ? null : () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: isSending
                      ? null
                      : () async {
                          final email = emailCtrl.text.trim();
                          if (email.isEmpty) {
                            ErrorHandler.showInfo(context, 'Please enter your email.');
                            return;
                          }
                          setModalState(() => isSending = true);
                          try {
                            await AuthService().resendVerification(email, _selectedCompany!.id);
                            if (context.mounted) {
                              Navigator.pop(dialogContext);
                              ErrorHandler.showSuccess(context, 'Verification code sent! Please check your email inbox.');
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => EmailVerificationScreen(
                                    email: email,
                                    companyId: _selectedCompany!.id,
                                  ),
                                ),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              setModalState(() => isSending = false);
                              ErrorHandler.showError(context, ErrorHandler.getErrorMessage(e));
                            }
                          }
                        },
                  child: isSending
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Verify'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showForgotPasswordDialog() {
    if (_selectedCompany == null) {
      ErrorHandler.showInfo(context, 'Please select a company before resetting password.');
      return;
    }
    final forgotFormKey = GlobalKey<FormState>();
    final fUsernameCtrl = TextEditingController();
    final fEmailCtrl = TextEditingController();
    final fNewPasswordCtrl = TextEditingController();
    final fConfirmPasswordCtrl = TextEditingController();
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              title: const Text('Forgot Password'),
              content: SingleChildScrollView(
                child: Form(
                  key: forgotFormKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Enter your details to reset your password.', style: TextStyle(fontSize: 14, color: Colors.grey)),
                      const SizedBox(height: 16),
                      CustomTextField(
                        controller: fUsernameCtrl,
                        label: 'Username',
                        prefixIcon: Icons.person_outline,
                        validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                      ),
                      CustomTextField(
                        controller: fEmailCtrl,
                        label: 'Email',
                        prefixIcon: Icons.email_outlined,
                        validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                      ),
                      CustomTextField(
                        controller: fNewPasswordCtrl,
                        label: 'New Password',
                        prefixIcon: Icons.lock_outline,
                        obscureText: true,
                        validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                      ),
                      CustomTextField(
                        controller: fConfirmPasswordCtrl,
                        label: 'Confirm New Password',
                        prefixIcon: Icons.lock_reset,
                        obscureText: true,
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Required';
                          if (v != fNewPasswordCtrl.text) return 'Passwords do not match';
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(onPressed: isSubmitting ? null : () => Navigator.pop(context), child: const Text('Cancel')),
                ElevatedButton(
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          if (!forgotFormKey.currentState!.validate()) return;
                          setModalState(() => isSubmitting = true);
                          try {
                            final msg = await _userService.forgotPassword(
                              username: fUsernameCtrl.text.trim(),
                              email: fEmailCtrl.text.trim(),
                              newPassword: fNewPasswordCtrl.text,
                              confirmPassword: fConfirmPasswordCtrl.text,
                              companyId: _selectedCompany!.id,
                            );
                            if (context.mounted) {
                              Navigator.pop(context);
                              ErrorHandler.showSuccess(context, msg);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => EmailVerificationScreen(
                                    email: fEmailCtrl.text.trim(),
                                    companyId: _selectedCompany!.id,
                                  ),
                                ),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              setModalState(() => isSubmitting = false);
                              ErrorHandler.showError(context, ErrorHandler.getErrorMessage(e));
                            }
                          }
                        },
                  child: isSubmitting ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Reset Password'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final theme = Theme.of(context);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              theme.colorScheme.primary.withOpacity(0.08),
              theme.colorScheme.background,
              Colors.white,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.shopping_bag_outlined,
                        size: 64,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Sapo Retail',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: theme.colorScheme.primary,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Welcome back!',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 32),
                    Card(
                      elevation: 4,
                      shadowColor: Colors.black.withOpacity(0.08),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      color: Colors.white,
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'Customer Login',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[800],
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 20),
                            _buildCompanySelector(theme),
                            const SizedBox(height: 12),
                            CustomTextField(
                              controller: _usernameCtrl,
                              label: 'Username',
                              prefixIcon: Icons.person_outline,
                              validator: (v) =>
                                  (v == null || v.trim().isEmpty) ? 'Please enter your username' : null,
                            ),
                            CustomTextField(
                              controller: _passwordCtrl,
                              label: 'Password',
                              prefixIcon: Icons.lock_outline,
                              obscureText: _obscurePassword,
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                                  color: Colors.grey,
                                  size: 20,
                                ),
                                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                              ),
                              validator: (v) =>
                                  (v == null || v.isEmpty) ? 'Please enter your password' : null,
                            ),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: _showForgotPasswordDialog,
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: Text(
                                  'Forgot password?',
                                  style: TextStyle(
                                    color: theme.colorScheme.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            if (auth.errorMessage != null) ...[
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.red[50],
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: Colors.red[100]!),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.error_outline, color: Colors.red[400], size: 20),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        auth.errorMessage!,
                                        style: TextStyle(color: Colors.red[700], fontSize: 13, fontWeight: FontWeight.w500),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                            ],
                            CustomButton(
                              label: 'Login',
                              onPressed: _handleLogin,
                              isLoading: auth.isLoading,
                              icon: Icons.login_rounded,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    if (widget.showSignup)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text("Don't have an account? ", style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.w500)),
                          TextButton(
                            onPressed: () {
                              auth.clearError();
                              Navigator.push(context, MaterialPageRoute(builder: (_) => const SignupScreen()));
                            },
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: Text(
                              'Register now',
                              style: TextStyle(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCompanySelector(ThemeData theme) {
    if (_isLoadingCompanies) {
      return Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.grey.shade200),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 12),
            Text(
              'Loading companies...',
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            )
          ],
        ),
      );
    }
    if (_companyError != null) {
      return Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.orange[50],
          border: Border.all(color: Colors.orange[200]!),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.orange),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _companyError!,
                style: TextStyle(fontSize: 13, color: Colors.orange.shade800),
              ),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _isLoadingCompanies = true;
                  _companyError = null;
                });
                _loadCompanies();
              },
              child: const Text('Retry'),
            )
          ],
        ),
      );
    }
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: _showCompanyPicker,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(
              color: _selectedCompany != null ? theme.colorScheme.primary : Colors.grey.shade200,
              width: _selectedCompany != null ? 1.5 : 1.0,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(
                Icons.business_rounded,
                color: _selectedCompany != null ? theme.colorScheme.primary : Colors.grey[500],
                size: 22,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _selectedCompany != null
                     ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _selectedCompany!.companyName,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                              fontSize: 14,
                            ),
                          ),
                          if (_selectedCompany!.companyAddress != null)
                            Text(
                              _selectedCompany!.companyAddress!,
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            )
                        ],
                      )
                    : Text(
                        'Select company / store',
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      ),
              ),
              Icon(Icons.keyboard_arrow_down_rounded, color: Colors.grey[600]),
            ],
          ),
        ),
      ),
    );
  }
}
