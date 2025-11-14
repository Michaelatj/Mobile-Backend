import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_role.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthState {
  final bool isAuthenticated;
  final AppUser? user;

  const AuthState({required this.isAuthenticated, this.user});

  AuthState copyWith({bool? isAuthenticated, AppUser? user}) =>
      AuthState(isAuthenticated: isAuthenticated ?? this.isAuthenticated, user: user ?? this.user);

  static const unauthenticated = AuthState(isAuthenticated: false);
}

class AuthController extends StateNotifier<AuthState> {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  AuthController() : super(AuthState.unauthenticated) {
    _restoreSession();
  }

  static const _kIsAuth = 'is_authenticated';
  static const _kUserName = 'user_name';
  static const _kUserRole = 'user_role';
  static const _kUserPhotoUrl = 'user_photo_url';
  static const _kUserLocation = 'user_location_label';
  static const _kUserId = 'user_id';
  static const _kUserEmail = 'user_email';
  static const _kUserTransactions = 'user_transactions';
  static const _kUserOrders = 'user_orders';

  Future<void> _restoreSession() async {
    final prefs = await SharedPreferences.getInstance();
    final isAuth = prefs.getBool(_kIsAuth) ?? false;
    
    // Check Firebase Auth state
    final firebaseUser = _firebaseAuth.currentUser;
    
    if (!isAuth || firebaseUser == null) {
      state = AuthState.unauthenticated;
      return;
    }

    final name = prefs.getString(_kUserName) ?? 'Pengguna';
    final roleStr = prefs.getString(_kUserRole) ?? 'customer';
    final role = roleStr == 'provider' ? UserRole.provider : UserRole.customer;
    final photoUrl = prefs.getString(_kUserPhotoUrl);
    final locationLabel = prefs.getString(_kUserLocation);
    final userId = prefs.getString(_kUserId) ?? firebaseUser.uid;
    final transactions = prefs.getInt(_kUserTransactions) ?? 0;
    final orders = prefs.getStringList(_kUserOrders) ?? [];
    
    state = AuthState(
      isAuthenticated: true,
      user: AppUser(
        id: userId,
        name: name,
        role: role,
        photoUrl: photoUrl,
        locationLabel: locationLabel,
        transactions: transactions,
        orders: orders,
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
      await prefs.setStringList(_kUserOrders, user.orders);
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
      await prefs.remove(_kUserEmail);
      await prefs.remove(_kUserTransactions);
      await prefs.remove(_kUserOrders);
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
    final orders = prefs.getStringList(_kUserOrders) ?? [];
    return AppUser(
      id: fallbackId,
      name: name,
      role: role,
      photoUrl: photoUrl,
      locationLabel: locationLabel,
      transactions: transactions,
      orders: orders,
    );
  }

  /// LOGIN WITH EMAIL/PASSWORD (Firebase Auth + MockAPI)
  Future<bool> loginWithEmail(String email, String password) async {
    try {
      // 1. Login ke Firebase Auth
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user == null) {
        debugPrint('[AUTH] Firebase login success but user is null');
        return false;
      }

      debugPrint('[AUTH] Firebase login success: ${credential.user!.uid}');

      // 2. Ambil data user dari MockAPI (FRESH DATA)
      final apiUser = await ApiService.loginUser(email, password);
      
      if (apiUser == null) {
        debugPrint('[AUTH] User not found in MockAPI, creating default user');
        // Jika belum ada di MockAPI, buat default user dengan Firebase UID
        final newUser = AppUser(
          id: credential.user!.uid,
          name: credential.user!.displayName ?? email.split('@')[0],
          role: UserRole.customer,
          photoUrl: credential.user!.photoURL,
          transactions: 0,
          orders: [],
        );
        
        state = AuthState(isAuthenticated: true, user: newUser);
        await _persistSession(isAuth: true, user: newUser);
        return true;
      }

      // 3. GUNAKAN MockAPI ID (BUKAN Firebase UID!)
      // MockAPI user sudah punya id sendiri (contoh: "5", "6")
      state = AuthState(isAuthenticated: true, user: apiUser);
      await _persistSession(isAuth: true, user: apiUser);
      
      debugPrint('[AUTH] Login complete: ${apiUser.name} (MockAPI ID: ${apiUser.id})');
      debugPrint('[AUTH] User transactions count: ${apiUser.transactions}');
      return true;

    } on FirebaseAuthException catch (e) {
      debugPrint('[AUTH] Firebase Auth error: ${e.code} - ${e.message}');
      
      // Handle specific Firebase Auth errors
      switch (e.code) {
        case 'user-not-found':
        case 'wrong-password':
        case 'invalid-credential':
          debugPrint('[AUTH] Invalid credentials');
          break;
        case 'user-disabled':
          debugPrint('[AUTH] User account disabled');
          break;
        case 'too-many-requests':
          debugPrint('[AUTH] Too many attempts, try again later');
          break;
        default:
          debugPrint('[AUTH] Unknown Firebase error: ${e.code}');
      }
      return false;
      
    } catch (e) {
      debugPrint('[AUTH] Unexpected error during login: $e');
      return false;
    }
  }

  /// REGISTER WITH EMAIL/PASSWORD (Firebase Auth + MockAPI)
  Future<bool> register(String email, String password, String name, String role) async {
    try {
      // 1. Register ke Firebase Auth
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user == null) {
        debugPrint('[AUTH] Firebase registration success but user is null');
        return false;
      }

      debugPrint('[AUTH] Firebase registration success: ${credential.user!.uid}');

      // 2. Update display name di Firebase
      await credential.user!.updateDisplayName(name);

      // 3. Register ke MockAPI (opsional, untuk sync data)
      final success = await ApiService.registerUser(
        email: email,
        password: password,
        name: name,
        role: role,
      );

      if (!success) {
        debugPrint('[AUTH] MockAPI registration failed, but Firebase success');
        // Tetap return true karena Firebase Auth berhasil
      }

      debugPrint('[AUTH] Registration complete: $name ($email)');
      return true;

    } on FirebaseAuthException catch (e) {
      debugPrint('[AUTH] Firebase registration error: ${e.code} - ${e.message}');
      
      switch (e.code) {
        case 'email-already-in-use':
          debugPrint('[AUTH] Email already registered');
          break;
        case 'weak-password':
          debugPrint('[AUTH] Password too weak');
          break;
        case 'invalid-email':
          debugPrint('[AUTH] Invalid email format');
          break;
        default:
          debugPrint('[AUTH] Unknown Firebase error: ${e.code}');
      }
      return false;
      
    } catch (e) {
      debugPrint('[AUTH] Unexpected error during registration: $e');
      return false;
    }
  }

