// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'workspace_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Riverpod notifier that manages the [WorkspaceState] for the workspace feature.
///
/// Access via `ref.read(workspaceProvider.notifier)`.
/// Watch state via `ref.watch(workspaceProvider)`.

@ProviderFor(Workspace)
final workspaceProvider = WorkspaceProvider._();

/// Riverpod notifier that manages the [WorkspaceState] for the workspace feature.
///
/// Access via `ref.read(workspaceProvider.notifier)`.
/// Watch state via `ref.watch(workspaceProvider)`.
final class WorkspaceProvider
    extends $NotifierProvider<Workspace, WorkspaceState> {
  /// Riverpod notifier that manages the [WorkspaceState] for the workspace feature.
  ///
  /// Access via `ref.read(workspaceProvider.notifier)`.
  /// Watch state via `ref.watch(workspaceProvider)`.
  WorkspaceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'workspaceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$workspaceHash();

  @$internal
  @override
  Workspace create() => Workspace();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(WorkspaceState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<WorkspaceState>(value),
    );
  }
}

String _$workspaceHash() => r'1624bdf1c295be6fdb02dabbb961df268face1ce';

/// Riverpod notifier that manages the [WorkspaceState] for the workspace feature.
///
/// Access via `ref.read(workspaceProvider.notifier)`.
/// Watch state via `ref.watch(workspaceProvider)`.

abstract class _$Workspace extends $Notifier<WorkspaceState> {
  WorkspaceState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<WorkspaceState, WorkspaceState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<WorkspaceState, WorkspaceState>,
              WorkspaceState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
