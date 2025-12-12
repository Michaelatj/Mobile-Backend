import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/services/firebase_analytics_nonblocking.dart';
import '../../core/state/auth_state.dart';
import '../../core/services/firebase_analytics_service.dart';
import '../../core/services/user_api_service.dart' as api_service;
import '../../core/models/user_role.dart';
import '../home/home_page.dart';
import '../partner/partner_dashboard_page.dart';
import '../../core/services/firestore_service.dart';

class LoginPage extends ConsumerStatefulWidget {
  static const routePath = '/auth/login';
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _isGoogleLoading = false;
  bool _isFacebookLoading = false;
  bool _rememberMe = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadRememberedUser();
  }

  Future<void> _loadRememberedUser() async {
    final prefs = await SharedPreferences.getInstance();
    final remembered = prefs.getBool('rememberMe') ?? false;
    final savedEmail = prefs.getString('savedEmail') ?? '';
    final savedPassword = prefs.getString('savedPassword') ?? '';

    setState(() {
      _rememberMe = remembered;
      if (_rememberMe) {
        _email.text = savedEmail;
        _password.text = savedPassword;
      }
    });
  }

  Future<void> _saveRememberMe() async {
    final prefs = await SharedPreferences.getInstance();
    if (_rememberMe) {
      await prefs.setBool('rememberMe', true);
      await prefs.setString('savedEmail', _email.text);
      await prefs.setString('savedPassword', _password.text);
    } else {
      await prefs.clear();
    }
  }

  Future<void> _handleLogin() async {
    // Validate form (only checks non-empty fields)
    if (!_formKey.currentState!.validate()) return;

    final email = _email.text.trim();
    final password = _password.text;

    setState(() => _isLoading = true);
    try {
      // 1. Sign in via Firebase Auth
      final userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);
      final firebaseUser = userCredential.user!;

      // 2. AMBIL DATA DARI FIRESTORE 📥
      final userData = await FirestoreService.getUser(firebaseUser.uid);

      // Default role jika data belum ada di Firestore (misal user lama)
      UserRole role = UserRole.customer;
      String name = firebaseUser.displayName ?? 'Pengguna';
      String? photoUrl = firebaseUser.photoURL;
      String? locationLabel;

      if (userData != null) {
        final roleString = userData['role'] as String? ?? 'customer';
        role = roleString == 'provider' ? UserRole.provider : UserRole.customer;
        name = userData['name'] as String? ?? name;
        photoUrl = userData['photoUrl'] as String? ?? photoUrl;
        locationLabel = userData['locationLabel'] as String?;
      }

      // 3. Update App State (Riverpod)
      final appUser = AppUser(
        id: firebaseUser.uid,
        name: name,
        role: role,
        photoUrl: photoUrl,
        locationLabel: locationLabel,
      );

      // 3. Persist session and update app auth state
      final auth = ref.read(authStateProvider.notifier);
      await auth.loginWithAppUser(appUser);

      // 4. Save remember me preference
      await _saveRememberMe();

      // 5. Non-blocking analytics
      FirebaseAnalyticsNonBlocking.logLoginEvent(
        userId: firebaseUser.uid,
        email: firebaseUser.email ?? email,
        loginMethod: 'email',
      );

      if (mounted) {
        // Navigate based on role: providers land on partner dashboard
        final target = appUser.role == UserRole.provider
            ? PartnerDashboardPage.routePath
            : HomePage.routePath;
        context.go(target);
      }
    } on FirebaseAuthException catch (e) {
      String message;
      switch (e.code) {
        case 'invalid-email':
          message = 'Format email tidak valid.';
          break;
        case 'user-not-found':
          message = 'Email tidak terdaftar. Silakan daftar dulu.';
          break;
        case 'wrong-password':
          message = 'Password salah. Coba lagi.';
          break;
        case 'user-disabled':
          message = 'Akun dinonaktifkan. Hubungi support.';
          break;
        case 'too-many-requests':
          message = 'Terlalu banyak percobaan. Coba lagi nanti.';
          break;
        default:
          message = e.message ?? 'Gagal login.';
      }
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(message)));
    } catch (e) {
      debugPrint('ERROR: Login failed: $e');
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Gagal login: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: const Color(0xFFEFF3F6),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    SizedBox(
                      height: 360,
                      width: double.infinity,
                      child: Container(
                        color: const Color(0xFFEFF3F6),
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        alignment: Alignment.center,
                        child: Image.network(
                          'https://hebbkx1anhila5yf.public.blob.vercel-storage.com/updatelogo-KxlsSB5MgWvC12jZ7IPWyhAKUem5Ok.png',
                          fit: BoxFit.contain,
                          height: 280,
                          width: double.infinity,
                          filterQuality: FilterQuality.high,
                          alignment: Alignment.center,
                        ),
                      ),
                    ),
                    Transform.translate(
                      offset: const Offset(0, -56),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 520),
                            child: Card(
                              elevation: 18,
                              shadowColor: Colors.black.withOpacity(0.16),
                              surfaceTintColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(24),
                              ),
                              clipBehavior: Clip.antiAlias,
                              color: Colors.white,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 24,
                                ),
                                child: Form(
                                  key: _formKey,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      Text(
                                        'Welcome Back!',
                                        textAlign: TextAlign.center,
                                        style:
                                            textTheme.headlineSmall?.copyWith(
                                          fontWeight: FontWeight.w800,
                                          color: Colors.black,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Log in to find your next service provider.',
                                        textAlign: TextAlign.center,
                                        style: textTheme.bodyMedium?.copyWith(
                                          color: Colors.black87,
                                        ),
                                      ),
                                      const SizedBox(height: 24),
                                      _InputField(
                                        controller: _email,
                                        hintText: 'Email',
                                        textInputType:
                                            TextInputType.emailAddress,
                                        validator: (v) =>
                                            (v == null || v.isEmpty)
                                                ? 'Wajib diisi'
                                                : null,
                                        prefixIcon: Icons.alternate_email,
                                      ),
                                      const SizedBox(height: 12),
                                      _InputField(
                                        controller: _password,
                                        hintText: 'Password',
                                        obscure: true,
                                        validator: (v) =>
                                            (v == null || v.length < 6)
                                                ? 'Minimal 6 karakter'
                                                : null,
                                        prefixIcon: Icons.lock_outline,
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Row(
                                            children: [
                                              Checkbox(
                                                value: _rememberMe,
                                                onChanged: (value) {
                                                  setState(() {
                                                    _rememberMe =
                                                        value ?? false;
                                                  });
                                                },
                                              ),
                                              const Text(
                                                'Remember me',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.w500,
                                                  color: Colors.black87,
                                                ),
                                              ),
                                            ],
                                          ),
                                          TextButton(
                                            onPressed: () {
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(
                                                const SnackBar(
                                                  content: Text(
                                                      'Fitur lupa password coming soon'),
                                                ),
                                              );
                                            },
                                            child:
                                                const Text('Forgot password?'),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      SizedBox(
                                        height: 56,
                                        child: FilledButton(
                                          style: FilledButton.styleFrom(
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                            ),
                                            textStyle: const TextStyle(
                                              fontWeight: FontWeight.w800,
                                              fontSize: 16,
                                            ),
                                          ),
                                          onPressed:
                                              _isLoading ? null : _handleLogin,
                                          child: _isLoading
                                              ? const SizedBox(
                                                  width: 20,
                                                  height: 20,
                                                  child:
                                                      CircularProgressIndicator(),
                                                )
                                              : const Text('Log In'),
                                        ),
                                      ),
                                      const SizedBox(height: 24),
                                      _LabeledDivider(
                                          label: 'Or continue with'),
                                      const SizedBox(height: 16),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: _SocialButton(
                                              label: 'Google',
                                              icon: Icons.g_translate,
                                              onPressed: _isGoogleLoading
                                                  ? () {}
                                                  : () async {
                                                      setState(() =>
                                                          _isGoogleLoading =
                                                              true);
                                                      try {
                                                        final auth = ref.read(
                                                            authStateProvider
                                                                .notifier);
                                                        await auth
                                                            .loginWithGoogle();

                                                        // Log analytics: Google login clicked
                                                        final authState = ref.read(
                                                            authStateProvider);
                                                        final userId = authState
                                                                .user?.id ??
                                                            'unknown';
                                                        await FirebaseAnalyticsService
                                                            .logLoginEvent(
                                                          userId: userId,
                                                          loginMethod: 'google',
                                                        );

                                                        if (mounted) {
                                                          final authState =
                                                              ref.read(
                                                                  authStateProvider);
                                                          final target = authState
                                                                      .user
                                                                      ?.role ==
                                                                  UserRole
                                                                      .provider
                                                              ? PartnerDashboardPage
                                                                  .routePath
                                                              : HomePage
                                                                  .routePath;
                                                          context.go(target);
                                                        }
                                                      } finally {
                                                        if (mounted) {
                                                          setState(() =>
                                                              _isGoogleLoading =
                                                                  false);
                                                        }
                                                      }
                                                    },
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: _SocialButton(
                                              label: 'Facebook',
                                              icon: Icons.facebook,
                                              onPressed: _isFacebookLoading
                                                  ? () {}
                                                  : () async {
                                                      setState(() =>
                                                          _isFacebookLoading =
                                                              true);
                                                      try {
                                                        final auth = ref.read(
                                                            authStateProvider
                                                                .notifier);
                                                        await auth
                                                            .loginWithFacebook();

                                                        // Log analytics: Facebook login clicked
                                                        final authState = ref.read(
                                                            authStateProvider);
                                                        final userId = authState
                                                                .user?.id ??
                                                            'unknown';
                                                        await FirebaseAnalyticsService
                                                            .logLoginEvent(
                                                          userId: userId,
                                                          loginMethod:
                                                              'facebook',
                                                        );

                                                        if (mounted) {
                                                          final authState =
                                                              ref.read(
                                                                  authStateProvider);
                                                          final target = authState
                                                                      .user
                                                                      ?.role ==
                                                                  UserRole
                                                                      .provider
                                                              ? PartnerDashboardPage
                                                                  .routePath
                                                              : HomePage
                                                                  .routePath;
                                                          context.go(target);
                                                        }
                                                      } finally {
                                                        if (mounted) {
                                                          setState(() =>
                                                              _isFacebookLoading =
                                                                  false);
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
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: textTheme.bodySmall?.copyWith(
                    color: cs.primary.withOpacity(0.7),
                  ),
                  children: [
                    const TextSpan(text: "Don't have an account? "),
                    WidgetSpan(
                      alignment: PlaceholderAlignment.middle,
                      child: InkWell(
                        onTap: () => context.go('/auth/register'),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 4, vertical: 2),
                          child: Text(
                            'Register now',
                            style: textTheme.bodySmall?.copyWith(
                              color: cs.primary,
                              fontWeight: FontWeight.w700,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InputField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final String? Function(String?)? validator;
  final bool obscure;
  final TextInputType? textInputType;
  final IconData? prefixIcon;

  const _InputField({
    required this.controller,
    required this.hintText,
    this.validator,
    this.obscure = false,
    this.textInputType,
    this.prefixIcon,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      keyboardType: textInputType,
      validator: validator,
      style: const TextStyle(color: Colors.black),
      decoration: InputDecoration(
        hintText: hintText,
        filled: true,
        fillColor: Theme.of(context).brightness == Brightness.dark
            ? cs.surfaceVariant.withOpacity(0.25)
            : cs.surfaceVariant.withOpacity(0.5),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        prefixIcon: prefixIcon == null
            ? null
            : Icon(prefixIcon, color: cs.primary.withOpacity(0.7)),
        border: OutlineInputBorder(
          borderSide: BorderSide.none,
          borderRadius: BorderRadius.circular(14),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: cs.primary, width: 2),
          borderRadius: BorderRadius.circular(14),
        ),
        hintStyle: const TextStyle(
          color: Colors.black54,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _LabeledDivider extends StatelessWidget {
  final String label;
  const _LabeledDivider({required this.label});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Row(
      children: [
        Expanded(child: Divider(color: cs.primary.withOpacity(0.2))),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            label,
            style: textTheme.bodySmall?.copyWith(
              color: cs.primary.withOpacity(0.7),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(child: Divider(color: cs.primary.withOpacity(0.2))),
      ],
    );
  }
}

class _SocialButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  const _SocialButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SizedBox(
      height: 48,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, color: cs.primary),
        label: Text(
          label,
          style: TextStyle(
            color: cs.primary,
            fontWeight: FontWeight.w700,
          ),
        ),
        style: OutlinedButton.styleFrom(
          backgroundColor: Theme.of(context).brightness == Brightness.dark
              ? cs.surfaceVariant.withOpacity(0.2)
              : cs.surfaceVariant.withOpacity(0.6),
          side: BorderSide(color: cs.primary.withOpacity(0.16)),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          foregroundColor: cs.primary,
        ),
      ),
    );
  }
}
