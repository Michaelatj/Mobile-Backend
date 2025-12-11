import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart'; // use go_router navigation
import 'login_page.dart';
import '../../core/database/provider_dao.dart';
import '../../core/models/service_provider.dart';
import '../../core/services/user_api_service.dart';
import '../../core/database/user_dao.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/services/firebase_analytics_nonblocking.dart';

class ProviderOnboardingPage extends StatefulWidget {
  static const routePath = '/auth/provider-onboarding';
  const ProviderOnboardingPage({super.key});

  @override
  State<ProviderOnboardingPage> createState() => _ProviderOnboardingPageState();
}

class _ProviderOnboardingPageState extends State<ProviderOnboardingPage> {
  final _formKey = GlobalKey<FormState>();
  final _serviceNameCtrl = TextEditingController();
  final _categoryCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  bool _isSaving = false;

  @override
  void dispose() {
    _serviceNameCtrl.dispose();
    _categoryCtrl.dispose();
    _priceCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _finishRegistration() async {
    if (!_formKey.currentState!.validate()) return;
    if (!mounted) return;

    setState(() => _isSaving = true);
    try {
      // Ensure we have an authenticated Firebase user (created during register)
      final fbUser = FirebaseAuth.instance.currentUser;
      if (fbUser == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content:
                  Text('No authenticated user found. Please log in first.')));
          context.go(LoginPage.routePath);
        }
        return;
      }

      final name = fbUser.displayName ?? 'Provider';
      final email = fbUser.email ?? '';
      final uid = fbUser.uid;

      // Parse price safely
      int priceFrom = int.tryParse(_priceCtrl.text.trim()) ?? 0;

      // Create local provider record
      final providerId = 'p_${DateTime.now().millisecondsSinceEpoch}';
      final serviceProvider = ServiceProvider(
        id: providerId,
        name: _serviceNameCtrl.text.trim().isEmpty
            ? name
            : _serviceNameCtrl.text.trim(),
        category: _categoryCtrl.text.trim().isEmpty
            ? 'General'
            : _categoryCtrl.text.trim(),
        rating: 0.0,
        distanceKm: 0.0,
        description: _descCtrl.text.trim(),
        priceFrom: priceFrom,
      );

      await ProviderDao.insertProvider(serviceProvider);

      // Upsert API user as provider (ensure role and firebaseUid are recorded)
      final apiUser = await UserApiService.createUser(
        name: name,
        email: email,
        role: 'provider',
        firebaseUid: uid,
      );

      // Persist/refresh local user record (do not store plaintext password)
      final userId = apiUser['id'] as String? ?? 'u_$uid';
      await UserDao.insertUser({
        'id': userId,
        'name': name,
        'email': email,
        'role': 'provider',
        'firebaseUid': uid,
        'createdAt': DateTime.now().toIso8601String(),
      });

      // Non-blocking analytics
      FirebaseAnalyticsNonBlocking.logLoginEvent(
        userId: uid,
        email: email,
        loginMethod: 'provider-onboarding',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Provider account set up successfully.')));
        // Navigate to login or home - choose Login to ensure fresh auth flow
        context.go(LoginPage.routePath);
      }
    } catch (e) {
      debugPrint('ERROR: provider onboarding failed: $e');
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to complete onboarding: $e')));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme; // use for consistent input styling
    final cardRadius = BorderRadius.circular(22); // match other pages
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
                  padding: const EdgeInsets.symmetric(horizontal: 24),
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 560),
                      child: Card(
                        color: Colors.white,
                        elevation: 18,
                        shadowColor: Colors.black.withOpacity(0.16),
                        surfaceTintColor: Colors.transparent,
                        shape: RoundedRectangleBorder(borderRadius: cardRadius),
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                const SizedBox(height: 12),
                                Text(
                                  'Set up your service',
                                  style:
                                      theme.textTheme.headlineSmall?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: theme.colorScheme.primary,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Provide a few details to complete your provider account.',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.colorScheme.onSurface
                                        .withOpacity(0.7),
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 24),

                                // Service Name
                                TextFormField(
                                  controller: _serviceNameCtrl,
                                  decoration: InputDecoration(
                                    hintText:
                                        'Service name (e.g. Home Cleaning)',
                                    filled: true,
                                    fillColor:
                                        cs.surfaceVariant.withOpacity(0.25),
                                    prefixIcon: Icon(
                                        Icons.design_services_outlined,
                                        color: cs.primary.withOpacity(0.7)),
                                    border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(14),
                                        borderSide: BorderSide.none),
                                    focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(14),
                                        borderSide: BorderSide(
                                            color: cs.primary, width: 1.4)),
                                  ),
                                  validator: (v) =>
                                      (v == null || v.trim().isEmpty)
                                          ? 'Please enter service name'
                                          : null,
                                ),
                                const SizedBox(height: 12),

                                // Category
                                TextFormField(
                                  controller: _categoryCtrl,
                                  decoration: InputDecoration(
                                    hintText: 'Category (e.g. Cleaning)',
                                    filled: true,
                                    fillColor:
                                        cs.surfaceVariant.withOpacity(0.25),
                                    prefixIcon: Icon(Icons.category_outlined,
                                        color: cs.primary.withOpacity(0.7)),
                                    border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(14),
                                        borderSide: BorderSide.none),
                                    focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(14),
                                        borderSide: BorderSide(
                                            color: cs.primary, width: 1.4)),
                                  ),
                                  validator: (v) =>
                                      (v == null || v.trim().isEmpty)
                                          ? 'Please enter category'
                                          : null,
                                ),
                                const SizedBox(height: 12),

                                // Price
                                TextFormField(
                                  controller: _priceCtrl,
                                  keyboardType: TextInputType.number,
                                  decoration: InputDecoration(
                                    hintText: 'Starting price (e.g. 150000)',
                                    filled: true,
                                    fillColor:
                                        cs.surfaceVariant.withOpacity(0.25),
                                    prefixIcon: Icon(Icons.payments_outlined,
                                        color: cs.primary.withOpacity(0.7)),
                                    border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(14),
                                        borderSide: BorderSide.none),
                                    focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(14),
                                        borderSide: BorderSide(
                                            color: cs.primary, width: 1.4)),
                                  ),
                                  validator: (v) =>
                                      (v == null || v.trim().isEmpty)
                                          ? 'Please enter price'
                                          : null,
                                ),
                                const SizedBox(height: 12),

                                // Description
                                TextFormField(
                                  controller: _descCtrl,
                                  minLines: 3,
                                  maxLines: 5,
                                  decoration: InputDecoration(
                                    hintText:
                                        'Tell customers about your service',
                                    filled: true,
                                    fillColor:
                                        cs.surfaceVariant.withOpacity(0.25),
                                    prefixIcon: Icon(Icons.subject_outlined,
                                        color: cs.primary.withOpacity(0.7)),
                                    border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(14),
                                        borderSide: BorderSide.none),
                                    focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(14),
                                        borderSide: BorderSide(
                                            color: cs.primary, width: 1.4)),
                                  ),
                                  validator: (v) => (v == null ||
                                          v.trim().length < 10)
                                      ? 'Please write at least 10 characters'
                                      : null,
                                ),

                                const SizedBox(height: 24),
                                SizedBox(
                                  height: 52,
                                  child: FilledButton(
                                    onPressed:
                                        _isSaving ? null : _finishRegistration,
                                    style: FilledButton.styleFrom(
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      textStyle: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 16,
                                      ),
                                      elevation: 1,
                                    ),
                                    child: _isSaving
                                        ? const SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(),
                                          )
                                        : const Text('Register'),
                                  ),
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
    );
  }
}
