// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'workspace_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$WorkspaceState {

/// Current phase of the processing pipeline
 WorkspacePhase get phase;/// Raw bytes of photos selected by the user; preserved across retries
 List<Uint8List> get selectedImages;/// Upload progress [0.0, 1.0]; only meaningful during [WorkspacePhase.uploading]
 double get uploadProgress;/// Server-assigned job ID, set after POST /jobs succeeds
 String? get activeJobId;/// Latest job status polled from GET /jobs/:id
 Job? get activeJob;/// Human-readable error message shown in the error banner
 String? get errorMessage;/// Number of consecutive network failures during polling (for UI feedback)
 int get networkRetryCount;/// User-supplied text prompts passed to SAM3 during executeJob.
///
/// Added via [WorkspaceNotifier.addPrompt]; removed via
/// [WorkspaceNotifier.removePrompt]. Passed as `prompts` in the
/// POST /jobs/:id/execute request body when non-empty.
 List<String> get customPrompts;
/// Create a copy of WorkspaceState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WorkspaceStateCopyWith<WorkspaceState> get copyWith => _$WorkspaceStateCopyWithImpl<WorkspaceState>(this as WorkspaceState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WorkspaceState&&(identical(other.phase, phase) || other.phase == phase)&&const DeepCollectionEquality().equals(other.selectedImages, selectedImages)&&(identical(other.uploadProgress, uploadProgress) || other.uploadProgress == uploadProgress)&&(identical(other.activeJobId, activeJobId) || other.activeJobId == activeJobId)&&(identical(other.activeJob, activeJob) || other.activeJob == activeJob)&&(identical(other.errorMessage, errorMessage) || other.errorMessage == errorMessage)&&(identical(other.networkRetryCount, networkRetryCount) || other.networkRetryCount == networkRetryCount)&&const DeepCollectionEquality().equals(other.customPrompts, customPrompts));
}


@override
int get hashCode => Object.hash(runtimeType,phase,const DeepCollectionEquality().hash(selectedImages),uploadProgress,activeJobId,activeJob,errorMessage,networkRetryCount,const DeepCollectionEquality().hash(customPrompts));

@override
String toString() {
  return 'WorkspaceState(phase: $phase, selectedImages: $selectedImages, uploadProgress: $uploadProgress, activeJobId: $activeJobId, activeJob: $activeJob, errorMessage: $errorMessage, networkRetryCount: $networkRetryCount, customPrompts: $customPrompts)';
}


}

