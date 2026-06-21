import 'package:flutter/foundation.dart';
import '../models/auth.dart';
import '../models/page_response.dart';
import '../services/user_service.dart';
import '../utils/error_handler.dart';

class UserProvider extends ChangeNotifier {
  final UserService _userService = UserService();

  List<UserResponse> _users = [];
  bool _isLoading = false;
  String? _errorMessage;
  int _currentPage = 0;
  int _totalPages = 1;
  String _searchKeyword = '';

  // Getters
  List<UserResponse> get users => _users;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int get currentPage => _currentPage;
  int get totalPages => _totalPages;

  /// Fetch users for management (MANAGER/ADMIN-only)
  Future<void> fetchUsers({
    String keyword = '',
    int page = 0,
    int size = 50,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    _searchKeyword = keyword;
    _currentPage = page;
    notifyListeners();

    try {
      final response = await _userService.getList(
        keyword: keyword,
        page: page,
        size: size,
      );

      _users = response.content;
      _totalPages = response.totalPages;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = ErrorHandler.getErrorMessage(e);
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Create a new user (MANAGER for employees, ADMIN for managers)
  Future<bool> createUser({
    required String fullName,
    required String phone,
    required String email,
    required String username,
    required String password,
    required String repeatPassword,
    required int companyId,
    required String address,
    required int roleId,
    int storeId = 0,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final newUser = await _userService.createUser(
        fullName: fullName,
        phone: phone,
        email: email,
        username: username,
        password: password,
        repeatPassword: repeatPassword,
        companyId: companyId,
        address: address,
        roleId: roleId,
        storeId: storeId,
      );

      _users.insert(0, newUser);
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

  /// Quick register a customer (used in POS screen)
  Future<UserResponse?> registerCustomer({
    required String fullName,
    required String phone,
    required int companyId,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final newUser = await _userService.createUser(
        fullName: fullName,
        phone: phone,
        email: '$phone@customer.sapo.vn',
        username: phone,
        password: '123',
        repeatPassword: '123',
        companyId: companyId,
        address: 'POS Quick Register',
        roleId: 4, // ID for CUSTOMER role
      );

      _users.insert(0, newUser);
      _isLoading = false;
      notifyListeners();
      return newUser;
    } catch (e) {
      _errorMessage = ErrorHandler.getErrorMessage(e);
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  /// Update user status (block/unblock)
  Future<bool> updateUserStatus(int userId, int status) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final updatedUser = await _userService.updateStatus(userId, status);
      
      // Update in local list
      final index = _users.indexWhere((u) => u.id == userId);
      if (index != -1) {
        _users[index] = updatedUser;
      }
      
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

  /// Go to next page
  Future<void> nextPage() async {
    if (_currentPage < _totalPages - 1) {
      await fetchUsers(
        keyword: _searchKeyword,
        page: _currentPage + 1,
      );
    }
  }

  /// Go to previous page
  Future<void> previousPage() async {
    if (_currentPage > 0) {
      await fetchUsers(
        keyword: _searchKeyword,
        page: _currentPage - 1,
      );
    }
  }

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
