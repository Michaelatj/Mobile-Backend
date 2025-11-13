import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_role.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../database/user_dao.dart';

class AuthState {
  final bool isAuthenticated;
  final AppUser? user;

  const AuthState({required this.isAuthenticated, this.user});

  AuthState copyWith({bool? isAuthenticated, AppUser? user}) => AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      user: user ?? this.user);

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

    // PATCH: ambil email dari prefs, cek ke DB
    final email = prefs.getString('savedEmail');
    String userId = 'session';
    if (email != null && email.isNotEmpty) {
      final dbUser = await UserDao.findUserByEmail(email);
      if (dbUser != null) {
        userId = dbUser['id'] as String? ?? 'session';
      }
    }

    state = AuthState(
      isAuthenticated: true,
      user: AppUser(
        id: userId,
        name: name,
        role: role,
        photoUrl: photoUrl,
        locationLabel: locationLabel,
      ),
    );
  }

  Future<void> _persistSession({required bool isAuth, AppUser? user}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kIsAuth, isAuth);
    if (isAuth && user != null) {
      await prefs.setString(_kUserName, user.name);
      await prefs.setString(
          _kUserRole, user.role == UserRole.provider ? 'provider' : 'customer');
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
    return AppUser(
      id: fallbackId,
      name: name,
      role: role,
      photoUrl: photoUrl,
      locationLabel: locationLabel,
    );
  }

  Future<void> loginWithEmail(String email, String password) async {
    // try read user from DB
    try {
      final userMap = await UserDao.findUser(email, password);
      if (userMap != null) {
        final roleStr = (userMap['role'] as String?) ?? 'customer';
        final role =
            roleStr == 'provider' ? UserRole.provider : UserRole.customer;
        final appUser = AppUser(
          id: userMap['id'] as String,
          name: (userMap['name'] as String?) ?? 'Pengguna',
          role: role,
          photoUrl: userMap['photoUrl'] as String?,
          locationLabel: userMap['locationLabel'] as String?,
        );
        state = AuthState(isAuthenticated: true, user: appUser);
        await _persistSession(isAuth: true, user: appUser);
        return;
      }
    } catch (_) {
      // fallthrough to prefs fallback
    }

    // fallback (previous behaviour) — keep for safety
    final user =
        await _buildUserFromPrefs(fallbackId: 'u1', fallbackName: 'Pengguna');
    state = AuthState(isAuthenticated: true, user: user);
    await _persistSession(isAuth: true, user: user);
  }

  Future<void> loginWithGoogle() async {
    final user = await _buildUserFromPrefs(
        fallbackId: 'uG', fallbackName: 'Google User');
    state = AuthState(isAuthenticated: true, user: user);
    await _persistSession(isAuth: true, user: user);
  }

  Future<void> loginWithFacebook() async {
    final user = await _buildUserFromPrefs(
        fallbackId: 'uF', fallbackName: 'Facebook User');
    state = AuthState(isAuthenticated: true, user: user);
    await _persistSession(isAuth: true, user: user);
  }

  Future<void> register(String email, String password) async {
    final user =
        await _buildUserFromPrefs(fallbackId: 'u2', fallbackName: 'Akun Baru');
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

  Future<void> logout() async {
    state = AuthState.unauthenticated;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kIsAuth, false);
    // Keep user profile fields (_kUserName, _kUserRole, _kUserPhotoUrl, _kUserLocation)
    // so they remain available when user logs in again.
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
      locationLabel: locationLabel?.trim().isNotEmpty == true
          ? locationLabel
          : current.locationLabel,
      photoUrl: (photoUrl != null && photoUrl.trim().isNotEmpty)
          ? photoUrl
          : photoUrl == ''
              ? null
              : current.photoUrl,
    );

    // PATCH: update users table in DB
    await UserDao.updateUserProfile(
      id: current.id,
      name: updated.name,
      locationLabel: updated.locationLabel,
      photoUrl: updated.photoUrl,
    );

    state = state.copyWith(user: updated);
    await _persistSession(isAuth: true, user: updated);
  }
}

final authStateProvider =
    StateNotifierProvider<AuthController, AuthState>((ref) => AuthController());
