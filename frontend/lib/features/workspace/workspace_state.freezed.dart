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

 WorkspacePhase get phase; String? get selectedPresetId; List<SelectedImage> get selectedImages; String? get activeJobId; double get uploadProgress; Job? get activeJob; String? get selectedRuleId; String? get errorMessage;
/// Create a copy of WorkspaceState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WorkspaceStateCopyWith<WorkspaceState> get copyWith => _$WorkspaceStateCopyWithImpl<WorkspaceState>(this as WorkspaceState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WorkspaceState&&(identical(other.phase, phase) || other.phase == phase)&&(identical(other.selectedPresetId, selectedPresetId) || other.selectedPresetId == selectedPresetId)&&const DeepCollectionEquality().equals(other.selectedImages, selectedImages)&&(identical(other.activeJobId, activeJobId) || other.activeJobId == activeJobId)&&(identical(other.uploadProgress, uploadProgress) || other.uploadProgress == uploadProgress)&&(identical(other.activeJob, activeJob) || other.activeJob == activeJob)&&(identical(other.selectedRuleId, selectedRuleId) || other.selectedRuleId == selectedRuleId)&&(identical(other.errorMessage, errorMessage) || other.errorMessage == errorMessage));
}


@override
int get hashCode => Object.hash(runtimeType,phase,selectedPresetId,const DeepCollectionEquality().hash(selectedImages),activeJobId,uploadProgress,activeJob,selectedRuleId,errorMessage);

@override
String toString() {
  return 'WorkspaceState(phase: $phase, selectedPresetId: $selectedPresetId, selectedImages: $selectedImages, activeJobId: $activeJobId, uploadProgress: $uploadProgress, activeJob: $activeJob, selectedRuleId: $selectedRuleId, errorMessage: $errorMessage)';
}


}

/// @nodoc
abstract mixin class $WorkspaceStateCopyWith<$Res>  {
  factory $WorkspaceStateCopyWith(WorkspaceState value, $Res Function(WorkspaceState) _then) = _$WorkspaceStateCopyWithImpl;
@useResult
$Res call({
 WorkspacePhase phase, String? selectedPresetId, List<SelectedImage> selectedImages, String? activeJobId, double uploadProgress, Job? activeJob, String? selectedRuleId, String? errorMessage
});


$JobCopyWith<$Res>? get activeJob;

}
/// @nodoc
class _$WorkspaceStateCopyWithImpl<$Res>
    implements $WorkspaceStateCopyWith<$Res> {
  _$WorkspaceStateCopyWithImpl(this._self, this._then);

  final WorkspaceState _self;
  final $Res Function(WorkspaceState) _then;

/// Create a copy of WorkspaceState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? phase = null,Object? selectedPresetId = freezed,Object? selectedImages = null,Object? activeJobId = freezed,Object? uploadProgress = null,Object? activeJob = freezed,Object? selectedRuleId = freezed,Object? errorMessage = freezed,}) {
  return _then(_self.copyWith(
phase: null == phase ? _self.phase : phase // ignore: cast_nullable_to_non_nullable
as WorkspacePhase,selectedPresetId: freezed == selectedPresetId ? _self.selectedPresetId : selectedPresetId // ignore: cast_nullable_to_non_nullable
as String?,selectedImages: null == selectedImages ? _self.selectedImages : selectedImages // ignore: cast_nullable_to_non_nullable
as List<SelectedImage>,activeJobId: freezed == activeJobId ? _self.activeJobId : activeJobId // ignore: cast_nullable_to_non_nullable
as String?,uploadProgress: null == uploadProgress ? _self.uploadProgress : uploadProgress // ignore: cast_nullable_to_non_nullable
as double,activeJob: freezed == activeJob ? _self.activeJob : activeJob // ignore: cast_nullable_to_non_nullable
as Job?,selectedRuleId: freezed == selectedRuleId ? _self.selectedRuleId : selectedRuleId // ignore: cast_nullable_to_non_nullable
as String?,errorMessage: freezed == errorMessage ? _self.errorMessage : errorMessage // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}
/// Create a copy of WorkspaceState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$JobCopyWith<$Res>? get activeJob {
    if (_self.activeJob == null) {
    return null;
  }

  return $JobCopyWith<$Res>(_self.activeJob!, (value) {
    return _then(_self.copyWith(activeJob: value));
  });
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( WorkspacePhase phase,  String? selectedPresetId,  List<SelectedImage> selectedImages,  String? activeJobId,  double uploadProgress,  Job? activeJob,  String? selectedRuleId,  String? errorMessage)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _WorkspaceState() when $default != null:
return $default(_that.phase,_that.selectedPresetId,_that.selectedImages,_that.activeJobId,_that.uploadProgress,_that.activeJob,_that.selectedRuleId,_that.errorMessage);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( WorkspacePhase phase,  String? selectedPresetId,  List<SelectedImage> selectedImages,  String? activeJobId,  double uploadProgress,  Job? activeJob,  String? selectedRuleId,  String? errorMessage)  $default,) {final _that = this;
switch (_that) {
case _WorkspaceState():
return $default(_that.phase,_that.selectedPresetId,_that.selectedImages,_that.activeJobId,_that.uploadProgress,_that.activeJob,_that.selectedRuleId,_that.errorMessage);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( WorkspacePhase phase,  String? selectedPresetId,  List<SelectedImage> selectedImages,  String? activeJobId,  double uploadProgress,  Job? activeJob,  String? selectedRuleId,  String? errorMessage)?  $default,) {final _that = this;
switch (_that) {
case _WorkspaceState() when $default != null:
return $default(_that.phase,_that.selectedPresetId,_that.selectedImages,_that.activeJobId,_that.uploadProgress,_that.activeJob,_that.selectedRuleId,_that.errorMessage);case _:
  return null;

}
}

}

/// @nodoc


class _WorkspaceState implements WorkspaceState {
  const _WorkspaceState({this.phase = WorkspacePhase.idle, this.selectedPresetId, final  List<SelectedImage> selectedImages = const [], this.activeJobId, this.uploadProgress = 0.0, this.activeJob, this.selectedRuleId, this.errorMessage}): _selectedImages = selectedImages;
  

@override@JsonKey() final  WorkspacePhase phase;
@override final  String? selectedPresetId;
 final  List<SelectedImage> _selectedImages;
@override@JsonKey() List<SelectedImage> get selectedImages {
  if (_selectedImages is EqualUnmodifiableListView) return _selectedImages;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_selectedImages);
}

@override final  String? activeJobId;
@override@JsonKey() final  double uploadProgress;
@override final  Job? activeJob;
@override final  String? selectedRuleId;
@override final  String? errorMessage;

/// Create a copy of WorkspaceState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$WorkspaceStateCopyWith<_WorkspaceState> get copyWith => __$WorkspaceStateCopyWithImpl<_WorkspaceState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _WorkspaceState&&(identical(other.phase, phase) || other.phase == phase)&&(identical(other.selectedPresetId, selectedPresetId) || other.selectedPresetId == selectedPresetId)&&const DeepCollectionEquality().equals(other._selectedImages, _selectedImages)&&(identical(other.activeJobId, activeJobId) || other.activeJobId == activeJobId)&&(identical(other.uploadProgress, uploadProgress) || other.uploadProgress == uploadProgress)&&(identical(other.activeJob, activeJob) || other.activeJob == activeJob)&&(identical(other.selectedRuleId, selectedRuleId) || other.selectedRuleId == selectedRuleId)&&(identical(other.errorMessage, errorMessage) || other.errorMessage == errorMessage));
}


@override
int get hashCode => Object.hash(runtimeType,phase,selectedPresetId,const DeepCollectionEquality().hash(_selectedImages),activeJobId,uploadProgress,activeJob,selectedRuleId,errorMessage);

@override
String toString() {
  return 'WorkspaceState(phase: $phase, selectedPresetId: $selectedPresetId, selectedImages: $selectedImages, activeJobId: $activeJobId, uploadProgress: $uploadProgress, activeJob: $activeJob, selectedRuleId: $selectedRuleId, errorMessage: $errorMessage)';
}


}

