import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/auth/auth_provider.dart';

/// Authentication screen with automatic anonymous login.
///
/// This screen automatically calls the auth provider's login() method
/// on mount to perform anonymous JWT authentication via POST /auth/anon.
///
/// Flow:
/// 1. Screen mounts → initState triggers auto-login
/// 2. Shows CircularProgressIndicator during login
/// 3. On success → GoRouter auth guard redirects to /domain-select
/// 4. On error → Shows error SnackBar, allows retry
///
/// The screen has no user interaction - login happens automatically.
/// The redirect to /domain-select is handled by the router's auth guard.
class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // Trigger auto-login after first frame to avoid calling during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _performAutoLogin();
    });
  }

  /// Performs anonymous login via auth provider.
  ///
  /// On success: Router auto-redirects to /domain-select via auth guard
  /// On failure: Shows error message and allows retry
  Future<void> _performAutoLogin() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await ref.read(authProvider.notifier).login();
      // Router will auto-redirect to /domain-select when authState changes
    } catch (error) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = error.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: _isLoading
            ? const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text(
                    'Logging in...',
                    style: TextStyle(fontSize: 16),
                  ),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: Colors.red,
                    size: 64,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Login Failed',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      _errorMessage ?? 'Unknown error',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _performAutoLogin,
                    child: const Text('Retry'),
                  ),
                ],
              ),
      ),
    );
  }
}
