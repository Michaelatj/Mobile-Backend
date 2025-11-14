import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/state/auth_state.dart';
import 'role_selection_page.dart';
import 'login_page.dart';
import 'provider_onboarding_page.dart';
import '../../core/models/user_role.dart';

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
  bool _isLoading = false; // Add loading state
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

  @override
  Widget build(BuildContext context) {
    final auth = ref.read(authStateProvider.notifier);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    const logoUrl = 'https://hebbkx1anhila5yf.public.blob.vercel-storage.com/updatelogo-KxlsSB5MgWvC12jZ7IPWyhAKUem5Ok.png';

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
                                onChanged: (v) => setState(() => _selectedRole = v!),
                                primary: cs.primary,
                                theme: theme,
                              ),
                              const SizedBox(height: 10),
                              _RoleOption(
                                label: 'I offer services',
                                value: 'provider',
                                groupValue: _selectedRole,
                                onChanged: (v) => setState(() => _selectedRole = v!),
                                primary: cs.primary,
                                theme: theme,
                              ),
                              const SizedBox(height: 18),
                              _InputField(
                                controller: _fullName,
                                hintText: 'Full name',
                                keyboardType: TextInputType.name,
                                validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                                theme: theme,
                                prefixIcon: Icons.person_outline,
                              ),
                              const SizedBox(height: 12),
                              _InputField(
                                controller: _email,
                                hintText: 'Email',
                                keyboardType: TextInputType.emailAddress,
                                validator: (v) =>
                                    (v == null || v.isEmpty || !v.contains('@')) ? 'Enter a valid email' : null,
                                theme: theme,
                                prefixIcon: Icons.alternate_email,
                              ),
                              const SizedBox(height: 12),
                              _InputField(
                                controller: _password,
                                hintText: 'Password',
                                obscureText: true,
                                validator: (v) => (v == null || v.length < 6) ? 'At least 6 characters' : null,
                                theme: theme,
                                prefixIcon: Icons.lock_outline,
                              ),
                              const SizedBox(height: 12),
                              _InputField(
                                controller: _confirmPassword,
                                hintText: 'Confirm password',
                                obscureText: true,
                                validator: (v) => (v != _password.text) ? 'Passwords do not match' : null,
                                theme: theme,
                                prefixIcon: Icons.verified_user_outlined,
                              ),
                              const SizedBox(height: 20),
                              if (_isCustomer) ...[
                                SizedBox(
                                  height: 52,
                                  child: FilledButton(
                                    onPressed: _isLoading ? null : () async {
                                      if (_formKey.currentState!.validate()) {
                                        setState(() => _isLoading = true);
                                        try {
                                          final success = await auth.register(
                                            _email.text,
                                            _password.text,
                                            _fullName.text,
                                            'customer',
                                          );
                                          if (mounted) {
                                            if (success) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                const SnackBar(
                                                  content: Text('Registrasi berhasil! Silakan login dengan akun Anda.'),
                                                  backgroundColor: Colors.green,
                                                ),
                                              );
                                              context.go(LoginPage.routePath);
                                            } else {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                const SnackBar(
                                                  content: Text('Registrasi gagal. Email mungkin sudah terdaftar.'),
                                                  backgroundColor: Colors.red,
                                                ),
                                              );
                                            }
                                          }
                                        } finally {
                                          if (mounted) {
                                            setState(() => _isLoading = false);
                                          }
                                        }
                                      }
                                    },
                                    style: FilledButton.styleFrom(
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                      textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                                      elevation: 1,
                                    ),
                                    child: _isLoading
                                        ? SizedBox(
                                            height: 24,
                                            width: 24,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor: AlwaysStoppedAnimation<Color>(
                                                Theme.of(context).colorScheme.onPrimary,
                                              ),
                                            ),
                                          )
                                        : const Text('Register'),
                                  ),
                                ),
                              ] else ...[
                                SizedBox(
                                  height: 52,
                                  child: FilledButton(
                                    onPressed: () {
                                      if (_formKey.currentState!.validate()) {
                                        context.go(ProviderOnboardingPage.routePath);
                                      }
                                    },
                                    style: FilledButton.styleFrom(
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                      textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                                      elevation: 1,
                                    ),
                                    child: const Text('Next'),
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
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text.rich(
                  TextSpan(
                    style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                    children: [
                      const TextSpan(text: 'By continuing, you agree to our '),
                      TextSpan(
                        text: 'Terms of Service',
                        style: TextStyle(color: cs.primary, fontWeight: FontWeight.w600),
                      ),
                      const TextSpan(text: ' and '),
                      TextSpan(
                        text: 'Privacy Policy',
                        style: TextStyle(color: cs.primary, fontWeight: FontWeight.w600),
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
    this.prefixIcon, // 
  });

  final TextEditingController controller;
  final String hintText;
  final bool obscureText;
  final FormFieldValidator<String>? validator;
  final TextInputType? keyboardType;
  final ThemeData theme;
  final IconData? prefixIcon; // 

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
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        prefixIcon: prefixIcon == null
            ? null
            : Icon(prefixIcon, color: cs.primary.withOpacity(0.7)), // 
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
                style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
