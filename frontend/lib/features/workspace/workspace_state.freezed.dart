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

 List<SelectedImage> get selectedImages; WorkspacePhase get phase; bool get showLargeBatchWarning; String? get errorMessage; double get uploadProgress; JobResult? get activeJob;
/// Create a copy of WorkspaceState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WorkspaceStateCopyWith<WorkspaceState> get copyWith => _$WorkspaceStateCopyWithImpl<WorkspaceState>(this as WorkspaceState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WorkspaceState&&const DeepCollectionEquality().equals(other.selectedImages, selectedImages)&&(identical(other.phase, phase) || other.phase == phase)&&(identical(other.showLargeBatchWarning, showLargeBatchWarning) || other.showLargeBatchWarning == showLargeBatchWarning)&&(identical(other.errorMessage, errorMessage) || other.errorMessage == errorMessage)&&(identical(other.uploadProgress, uploadProgress) || other.uploadProgress == uploadProgress)&&(identical(other.activeJob, activeJob) || other.activeJob == activeJob));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(selectedImages),phase,showLargeBatchWarning,errorMessage,uploadProgress,activeJob);

@override
String toString() {
  return 'WorkspaceState(selectedImages: $selectedImages, phase: $phase, showLargeBatchWarning: $showLargeBatchWarning, errorMessage: $errorMessage, uploadProgress: $uploadProgress, activeJob: $activeJob)';
}


}