  /// LOGIN WITH GOOGLE (Placeholder - tetap seperti sebelumnya)
  Future<void> loginWithGoogle() async {
    final user = await _buildUserFromPrefs(fallbackId: 'uG', fallbackName: 'Google User');
    state = AuthState(isAuthenticated: true, user: user);
    await _persistSession(isAuth: true, user: user);
  }

  /// LOGIN WITH FACEBOOK (Placeholder - tetap seperti sebelumnya)
  Future<void> loginWithFacebook() async {
    final user = await _buildUserFromPrefs(fallbackId: 'uF', fallbackName: 'Facebook User');
    state = AuthState(isAuthenticated: true, user: user);
    await _persistSession(isAuth: true, user: user);
  }

  void chooseRole(UserRole role) {
    final user = state.user;
    if (user != null) {
      state = state.copyWith(user: user.copyWith(role: role));
      _persistSession(isAuth: true, user: user);
    }
  }

  /// LOGOUT (Firebase Auth + Local)
  Future<void> logout() async {
    try {
      await _firebaseAuth.signOut();
      debugPrint('[AUTH] Firebase sign out success');
    } catch (e) {
      debugPrint('[AUTH] Firebase sign out error: $e');
    }
    
    state = AuthState.unauthenticated;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kIsAuth, false);
    debugPrint('[AUTH] Local session cleared');
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
    
    // Update Firebase display name if name changed
    if (name != null && name.trim().isNotEmpty) {
      try {
        await _firebaseAuth.currentUser?.updateDisplayName(name);
      } catch (e) {
        debugPrint('[AUTH] Failed to update Firebase display name: $e');
      }
    }
    
    // Update photo URL if changed
    if (photoUrl != null && photoUrl.trim().isNotEmpty) {
      try {
        await _firebaseAuth.currentUser?.updatePhotoURL(photoUrl);
      } catch (e) {
        debugPrint('[AUTH] Failed to update Firebase photo URL: $e');
      }
    }
    
    state = state.copyWith(user: updated);
    await _persistSession(isAuth: true, user: updated);
  }

  /// REFRESH USER DATA FROM API (untuk sync transaction count)
  Future<void> refreshUserData() async {
    final current = state.user;
    if (current == null) return;

    try {
      // Ambil fresh data dari API
      final count = await ApiService.getUserTransactions(current.id);
      
      if (count != current.transactions) {
        debugPrint('[AUTH] Refreshing user data: transactions $count');
        
        final updated = current.copyWith(
          transactions: count,
        );
        
        state = state.copyWith(user: updated);
        await _persistSession(isAuth: true, user: updated);
      }
    } catch (e) {
      debugPrint('[AUTH] Failed to refresh user data: $e');
    }
  }

  Future<bool> processPayment({
    required String invoiceCode,
    required Map<String, dynamic> orderData,
  }) async {
    final current = state.user;
    if (current == null) return false;
    
    try {
      final success = await ApiService.processPayment(
        userId: current.id,
        invoiceCode: invoiceCode,
        orderData: orderData,
      );

      if (success) {
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
      debugPrint('[AUTH] Process payment error: $e');
      return false;
    }
  }

  Future<void> incrementTransactions() async {
    final current = state.user;
    if (current == null) return;
    
    final newTransactionId = DateTime.now().millisecondsSinceEpoch.toString();
    final newOrdersList = [...current.orders, newTransactionId];
    
    final newCount = newOrdersList.length;
    final updated = current.copyWith(transactions: newCount);
    
    await ApiService.updateUserTransactions(current.id, newOrdersList);
    
    state = state.copyWith(user: updated);
    await _persistSession(isAuth: true, user: updated);
  }
}

final authStateProvider = StateNotifierProvider<AuthController, AuthState>((ref) => AuthController());