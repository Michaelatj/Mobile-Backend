import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/state/auth_state.dart';
import 'login_page.dart';
import 'provider_onboarding_page.dart';
import '../../core/database/user_dao.dart';
import '../../core/services/user_api_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/services/firebase_analytics_nonblocking.dart';
import '../../core/services/firestore_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // <--- Add this line!

class RegisterPage extends ConsumerStatefulWidget {
  static const routePath = '/auth/register';
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _fullName = TextEditingController();
  final _confirmPassword = TextEditingController();
  String _selectedRole = 'customer';
  bool _isLoading = false;

  bool get _isProvider => _selectedRole == 'provider';
  bool get _isCustomer => _selectedRole == 'customer';

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _fullName.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  Future<void> _handleRegisterCustomer() async {
  // 1. Basic Form Validation
  if (!_formKey.currentState!.validate()) return;

  // 2. Get values
  final email = _email.text.trim();
  final password = _password.text;
  final confirmPassword = _confirmPassword.text;
  final fullname = _fullName.text.trim().isEmpty ? 'Pengguna' : _fullName.text.trim();

  // 3. Email Regex Validation
  final emailRegex = RegExp(r'^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$');
  if (!emailRegex.hasMatch(email)) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Format email tidak sesuai.')),
    );
    return;
  }

  // 4. Password Length Validation
  if (password.length < 6) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Password terlalu pendek (min 6 karakter).')),
    );
    return;
  }

  // 5. Password Match Validation
  if (password != confirmPassword) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Passwords do not match')),
    );
    return;
  }

  // Start Loading
  setState(() => _isLoading = true);

  try {
    print("---- 1. MULAI REGISTER ----");

    // --------------------------
    // STEP A: Create User (Auth)
    // --------------------------
    final userCredential = await FirebaseAuth.instance
        .createUserWithEmailAndPassword(email: email, password: password);
    final firebaseUser = userCredential.user!;
    
    // Update Display Name
    await firebaseUser.updateDisplayName(fullname);

    print("---- 2. AUTH BERHASIL: ${firebaseUser.uid} ----");

    // --------------------------
    // STEP B: Save to Firestore
    // --------------------------
    print("---- 3. MENYIMPAN KE FIRESTORE... ----");
    
    // We write directly to the 'users' collection
    await FirebaseFirestore.instance.collection('users').doc(firebaseUser.uid).set({
      'uid': firebaseUser.uid,
      'email': email,
      'name': fullname,
      'role': _selectedRole, // 'customer'
      'createdAt': FieldValue.serverTimestamp(),
    });

    print("---- 4. SUKSES SIMPAN KE FIRESTORE! ----");

    // --------------------------
    // STEP C: Save to SQLite (Local)
    // --------------------------
    final id = firebaseUser.uid; 
    await UserDao.insertUser({
      'id': id,
      'name': fullname,
      'email': email,
      'role': _selectedRole,
      'firebaseUid': firebaseUser.uid,
      'createdAt': DateTime.now().toIso8601String(),
    });

    // --------------------------
    // STEP D: Analytics
    // --------------------------
    FirebaseAnalyticsNonBlocking.logLoginEvent(
      userId: firebaseUser.uid,
      email: email,
      loginMethod: 'email-register',
    );

    // --------------------------
    // STEP E: Navigate
    // --------------------------
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Register berhasil. Silakan login.'))
      );
      context.go(LoginPage.routePath);
    }

  } on FirebaseAuthException catch (e) {
    // Handle specific Firebase Auth errors
    String message;
    switch (e.code) {
      case 'invalid-email':
        message = 'Format email tidak valid.';
        break;
      case 'weak-password':
        message = 'Password terlalu pendek (min 6 karakter).';
        break;
      case 'email-already-in-use':
        message = 'Email sudah terdaftar. Silakan login.';
        break;
      default:
        message = e.message ?? 'Gagal mendaftar.';
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    }
  } catch (e) {
    // Handle General Errors (Including Firestore/Database errors)
    print("!!!! FATAL ERROR: $e !!!!"); // Check your Debug Console for this!
    
    // Rollback: If database failed, delete the auth user so they can try again
    try {
      final current = FirebaseAuth.instance.currentUser;
      if (current != null) {
        await current.delete();
        debugPrint('DEBUG: Rolled back Firebase user after failure');
      }
    } catch (rollErr) {
      debugPrint('WARN: Failed to rollback Firebase user: $rollErr');
    }
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal register: $e'))
      );
    }
  } finally {
    if (mounted) setState(() => _isLoading = false);
  }
}

  Future<void> _handleRegisterProvider() async {
    // First, basic non-empty form validation
    if (!_formKey.currentState!.validate()) return;

    // Then run the same sequential client-side validations used for customers
    final email = _email.text.trim();
    final password = _password.text;
    final confirmPassword = _confirmPassword.text;
    final fullname =
        _fullName.text.trim().isEmpty ? 'Pengguna' : _fullName.text.trim();

    final emailRegex =
        RegExp(r'^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$');
    if (!emailRegex.hasMatch(email)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Format email tidak sesuai.')),
      );
      return;
    }

    if (password.length < 6) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Password terlalu pendek (min 6 karakter).')),
      );
      return;
    }

    if (password != confirmPassword) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      // 1. Create User di Firebase Auth
      final userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);
      final firebaseUser = userCredential.user!;
      await firebaseUser.updateDisplayName(fullname);

      // 2. SIMPAN KE FIRESTORE (Pengganti UserApiService/UserDao lama) 🚀
      // Kita import FirestoreService yang baru dibuat di atas
      await FirestoreService.saveUser(
        uid: firebaseUser.uid,
        email: email,
        name: fullname,
        role: _selectedRole,
      );

      final id = firebaseUser.uid; 
      
      await UserDao.insertUser({
        'id': id,
        'name': fullname,
        'email': email,
        'role': _selectedRole, // Sesuaikan dengan variabel role kamu (customer/provider)
        'firebaseUid': firebaseUser.uid,
        'createdAt': DateTime.now().toIso8601String(),
      });

      // Non-blocking analytics
      FirebaseAnalyticsNonBlocking.logLoginEvent(
        userId: firebaseUser.uid,
        email: email,
        loginMethod: 'email-register-provider',
      );

      if (mounted) {
        // Move to provider onboarding details page
        context.go(ProviderOnboardingPage.routePath);
      }
    } on FirebaseAuthException catch (e) {
      String message;
      switch (e.code) {
        case 'invalid-email':
          message = 'Format email tidak valid.';
          break;
        case 'weak-password':
          message = 'Password terlalu pendek (min 6 karakter).';
          break;
        case 'email-already-in-use':
          message = 'Email sudah terdaftar. Silakan login.';
          break;
        default:
          message = e.message ?? 'Gagal mendaftar.';
      }
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(message)));
      }
    } catch (e) {
      // If API creation failed after Firebase creation, attempt rollback
      try {
        final current = FirebaseAuth.instance.currentUser;
        if (current != null) {
          await current.delete();
          debugPrint('DEBUG: Rolled back Firebase user after API failure');
        }
      } catch (rollErr) {
        debugPrint('WARN: Failed to rollback Firebase user: $rollErr');
      }
      debugPrint('ERROR: Provider register unexpected error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Gagal register: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    const logoUrl =
        'https://hebbkx1anhila5yf.public.blob.vercel-storage.com/updatelogo-KxlsSB5MgWvC12jZ7IPWyhAKUem5Ok.png';

    return Scaffold(
      backgroundColor: const Color(0xFFEFF3F6),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              SizedBox(
                height: 360,
                width: double.infinity,
                child: Container(
                  alignment: Alignment.center,
                  child: Image.network(
                    logoUrl,
                    height: 280,
                    width: double.infinity,
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.high,
                  ),
                ),
              ),
              Transform.translate(
                offset: const Offset(0, -56),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 560),
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(22),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.10),
                              blurRadius: 28,
                              offset: const Offset(0, 12),
                            ),
                          ],
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                'Create your account',
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: Colors.black,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Join BayangIn to book or offer trusted services.',
                                textAlign: TextAlign.center,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 16),
                              _RoleOption(
                                label: "I'm looking for services",
                                value: 'customer',
                                groupValue: _selectedRole,
                                onChanged: (v) =>
                                    setState(() => _selectedRole = v!),
                                primary: cs.primary,
                                theme: theme,
                              ),
                              const SizedBox(height: 10),
                              _RoleOption(
                                label: 'I offer services',
                                value: 'provider',
                                groupValue: _selectedRole,
                                onChanged: (v) =>
                                    setState(() => _selectedRole = v!),
                                primary: cs.primary,
                                theme: theme,
                              ),
                              const SizedBox(height: 18),
                              _InputField(
                                controller: _fullName,
                                hintText: 'Full name',
                                keyboardType: TextInputType.name,
                                validator: (v) => (v == null || v.isEmpty)
                                    ? 'Please enter your name'
                                    : null,
                                theme: theme,
                                prefixIcon: Icons.person_outline,
                              ),
                              const SizedBox(height: 12),
                              _InputField(
                                controller: _email,
                                hintText: 'Email',
                                keyboardType: TextInputType.emailAddress,
                                validator: (v) => (v == null || v.isEmpty)
                                    ? 'Please enter your email'
                                    : null,
                                theme: theme,
                                prefixIcon: Icons.alternate_email,
                              ),
                              const SizedBox(height: 12),
                              _InputField(
                                controller: _password,
                                hintText: 'Password',
                                obscureText: true,
                                validator: (v) => (v == null || v.isEmpty)
                                    ? 'Please enter a password'
                                    : null,
                                theme: theme,
                                prefixIcon: Icons.lock_outline,
                              ),
                              const SizedBox(height: 12),
                              _InputField(
                                controller: _confirmPassword,
                                hintText: 'Confirm password',
                                obscureText: true,
                                validator: (v) => (v == null || v.isEmpty)
                                    ? 'Please confirm your password'
                                    : null,
                                theme: theme,
                                prefixIcon: Icons.verified_user_outlined,
                              ),
                              const SizedBox(height: 20),
                              if (_isCustomer) ...[
                                SizedBox(
                                  height: 52,
                                  child: FilledButton(
                                    onPressed: _isLoading
                                        ? null
                                        : _handleRegisterCustomer,
                                    style: FilledButton.styleFrom(
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12)),
                                      textStyle: const TextStyle(fontSize: 16),
                                      elevation: 1,
                                    ),
                                    child: _isLoading
                                        ? const SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(),
                                          )
                                        : const Text('Register'),
                                  ),
                                ),
                              ] else ...[
                                SizedBox(
                                  height: 52,
                                  child: FilledButton(
                                    onPressed: _isLoading
                                        ? null
                                        : _handleRegisterProvider,
                                    style: FilledButton.styleFrom(
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(14)),
                                      textStyle: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 16),
                                      elevation: 1,
                                    ),
                                    child: _isLoading
                                        ? const SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(),
                                          )
                                        : const Text('Next'),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: cs.primary.withOpacity(0.7),
                    ),
                    children: [
                      const TextSpan(text: 'Already have an account? '),
                      WidgetSpan(
                        alignment: PlaceholderAlignment.middle,
                        child: InkWell(
                          onTap: () => context.go('/auth/login'),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 4, vertical: 2),
                            child: Text(
                              'Log In',
                              style: theme.textTheme.bodySmall?.copyWith(
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
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text.rich(
                  TextSpan(
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: Colors.grey[600]),
                    children: [
                      const TextSpan(text: 'By continuing, you agree to our '),
                      TextSpan(
                        text: 'Terms of Service',
                        style: TextStyle(
                            color: cs.primary, fontWeight: FontWeight.w600),
                      ),
                      const TextSpan(text: ' and '),
                      TextSpan(
                        text: 'Privacy Policy',
                        style: TextStyle(
                            color: cs.primary, fontWeight: FontWeight.w600),
                      ),
                      const TextSpan(text: '.'),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InputField extends StatelessWidget {
  const _InputField({
    required this.controller,
    required this.hintText,
    required this.theme,
    this.obscureText = false,
    this.validator,
    this.keyboardType,
    this.prefixIcon,
  });

  final TextEditingController controller;
  final String hintText;
  final bool obscureText;
  final FormFieldValidator<String>? validator;
  final TextInputType? keyboardType;
  final ThemeData theme;
  final IconData? prefixIcon;

  @override
  Widget build(BuildContext context) {
    final cs = theme.colorScheme;
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      validator: validator,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.black),
      decoration: InputDecoration(
        hintText: hintText,
        isDense: true,
        filled: true,
        fillColor: cs.surfaceVariant.withOpacity(0.25),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        prefixIcon: prefixIcon == null
            ? null
            : Icon(prefixIcon, color: cs.primary.withOpacity(0.7)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.withOpacity(0.4)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.withOpacity(0.35)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: cs.primary, width: 1.4),
        ),
        hintStyle: const TextStyle(color: Colors.black54),
      ),
    );
  }
}

class _RoleOption extends StatelessWidget {
  const _RoleOption({
    required this.label,
    required this.value,
    required this.groupValue,
    required this.onChanged,
    required this.primary,
    required this.theme,
  });

  final String label;
  final String value;
  final String? groupValue;
  final ValueChanged<String?> onChanged;
  final Color primary;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final isSelected = value == groupValue;
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => onChanged(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: isSelected ? primary.withOpacity(0.08) : Colors.white,
          border: Border.all(
            color: isSelected ? primary : Colors.grey.withOpacity(0.4),
            width: 1,
          ),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
          ],
        ),
        child: Row(
          children: [
            Radio<String>(
              value: value,
              groupValue: groupValue,
              onChanged: onChanged,
              activeColor: primary,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
