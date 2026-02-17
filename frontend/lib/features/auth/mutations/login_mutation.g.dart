// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'login_mutation.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(LoginMutation)
final loginMutationProvider = LoginMutationProvider._();

final class LoginMutationProvider
    extends $AsyncNotifierProvider<LoginMutation, LoginResponse?> {
  LoginMutationProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'loginMutationProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$loginMutationHash();

  @$internal
  @override
  LoginMutation create() => LoginMutation();
}

String _$loginMutationHash() => r'ec0b0706cbfede5fc9b61a80287a4b15a86193fc';

abstract class _$LoginMutation extends $AsyncNotifier<LoginResponse?> {
  FutureOr<LoginResponse?> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<LoginResponse?>, LoginResponse?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<LoginResponse?>, LoginResponse?>,
              AsyncValue<LoginResponse?>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
