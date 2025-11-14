import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'login_page.dart';
import 'register_page.dart';

class OnboardingPage extends StatefulWidget {
  static const routePath = '/';
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final _controller = PageController();
  int _page = 0;

  static const _logoUrl = 'https://hebbkx1anhila5yf.public.blob.vercel-storage.com/updatelogo-KxlsSB5MgWvC12jZ7IPWyhAKUem5Ok.png';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _next() {
    if (_page < 2) {
      _controller.animateToPage(
        _page + 1,
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Slides
                    Flexible(
                      child: PageView(
                        controller: _controller,
                        onPageChanged: (i) => setState(() => _page = i),
                        children: const [
                          _OnboardSlide(
                            title: 'Welcome to BayangIn',
                            subtitle:
                                'Find trusted service providers in your neighborhood for all your needs.',
                            logoUrl: _logoUrl,
                          ),
                          _OnboardSlide(
                            title: 'Find trusted service providers',
                            subtitle:
                                'BayangIn connects you with skilled professionals nearby—fast and reliable.',
                            logoUrl: _logoUrl,
                          ),
                          _OnboardSlide(
                            title:
                                'Find the right service provider for your needs',
                            subtitle:
                                'Connect with trusted professionals and enjoy the convenience and security of our platform.',
                            logoUrl: _logoUrl,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Dots indicator
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(3, (i) {
                        final active = i == _page;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 220),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          height: 8,
                          width: active ? 20 : 8,
                          decoration: BoxDecoration(
                            color:
                                active ? cs.primary : cs.primary.withOpacity(0.25),
                            borderRadius: BorderRadius.circular(999),
                          ),
                        );
                      }),
                    ),

                    const SizedBox(height: 20),

                    // CTAs
                    if (_page < 2) ...[
                      FilledButton(
                        onPressed: _next,
                        style: FilledButton.styleFrom(
                          minimumSize: Size(double.infinity, 52),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          textStyle: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                        child: Text(_page == 0 ? 'Get Started' : 'Next'),
                      ),
                    ] else ...[
                      FilledButton(
                        onPressed: () => context.go(RegisterPage.routePath),
                        style: FilledButton.styleFrom(
                          minimumSize: Size(double.infinity, 52),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          textStyle: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                        child: const Text('Sign up'),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton(
                        onPressed: () => context.go(LoginPage.routePath),
                        style: OutlinedButton.styleFrom(
                          minimumSize: Size(double.infinity, 52),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          side: BorderSide(color: cs.primary, width: 1.2),
                          textStyle: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                        child: const Text('Log in'),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _OnboardSlide extends StatelessWidget {
  final String title;
  final String subtitle;
  final String logoUrl;
  const _OnboardSlide({
    required this.title,
    required this.subtitle,
    required this.logoUrl,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Column(
      children: [
        Container(
          height: 320, // was 260
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
          ),
          alignment: Alignment.center,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Image.network(
              logoUrl,
              fit: BoxFit.contain,
              width: 280, // was 240
              height: 280, // was 240
              loadingBuilder: (context, child, prog) =>
                  prog == null
                      ? child
                      : const SizedBox(
                          width: 28,
                          height: 28,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
              errorBuilder: (context, error, stack) => Icon(
                Icons.image_not_supported_outlined,
                size: 32,
                color: cs.primary,
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          title,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                color: Theme.of(context).colorScheme.onSurface,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                height: 1.5,
              ),
        ),
      ],
    );
  }
}
