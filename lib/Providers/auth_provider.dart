import 'package:flutter/foundation.dart';
import '../models/auth.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import '../utils/error_handler.dart';

/// Manages authentication state for the entire app.
///
/// Exposes: [user], [isAuthenticated], [isLoading], [errorMessage], [roleName].
/// Actions: [login], [signup], [logout], [clearError].
///
/// Role-based routing: after login, check [roleName] to decide which
/// shell (CustomerShell, StaffShell, AdminShell) to show.
class AuthProvider with ChangeNotifier {
  final AuthService _service = AuthService();

  // ----- State fields -----
  UserResponse? _user;
  bool _isLoading = false;
  String? _errorMessage;

  // ----- Getters -----
  UserResponse? get user => _user;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// True when user has logged in and token is stored.
  bool get isAuthenticated =>
      _user != null && ApiService.instance.authToken != null;

  /// Current user's role name (e.g. "ADMIN", "MANAGER", "EMPLOYEE", "CUSTOMER").
  String? get roleName => _user?.roleName;

  /// Convenience checks for role-based UI.
  bool get isAdmin => roleName?.toUpperCase() == 'ADMIN';
  bool get isManager => roleName?.toUpperCase() == 'MANAGER';
  bool get isEmployee => roleName?.toUpperCase() == 'EMPLOYEE';
  bool get isCustomer => roleName?.toUpperCase() == 'CUSTOMER';

  /// True if user is MANAGER or EMPLOYEE (staff members).
  bool get isStaff => isManager || isEmployee;

  // ----- Actions -----

  /// Login with credentials. On success, stores token and user in memory.
  /// Returns true if login succeeded.
  Future<bool> login({
    required String username,
    required String password,
    required int companyId,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _service.login(
        username: username,
        password: password,
        companyId: companyId,
      );
      // Store token so all subsequent requests are authenticated
      ApiService.instance.authToken = result.token;
      _user = result.user;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = ErrorHandler.getErrorMessage(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Public signup — creates a CUSTOMER account.
  /// Does NOT send roleId or storeId; backend assigns CUSTOMER by default.
  /// Returns true if signup succeeded.
  Future<bool> signup({
    required String fullName,
    required String phone,
    required String email,
    required String username,
    required String password,
    required String repeatPassword,
    required int companyId,
    required String address,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _service.signup(
        fullName: fullName,
        phone: phone,
        email: email,
        username: username,
        password: password,
        repeatPassword: repeatPassword,
        companyId: companyId,
        address: address,
      );
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = ErrorHandler.getErrorMessage(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Clear token and user data. Returns to login screen via RootNavigator.
  void logout() {
    _service.logout();
    _user = null;
    _errorMessage = null;
    notifyListeners();
  }

  /// Clear current error message (e.g. when user edits form fields).
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Replace the current cached user after a successful profile update.
  void updateUser(UserResponse user) {
    _user = user;
    notifyListeners();
  }
}