/// @nodoc
abstract mixin class _$WorkspaceStateCopyWith<$Res> implements $WorkspaceStateCopyWith<$Res> {
  factory _$WorkspaceStateCopyWith(_WorkspaceState value, $Res Function(_WorkspaceState) _then) = __$WorkspaceStateCopyWithImpl;
@override @useResult
$Res call({
 WorkspacePhase phase, String? selectedPresetId, List<SelectedImage> selectedImages, String? activeJobId, double uploadProgress, Job? activeJob, String? selectedRuleId, String? errorMessage
});


@override $JobCopyWith<$Res>? get activeJob;

}
/// @nodoc
class __$WorkspaceStateCopyWithImpl<$Res>
    implements _$WorkspaceStateCopyWith<$Res> {
  __$WorkspaceStateCopyWithImpl(this._self, this._then);

  final _WorkspaceState _self;
  final $Res Function(_WorkspaceState) _then;

/// Create a copy of WorkspaceState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? phase = null,Object? selectedPresetId = freezed,Object? selectedImages = null,Object? activeJobId = freezed,Object? uploadProgress = null,Object? activeJob = freezed,Object? selectedRuleId = freezed,Object? errorMessage = freezed,}) {
  return _then(_WorkspaceState(
phase: null == phase ? _self.phase : phase // ignore: cast_nullable_to_non_nullable
as WorkspacePhase,selectedPresetId: freezed == selectedPresetId ? _self.selectedPresetId : selectedPresetId // ignore: cast_nullable_to_non_nullable
as String?,selectedImages: null == selectedImages ? _self._selectedImages : selectedImages // ignore: cast_nullable_to_non_nullable
as List<SelectedImage>,activeJobId: freezed == activeJobId ? _self.activeJobId : activeJobId // ignore: cast_nullable_to_non_nullable
as String?,uploadProgress: null == uploadProgress ? _self.uploadProgress : uploadProgress // ignore: cast_nullable_to_non_nullable
as double,activeJob: freezed == activeJob ? _self.activeJob : activeJob // ignore: cast_nullable_to_non_nullable
as Job?,selectedRuleId: freezed == selectedRuleId ? _self.selectedRuleId : selectedRuleId // ignore: cast_nullable_to_non_nullable
as String?,errorMessage: freezed == errorMessage ? _self.errorMessage : errorMessage // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

/// Create a copy of WorkspaceState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$JobCopyWith<$Res>? get activeJob {
    if (_self.activeJob == null) {
    return null;
  }

  return $JobCopyWith<$Res>(_self.activeJob!, (value) {
    return _then(_self.copyWith(activeJob: value));
  });
}
}

// dart format on