/// @nodoc
abstract mixin class $WorkspaceStateCopyWith<$Res>  {
  factory $WorkspaceStateCopyWith(WorkspaceState value, $Res Function(WorkspaceState) _then) = _$WorkspaceStateCopyWithImpl;
@useResult
$Res call({
 WorkspacePhase phase, List<Uint8List> selectedImages, double uploadProgress, String? activeJobId, Job? activeJob, String? errorMessage, int networkRetryCount, List<String> customPrompts
});




}
/// @nodoc
class _$WorkspaceStateCopyWithImpl<$Res>
    implements $WorkspaceStateCopyWith<$Res> {
  _$WorkspaceStateCopyWithImpl(this._self, this._then);

  final WorkspaceState _self;
  final $Res Function(WorkspaceState) _then;

/// Create a copy of WorkspaceState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? phase = null,Object? selectedImages = null,Object? uploadProgress = null,Object? activeJobId = freezed,Object? activeJob = freezed,Object? errorMessage = freezed,Object? networkRetryCount = null,Object? customPrompts = null,}) {
  return _then(_self.copyWith(
phase: null == phase ? _self.phase : phase // ignore: cast_nullable_to_non_nullable
as WorkspacePhase,selectedImages: null == selectedImages ? _self.selectedImages : selectedImages // ignore: cast_nullable_to_non_nullable
as List<Uint8List>,uploadProgress: null == uploadProgress ? _self.uploadProgress : uploadProgress // ignore: cast_nullable_to_non_nullable
as double,activeJobId: freezed == activeJobId ? _self.activeJobId : activeJobId // ignore: cast_nullable_to_non_nullable
as String?,activeJob: freezed == activeJob ? _self.activeJob : activeJob // ignore: cast_nullable_to_non_nullable
as Job?,errorMessage: freezed == errorMessage ? _self.errorMessage : errorMessage // ignore: cast_nullable_to_non_nullable
as String?,networkRetryCount: null == networkRetryCount ? _self.networkRetryCount : networkRetryCount // ignore: cast_nullable_to_non_nullable
as int,customPrompts: null == customPrompts ? _self.customPrompts : customPrompts // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}

}


/// Adds pattern-matching-related methods to [WorkspaceState].
extension WorkspaceStatePatterns on WorkspaceState {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _WorkspaceState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _WorkspaceState() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _WorkspaceState value)  $default,){
final _that = this;
switch (_that) {
case _WorkspaceState():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _WorkspaceState value)?  $default,){
final _that = this;
switch (_that) {
case _WorkspaceState() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( WorkspacePhase phase,  List<Uint8List> selectedImages,  double uploadProgress,  String? activeJobId,  Job? activeJob,  String? errorMessage,  int networkRetryCount,  List<String> customPrompts)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _WorkspaceState() when $default != null:
return $default(_that.phase,_that.selectedImages,_that.uploadProgress,_that.activeJobId,_that.activeJob,_that.errorMessage,_that.networkRetryCount,_that.customPrompts);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( WorkspacePhase phase,  List<Uint8List> selectedImages,  double uploadProgress,  String? activeJobId,  Job? activeJob,  String? errorMessage,  int networkRetryCount,  List<String> customPrompts)  $default,) {final _that = this;
switch (_that) {
case _WorkspaceState():
return $default(_that.phase,_that.selectedImages,_that.uploadProgress,_that.activeJobId,_that.activeJob,_that.errorMessage,_that.networkRetryCount,_that.customPrompts);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( WorkspacePhase phase,  List<Uint8List> selectedImages,  double uploadProgress,  String? activeJobId,  Job? activeJob,  String? errorMessage,  int networkRetryCount,  List<String> customPrompts)?  $default,) {final _that = this;
switch (_that) {
case _WorkspaceState() when $default != null:
return $default(_that.phase,_that.selectedImages,_that.uploadProgress,_that.activeJobId,_that.activeJob,_that.errorMessage,_that.networkRetryCount,_that.customPrompts);case _:
  return null;

}
}

}

/// @nodoc


class _WorkspaceState implements WorkspaceState {
  const _WorkspaceState({this.phase = WorkspacePhase.idle, final  List<Uint8List> selectedImages = const [], this.uploadProgress = 0.0, this.activeJobId, this.activeJob, this.errorMessage, this.networkRetryCount = 0, final  List<String> customPrompts = const []}): _selectedImages = selectedImages,_customPrompts = customPrompts;
  

/// Current phase of the processing pipeline
@override@JsonKey() final  WorkspacePhase phase;
/// Raw bytes of photos selected by the user; preserved across retries
 final  List<Uint8List> _selectedImages;
/// Raw bytes of photos selected by the user; preserved across retries
@override@JsonKey() List<Uint8List> get selectedImages {
  if (_selectedImages is EqualUnmodifiableListView) return _selectedImages;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_selectedImages);
}

/// Upload progress [0.0, 1.0]; only meaningful during [WorkspacePhase.uploading]
@override@JsonKey() final  double uploadProgress;
/// Server-assigned job ID, set after POST /jobs succeeds
@override final  String? activeJobId;
/// Latest job status polled from GET /jobs/:id
@override final  Job? activeJob;
/// Human-readable error message shown in the error banner
@override final  String? errorMessage;
/// Number of consecutive network failures during polling (for UI feedback)
@override@JsonKey() final  int networkRetryCount;
/// User-supplied text prompts passed to SAM3 during executeJob.
///
/// Added via [WorkspaceNotifier.addPrompt]; removed via
/// [WorkspaceNotifier.removePrompt]. Passed as `prompts` in the
/// POST /jobs/:id/execute request body when non-empty.
 final  List<String> _customPrompts;
/// User-supplied text prompts passed to SAM3 during executeJob.
///
/// Added via [WorkspaceNotifier.addPrompt]; removed via
/// [WorkspaceNotifier.removePrompt]. Passed as `prompts` in the
/// POST /jobs/:id/execute request body when non-empty.
@override@JsonKey() List<String> get customPrompts {
  if (_customPrompts is EqualUnmodifiableListView) return _customPrompts;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_customPrompts);
}


/// Create a copy of WorkspaceState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$WorkspaceStateCopyWith<_WorkspaceState> get copyWith => __$WorkspaceStateCopyWithImpl<_WorkspaceState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _WorkspaceState&&(identical(other.phase, phase) || other.phase == phase)&&const DeepCollectionEquality().equals(other._selectedImages, _selectedImages)&&(identical(other.uploadProgress, uploadProgress) || other.uploadProgress == uploadProgress)&&(identical(other.activeJobId, activeJobId) || other.activeJobId == activeJobId)&&(identical(other.activeJob, activeJob) || other.activeJob == activeJob)&&(identical(other.errorMessage, errorMessage) || other.errorMessage == errorMessage)&&(identical(other.networkRetryCount, networkRetryCount) || other.networkRetryCount == networkRetryCount)&&const DeepCollectionEquality().equals(other._customPrompts, _customPrompts));
}