/// @nodoc
abstract mixin class $WorkspaceStateCopyWith<$Res>  {
  factory $WorkspaceStateCopyWith(WorkspaceState value, $Res Function(WorkspaceState) _then) = _$WorkspaceStateCopyWithImpl;
@useResult
$Res call({
 List<SelectedImage> selectedImages, WorkspacePhase phase, bool showLargeBatchWarning, String? errorMessage, double uploadProgress, JobResult? activeJob
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
@pragma('vm:prefer-inline') @override $Res call({Object? selectedImages = null,Object? phase = null,Object? showLargeBatchWarning = null,Object? errorMessage = freezed,Object? uploadProgress = null,Object? activeJob = freezed,}) {
  return _then(_self.copyWith(
selectedImages: null == selectedImages ? _self.selectedImages : selectedImages // ignore: cast_nullable_to_non_nullable
as List<SelectedImage>,phase: null == phase ? _self.phase : phase // ignore: cast_nullable_to_non_nullable
as WorkspacePhase,showLargeBatchWarning: null == showLargeBatchWarning ? _self.showLargeBatchWarning : showLargeBatchWarning // ignore: cast_nullable_to_non_nullable
as bool,errorMessage: freezed == errorMessage ? _self.errorMessage : errorMessage // ignore: cast_nullable_to_non_nullable
as String?,uploadProgress: null == uploadProgress ? _self.uploadProgress : uploadProgress // ignore: cast_nullable_to_non_nullable
as double,activeJob: freezed == activeJob ? _self.activeJob : activeJob // ignore: cast_nullable_to_non_nullable
as JobResult?,
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<SelectedImage> selectedImages,  WorkspacePhase phase,  bool showLargeBatchWarning,  String? errorMessage,  double uploadProgress,  JobResult? activeJob)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _WorkspaceState() when $default != null:
return $default(_that.selectedImages,_that.phase,_that.showLargeBatchWarning,_that.errorMessage,_that.uploadProgress,_that.activeJob);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<SelectedImage> selectedImages,  WorkspacePhase phase,  bool showLargeBatchWarning,  String? errorMessage,  double uploadProgress,  JobResult? activeJob)  $default,) {final _that = this;
switch (_that) {
case _WorkspaceState():
return $default(_that.selectedImages,_that.phase,_that.showLargeBatchWarning,_that.errorMessage,_that.uploadProgress,_that.activeJob);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<SelectedImage> selectedImages,  WorkspacePhase phase,  bool showLargeBatchWarning,  String? errorMessage,  double uploadProgress,  JobResult? activeJob)?  $default,) {final _that = this;
switch (_that) {
case _WorkspaceState() when $default != null:
return $default(_that.selectedImages,_that.phase,_that.showLargeBatchWarning,_that.errorMessage,_that.uploadProgress,_that.activeJob);case _:
  return null;

}
}

}

/// @nodoc


class _WorkspaceState implements WorkspaceState {
  const _WorkspaceState({final  List<SelectedImage> selectedImages = const [], this.phase = WorkspacePhase.idle, this.showLargeBatchWarning = false, this.errorMessage, this.uploadProgress = 0.0, this.activeJob}): _selectedImages = selectedImages;
  

 final  List<SelectedImage> _selectedImages;
@override@JsonKey() List<SelectedImage> get selectedImages {
  if (_selectedImages is EqualUnmodifiableListView) return _selectedImages;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_selectedImages);
}

@override@JsonKey() final  WorkspacePhase phase;
@override@JsonKey() final  bool showLargeBatchWarning;
@override final  String? errorMessage;
@override@JsonKey() final  double uploadProgress;
@override final  JobResult? activeJob;

/// Create a copy of WorkspaceState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$WorkspaceStateCopyWith<_WorkspaceState> get copyWith => __$WorkspaceStateCopyWithImpl<_WorkspaceState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _WorkspaceState&&const DeepCollectionEquality().equals(other._selectedImages, _selectedImages)&&(identical(other.phase, phase) || other.phase == phase)&&(identical(other.showLargeBatchWarning, showLargeBatchWarning) || other.showLargeBatchWarning == showLargeBatchWarning)&&(identical(other.errorMessage, errorMessage) || other.errorMessage == errorMessage)&&(identical(other.uploadProgress, uploadProgress) || other.uploadProgress == uploadProgress)&&(identical(other.activeJob, activeJob) || other.activeJob == activeJob));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_selectedImages),phase,showLargeBatchWarning,errorMessage,uploadProgress,activeJob);

@override
String toString() {
  return 'WorkspaceState(selectedImages: $selectedImages, phase: $phase, showLargeBatchWarning: $showLargeBatchWarning, errorMessage: $errorMessage, uploadProgress: $uploadProgress, activeJob: $activeJob)';
}


}

/// @nodoc
abstract mixin class _$WorkspaceStateCopyWith<$Res> implements $WorkspaceStateCopyWith<$Res> {
  factory _$WorkspaceStateCopyWith(_WorkspaceState value, $Res Function(_WorkspaceState) _then) = __$WorkspaceStateCopyWithImpl;
@override @useResult
$Res call({
 List<SelectedImage> selectedImages, WorkspacePhase phase, bool showLargeBatchWarning, String? errorMessage, double uploadProgress, JobResult? activeJob
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
@override @pragma('vm:prefer-inline') $Res call({Object? selectedImages = null,Object? phase = null,Object? showLargeBatchWarning = null,Object? errorMessage = freezed,Object? uploadProgress = null,Object? activeJob = freezed,}) {
  return _then(_WorkspaceState(
selectedImages: null == selectedImages ? _self._selectedImages : selectedImages // ignore: cast_nullable_to_non_nullable
as List<SelectedImage>,phase: null == phase ? _self.phase : phase // ignore: cast_nullable_to_non_nullable
as WorkspacePhase,showLargeBatchWarning: null == showLargeBatchWarning ? _self.showLargeBatchWarning : showLargeBatchWarning // ignore: cast_nullable_to_non_nullable
as bool,errorMessage: freezed == errorMessage ? _self.errorMessage : errorMessage // ignore: cast_nullable_to_non_nullable
as String?,uploadProgress: null == uploadProgress ? _self.uploadProgress : uploadProgress // ignore: cast_nullable_to_non_nullable
as double,activeJob: freezed == activeJob ? _self.activeJob : activeJob // ignore: cast_nullable_to_non_nullable
as JobResult?,
  ));
}


}

// dart format on
