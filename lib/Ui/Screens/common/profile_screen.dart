import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../Providers/auth_provider.dart';
import '../../../services/user_service.dart';
import '../../Widgets/custom_text_field.dart';
import '../../Widgets/custom_button.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _userService = UserService();
  static final _phoneRegex = RegExp(r'^0[35789][0-9]{8}$');
  static final _emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
  
  late TextEditingController _fullNameCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _emailCtrl;
  late TextEditingController _addressCtrl;
  
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().user;
    _fullNameCtrl = TextEditingController(text: user?.fullName);
    _phoneCtrl = TextEditingController(text: user?.phone);
    _emailCtrl = TextEditingController(text: user?.email);
    _addressCtrl = TextEditingController(text: user?.address);
  }

  @override
  void dispose() {
    _fullNameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final updatedUser = await _userService.updateProfile(
        fullName: _fullNameCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        address: _addressCtrl.text.trim(),
      );
      if (mounted) {
        context.read<AuthProvider>().updateUser(updatedUser);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating profile: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isCustomer = context.read<AuthProvider>().isCustomer;
    return Scaffold(
      appBar: AppBar(title: const Text('My Profile')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              CustomTextField(
                controller: _fullNameCtrl,
                label: 'Full Name',
                prefixIcon: Icons.person,
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              CustomTextField(
                controller: _phoneCtrl,
                label: 'Phone',
                prefixIcon: Icons.phone,
                keyboardType: TextInputType.phone,
                validator: (v) {
                  final value = v?.trim() ?? '';
                  if (value.isEmpty) return 'Required';
                  if (!_phoneRegex.hasMatch(value)) {
                    return 'Invalid Vietnamese phone number';
                  }
                  return null;
                },
              ),
              CustomTextField(
                controller: _emailCtrl,
                label: 'Email',
                prefixIcon: Icons.email,
                keyboardType: TextInputType.emailAddress,
                readOnly: isCustomer,
                validator: (v) {
                  final value = v?.trim() ?? '';
                  if (value.isEmpty) return 'Required';
                  if (!_emailRegex.hasMatch(value)) {
                    return 'Invalid email format';
                  }
                  return null;
                },
              ),
              CustomTextField(
                controller: _addressCtrl,
                label: 'Address',
                prefixIcon: Icons.location_on,
                validator: (_) => null,
              ),
              const SizedBox(height: 24),
              CustomButton(
                label: 'Save Changes',
                icon: Icons.save,
                onPressed: _updateProfile,
                isLoading: _isLoading,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