@override
int get hashCode => Object.hash(runtimeType,phase,const DeepCollectionEquality().hash(_selectedImages),uploadProgress,activeJobId,activeJob,errorMessage,networkRetryCount,const DeepCollectionEquality().hash(_customPrompts));

@override
String toString() {
  return 'WorkspaceState(phase: $phase, selectedImages: $selectedImages, uploadProgress: $uploadProgress, activeJobId: $activeJobId, activeJob: $activeJob, errorMessage: $errorMessage, networkRetryCount: $networkRetryCount, customPrompts: $customPrompts)';
}


}

/// @nodoc
abstract mixin class _$WorkspaceStateCopyWith<$Res> implements $WorkspaceStateCopyWith<$Res> {
  factory _$WorkspaceStateCopyWith(_WorkspaceState value, $Res Function(_WorkspaceState) _then) = __$WorkspaceStateCopyWithImpl;
@override @useResult
$Res call({
 WorkspacePhase phase, List<Uint8List> selectedImages, double uploadProgress, String? activeJobId, Job? activeJob, String? errorMessage, int networkRetryCount, List<String> customPrompts
});




}
/// @nodoc
class __$WorkspaceStateCopyWithImpl<$Res>
    implements _$WorkspaceStateCopyWith<$Res> {
  __$WorkspaceStateCopyWithImpl(this._self, this._then);

  final _WorkspaceState _self;
  final $Res Function(_WorkspaceState) _then;

/// Create a copy of WorkspaceState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? phase = null,Object? selectedImages = null,Object? uploadProgress = null,Object? activeJobId = freezed,Object? activeJob = freezed,Object? errorMessage = freezed,Object? networkRetryCount = null,Object? customPrompts = null,}) {
  return _then(_WorkspaceState(
phase: null == phase ? _self.phase : phase // ignore: cast_nullable_to_non_nullable
as WorkspacePhase,selectedImages: null == selectedImages ? _self._selectedImages : selectedImages // ignore: cast_nullable_to_non_nullable
as List<Uint8List>,uploadProgress: null == uploadProgress ? _self.uploadProgress : uploadProgress // ignore: cast_nullable_to_non_nullable
as double,activeJobId: freezed == activeJobId ? _self.activeJobId : activeJobId // ignore: cast_nullable_to_non_nullable
as String?,activeJob: freezed == activeJob ? _self.activeJob : activeJob // ignore: cast_nullable_to_non_nullable
as Job?,errorMessage: freezed == errorMessage ? _self.errorMessage : errorMessage // ignore: cast_nullable_to_non_nullable
as String?,networkRetryCount: null == networkRetryCount ? _self.networkRetryCount : networkRetryCount // ignore: cast_nullable_to_non_nullable
as int,customPrompts: null == customPrompts ? _self._customPrompts : customPrompts // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}


}

// dart format on
