import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

// Dark-theme palette matching WsColors spec:
// error = 0xFFEF4444  (red offline banner background)
const _errorColor = Color(0xFFEF4444);
const _bannerHeight = 48.0;

/// A widget that overlays an animated offline banner on top of its [child]
/// whenever network connectivity is unavailable.
///
/// Listens to [Connectivity.onConnectivityChanged] and shows a persistent
/// top banner (red background, wifi_off icon, "No internet connection" text)
/// when [ConnectivityResult.none] is detected. The banner animates out
/// automatically when connectivity is restored.
///
/// The [StreamSubscription] is cancelled in [dispose] to prevent memory leaks.
///
/// Usage:
/// ```dart
/// OfflineIndicator(child: MyApp())
/// ```
class OfflineIndicator extends StatefulWidget {
  /// The widget subtree to display beneath the offline banner.
  final Widget child;

  const OfflineIndicator({super.key, required this.child});

  @override
  State<OfflineIndicator> createState() => _OfflineIndicatorState();
}

class _OfflineIndicatorState extends State<OfflineIndicator> {
  late StreamSubscription<List<ConnectivityResult>> _subscription;
  bool _isOffline = false;

  @override
  void initState() {
    super.initState();

    // Subscribe to connectivity changes.
    // connectivity_plus v7 emits List<ConnectivityResult>.
    _subscription = Connectivity().onConnectivityChanged.listen(
      (List<ConnectivityResult> results) {
        final offline = results.contains(ConnectivityResult.none);
        if (mounted && offline != _isOffline) {
          setState(() => _isOffline = offline);
        }
      },
    );
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Main content — always visible beneath the banner.
        widget.child,

        // Offline banner — slides in from top when offline.
        AnimatedPositioned(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          top: _isOffline ? 0.0 : -_bannerHeight,
          left: 0,
          right: 0,
          height: _bannerHeight,
          child: Material(
            color: _errorColor,
            child: SafeArea(
              bottom: false,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.wifi_off,
                    color: Colors.white,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'No internet connection',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
