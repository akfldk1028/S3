import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../../features/onboarding/onboarding_provider.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _onboardingChecked = false;

  @override
  void initState() {
    super.initState();
    _checkOnboarding();
  }

  /// Reads the [onboardingProvider] and redirects to [/onboarding]
  /// if the `onboarding_completed` flag is absent or false.
  ///
  /// A boolean guard [_onboardingChecked] prevents double-execution
  /// (e.g. if initState is called twice).
  Future<void> _checkOnboarding() async {
    if (_onboardingChecked) return;
    _onboardingChecked = true;

    final onboardingState = await ref.read(onboardingProvider.future);

    if (!mounted) return;

    if (!onboardingState) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          context.go('/onboarding');
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Home',
              style: ShadTheme.of(context).textTheme.h1,
            ),
            const SizedBox(height: 16),
            ShadButton(
              onPressed: () => context.push('/profile'),
              child: const Text('Go to Profile'),
            ),
            const SizedBox(height: 8),
            ShadButton.outline(
              onPressed: () => context.push('/login'),
              child: const Text('Go to Login'),
            ),
          ],
        ),
      ),
    );
  }
}
