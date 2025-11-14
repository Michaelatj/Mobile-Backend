import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_role.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';

class AuthState {
  final bool isAuthenticated;
  final AppUser? user;

  const AuthState({required this.isAuthenticated, this.user});

  AuthState copyWith({bool? isAuthenticated, AppUser? user}) =>
      AuthState(isAuthenticated: isAuthenticated ?? this.isAuthenticated, user: user ?? this.user);

  static const unauthenticated = AuthState(isAuthenticated: false);
}

class AuthController extends StateNotifier<AuthState> {
  AuthController() : super(AuthState.unauthenticated) {
    _restoreSession();
  }

  static const _kIsAuth = 'is_authenticated';
  static const _kUserName = 'user_name';
  static const _kUserRole = 'user_role';
  static const _kUserPhotoUrl = 'user_photo_url';
  static const _kUserLocation = 'user_location_label';
  static const _kUserId = 'user_id';
  static const _kUserTransactions = 'user_transactions';
  static const _kUserOrders = 'user_orders'; // Added key for orders

  Future<void> _restoreSession() async {
    final prefs = await SharedPreferences.getInstance();
    final isAuth = prefs.getBool(_kIsAuth) ?? false;
    if (!isAuth) {
      state = AuthState.unauthenticated;
      return;
    }
    final name = prefs.getString(_kUserName) ?? 'Pengguna';
    final roleStr = prefs.getString(_kUserRole) ?? 'customer';
    final role = roleStr == 'provider' ? UserRole.provider : UserRole.customer;
    final photoUrl = prefs.getString(_kUserPhotoUrl);
    final locationLabel = prefs.getString(_kUserLocation);
    final userId = prefs.getString(_kUserId) ?? 'session';
    final transactions = prefs.getInt(_kUserTransactions) ?? 0;
    final orders = prefs.getStringList(_kUserOrders) ?? []; // Restore orders from prefs
    state = AuthState(
      isAuthenticated: true,
      user: AppUser(
        id: userId,
        name: name,
        role: role,
        photoUrl: photoUrl,
        locationLabel: locationLabel,
        transactions: transactions,
        orders: orders, // Include orders in restored user
      ),
    );
  }

