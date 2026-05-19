import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../utils/error_handler.dart';
import '../Widgets/custom_button.dart';

class EmailVerificationScreen extends StatefulWidget {
  final String email;

  const EmailVerificationScreen({super.key, required this.email});

  @override
  State<EmailVerificationScreen> createState() => _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  final _codeCtrl = TextEditingController();
  final AuthService _authService = AuthService();
  bool _isLoading = false;
  bool _isResending = false;

  @override
  void dispose() {
    _codeCtrl.dispose();
    super.dispose();
  }

  Future<void> _verifyCode() async {
    final code = _codeCtrl.text.trim();
    if (code.length != 6) {
      ErrorHandler.showInfo(context, 'Vui lòng nhập đầy đủ mã xác nhận gồm 6 chữ số.');
      return;
    }

    setState(() => _isLoading = true);
    try {
      await _authService.verifyEmail(widget.email, code);
      if (mounted) {
        ErrorHandler.showSuccess(context, 'Xác thực email thành công! Bạn có thể đăng nhập ngay.');
        // Navigate back to login
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ErrorHandler.showError(context, ErrorHandler.getErrorMessage(e));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _resendCode() async {
    setState(() => _isResending = true);
    try {
      await _authService.resendVerification(widget.email);
      if (mounted) {
        ErrorHandler.showSuccess(context, 'Đã gửi lại mã xác nhận mới! Vui lòng kiểm tra hộp thư email.');
      }
    } catch (e) {
      if (mounted) {
        ErrorHandler.showError(context, ErrorHandler.getErrorMessage(e));
      }
    } finally {
      if (mounted) setState(() => _isResending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify Email'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.mark_email_read_outlined, size: 64, color: Colors.blue),
            const SizedBox(height: 24),
            Text(
              'Enter Verification Code',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'We have sent a 6-digit code to:\n${widget.email}',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
            ),
            const SizedBox(height: 32),
            TextField(
              controller: _codeCtrl,
              keyboardType: TextInputType.number,
              maxLength: 6,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 24, letterSpacing: 8, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                hintText: '000000',
                counterText: '',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 24),
            CustomButton(
              label: 'Verify',
              onPressed: _verifyCode,
              isLoading: _isLoading,
              icon: Icons.check_circle_outline,
            ),
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: _isResending ? null : _resendCode,
              icon: _isResending
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.refresh),
              label: Text(_isResending ? 'Resending...' : 'Resend Code'),
            ),
          ],
        ),
      ),
    );
  }
}
