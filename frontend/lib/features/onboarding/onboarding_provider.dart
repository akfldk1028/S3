import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'onboarding_provider.g.dart';

const _kOnboardingCompletedKey = 'onboarding_completed';

@riverpod
class OnboardingNotifier extends _$OnboardingNotifier {
  @override
  FutureOr<bool> build() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_kOnboardingCompletedKey) ?? false;
    } catch (_) {
      // If SharedPreferences read fails, default to false (show onboarding).
      return false;
    }
  }

  Future<void> completeOnboarding() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_kOnboardingCompletedKey, true);
      state = const AsyncData(true);
    } catch (_) {
      // Keep current state on failure; onboarding will show again next launch.
    }
  }
}