  Future<void> _persistSession({required bool isAuth, AppUser? user}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kIsAuth, isAuth);
    if (isAuth && user != null) {
      await prefs.setString(_kUserName, user.name);
      await prefs.setString(_kUserRole, user.role == UserRole.provider ? 'provider' : 'customer');
      await prefs.setString(_kUserId, user.id);
      await prefs.setInt(_kUserTransactions, user.transactions);
      await prefs.setStringList(_kUserOrders, user.orders); // Persist orders
      if (user.photoUrl != null) {
        await prefs.setString(_kUserPhotoUrl, user.photoUrl!);
      } else {
        await prefs.remove(_kUserPhotoUrl);
      }
      if (user.locationLabel != null) {
        await prefs.setString(_kUserLocation, user.locationLabel!);
      } else {
        await prefs.remove(_kUserLocation);
      }
    } else {
      await prefs.remove(_kUserName);
      await prefs.remove(_kUserRole);
      await prefs.remove(_kUserPhotoUrl);
      await prefs.remove(_kUserLocation);
      await prefs.remove(_kUserId);
      await prefs.remove(_kUserTransactions);
      await prefs.remove(_kUserOrders); // Remove orders on logout
    }
  }

  Future<AppUser> _buildUserFromPrefs({
    required String fallbackId,
    required String fallbackName,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString(_kUserName) ?? fallbackName;
    final roleStr = prefs.getString(_kUserRole) ?? 'customer';
    final role = roleStr == 'provider' ? UserRole.provider : UserRole.customer;
    final photoUrl = prefs.getString(_kUserPhotoUrl);
    final locationLabel = prefs.getString(_kUserLocation);
    final transactions = prefs.getInt(_kUserTransactions) ?? 0;
    final orders = prefs.getStringList(_kUserOrders) ?? []; // Get orders from prefs
    return AppUser(
      id: fallbackId,
      name: name,
      role: role,
      photoUrl: photoUrl,
      locationLabel: locationLabel,
      transactions: transactions,
      orders: orders, // Include orders
    );
  }

  Future<bool> loginWithEmail(String email, String password) async {
    try {
      final apiUser = await ApiService.loginUser(email, password);
      if (apiUser == null) {
        return false; // Login failed - user not found
      }
      
      state = AuthState(isAuthenticated: true, user: apiUser);
      await _persistSession(isAuth: true, user: apiUser);
      return true;
    } catch (e) {
      print('[v0] Login error: $e');
      return false;
    }
  }

  Future<void> loginWithGoogle() async {
    final user = await _buildUserFromPrefs(fallbackId: 'uG', fallbackName: 'Google User');
    state = AuthState(isAuthenticated: true, user: user);
    await _persistSession(isAuth: true, user: user);
  }

  Future<void> loginWithFacebook() async {
    final user = await _buildUserFromPrefs(fallbackId: 'uF', fallbackName: 'Facebook User');
    state = AuthState(isAuthenticated: true, user: user);
    await _persistSession(isAuth: true, user: user);
  }

  Future<bool> register(String email, String password, String name, String role) async {
    try {
      final success = await ApiService.registerUser(
        email: email,
        password: password,
        name: name,
        role: role,
      );
      
      return success; // Return success without auto-login
    } catch (e) {
      print('[v0] Register error: $e');
      return false;
    }
  }

  void chooseRole(UserRole role) {
    final user = state.user;
    if (user != null) {
      state = state.copyWith(user: user.copyWith(role: role));
      _persistSession(isAuth: true, user: user);
    }
  }

  Future<void> logout() async {
    state = AuthState.unauthenticated;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kIsAuth, false);
  }

  Future<void> updateProfile({
    String? name,
    String? locationLabel,
    String? photoUrl,
  }) async {
    final current = state.user;
    if (current == null) return;
    final updated = current.copyWith(
      name: name?.trim().isNotEmpty == true ? name : current.name,
      locationLabel: locationLabel?.trim().isNotEmpty == true ? locationLabel : current.locationLabel,
      photoUrl: (photoUrl != null && photoUrl.trim().isNotEmpty) ? photoUrl : photoUrl == '' ? null : current.photoUrl,
    );
    state = state.copyWith(user: updated);
    await _persistSession(isAuth: true, user: updated);
  }

  Future<bool> processPayment({
    required String invoiceCode,
    required Map<String, dynamic> orderData,
  }) async {
    final current = state.user;
    if (current == null) return false;
    
    try {
      // Call API to process payment and update user
      final success = await ApiService.processPayment(
        userId: current.id,
        invoiceCode: invoiceCode,
        orderData: orderData,
      );

      if (success) {
        // Update local state
        final newOrders = [...current.orders, invoiceCode];
        final newTransactionCount = current.transactions + 1;
        
        final updated = current.copyWith(
          transactions: newTransactionCount,
          orders: newOrders,
        );
        
        state = state.copyWith(user: updated);
        await _persistSession(isAuth: true, user: updated);
      }

      return success;
    } catch (e) {
      print('[v0] Process payment error: $e');
      return false;
    }
  }

  Future<void> incrementTransactions() async {
    final current = state.user;
    if (current == null) return;
    
    // Create a new transaction entry
    final newTransactionId = DateTime.now().millisecondsSinceEpoch.toString();
    final newOrdersList = [...current.orders, newTransactionId];
    
    final newCount = newOrdersList.length;
    final updated = current.copyWith(transactions: newCount);
    
    // Update in mockAPI
    await ApiService.updateUserTransactions(current.id, newOrdersList);
    
    state = state.copyWith(user: updated);
    await _persistSession(isAuth: true, user: updated);
  }
}

final authStateProvider = StateNotifierProvider<AuthController, AuthState>((ref) => AuthController());
