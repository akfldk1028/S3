import 'dart:ui';

import 'package:flutter/material.dart';

// Dark-theme palette matching WsColors spec:
// bg    = 0xFF0F0F17  (page background)
// error = 0xFFEF4444  (red error indicator)
const _bg = Color(0xFF0F0F17);
const _errorColor = Color(0xFFEF4444);
const _surfaceColor = Color(0xFF1A1A2E);
const _textPrimary = Colors.white;
const _textSecondary = Color(0xFF8888AA);

/// A global error boundary that catches both Flutter framework errors and
/// unhandled async/platform errors.
///
/// Wrap the root of your widget tree with [ErrorBoundary] to ensure that any
/// uncaught exception renders a styled recovery screen instead of a blank
/// white crash page. The recovery screen displays an error icon, the error
/// message, and a "Restart App" button that resets the captured error so the
/// child tree is shown again.
///
/// Usage:
/// ```dart
/// ErrorBoundary(child: MyApp())
/// ```
class ErrorBoundary extends StatefulWidget {
  /// The widget subtree to protect.
  final Widget child;

  const ErrorBoundary({super.key, required this.child});

  @override
  State<ErrorBoundary> createState() => _ErrorBoundaryState();
}

class _ErrorBoundaryState extends State<ErrorBoundary> {
  Object? _error;

  @override
  void initState() {
    super.initState();

    // Capture synchronous Flutter framework errors (widget build, layout, etc.)
    FlutterError.onError = (FlutterErrorDetails details) {
      if (mounted) {
        setState(() => _error = details.exception);
      }
    };

    // Capture asynchronous / platform-level errors that Flutter does not
    // route through FlutterError.onError (e.g. unawaited Future errors,
    // isolate errors forwarded by the platform dispatcher).
    PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
      if (mounted) {
        setState(() => _error = error);
      }
      // Return true to indicate the error has been handled; prevents the
      // platform from propagating it further.
      return true;
    };
  }

  /// Clears the captured error, causing the child tree to be displayed again.
  void _restartApp() {
    setState(() => _error = null);
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return _ErrorScreen(error: _error!, onRestart: _restartApp);
    }
    return widget.child;
  }
}

/// Full-screen error recovery screen shown when [ErrorBoundary] captures an
/// unhandled exception.
///
/// Styled with the dark-theme WsColors palette (bg background, error-red icon)
/// for visual consistency with the rest of the app.
class _ErrorScreen extends StatelessWidget {
  final Object error;
  final VoidCallback onRestart;

  const _ErrorScreen({required this.error, required this.onRestart});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Scaffold(
        backgroundColor: _bg,
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Error icon
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: _errorColor.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.error_outline_rounded,
                      color: _errorColor,
                      size: 44,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Title
                  const Text(
                    'Something went wrong',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: _textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Error message
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _surfaceColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      error.toString(),
                      textAlign: TextAlign.center,
                      maxLines: 6,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _textSecondary,
                        fontSize: 13,
                        height: 1.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Restart button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: onRestart,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _errorColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Restart App',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
