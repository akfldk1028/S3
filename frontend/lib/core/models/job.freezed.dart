// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'job.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Job {

@JsonKey(name: 'job_id') String get jobId; String get status;// 'created' | 'uploaded' | 'queued' | 'running' | 'done' | 'failed' | 'canceled'
 String get preset; JobProgress get progress;@JsonKey(name: 'outputs_ready') List<JobItem> get outputsReady;
/// Create a copy of Job
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$JobCopyWith<Job> get copyWith => _$JobCopyWithImpl<Job>(this as Job, _$identity);

  /// Serializes this Job to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Job&&(identical(other.jobId, jobId) || other.jobId == jobId)&&(identical(other.status, status) || other.status == status)&&(identical(other.preset, preset) || other.preset == preset)&&(identical(other.progress, progress) || other.progress == progress)&&const DeepCollectionEquality().equals(other.outputsReady, outputsReady));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,jobId,status,preset,progress,const DeepCollectionEquality().hash(outputsReady));

@override
String toString() {
  return 'Job(jobId: $jobId, status: $status, preset: $preset, progress: $progress, outputsReady: $outputsReady)';
}


}

/// @nodoc
abstract mixin class $JobCopyWith<$Res>  {
  factory $JobCopyWith(Job value, $Res Function(Job) _then) = _$JobCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'job_id') String jobId, String status, String preset, JobProgress progress,@JsonKey(name: 'outputs_ready') List<JobItem> outputsReady
});


$JobProgressCopyWith<$Res> get progress;

}
/// @nodoc
class _$JobCopyWithImpl<$Res>
    implements $JobCopyWith<$Res> {
  _$JobCopyWithImpl(this._self, this._then);

  final Job _self;
  final $Res Function(Job) _then;

/// Create a copy of Job
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? jobId = null,Object? status = null,Object? preset = null,Object? progress = null,Object? outputsReady = null,}) {
  return _then(_self.copyWith(
jobId: null == jobId ? _self.jobId : jobId // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,preset: null == preset ? _self.preset : preset // ignore: cast_nullable_to_non_nullable
as String,progress: null == progress ? _self.progress : progress // ignore: cast_nullable_to_non_nullable
as JobProgress,outputsReady: null == outputsReady ? _self.outputsReady : outputsReady // ignore: cast_nullable_to_non_nullable
as List<JobItem>,
  ));
}
/// Create a copy of Job
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$JobProgressCopyWith<$Res> get progress {
  
  return $JobProgressCopyWith<$Res>(_self.progress, (value) {
    return _then(_self.copyWith(progress: value));
  });
}
}


/// Adds pattern-matching-related methods to [Job].
extension JobPatterns on Job {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Job value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Job() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Job value)  $default,){
final _that = this;
switch (_that) {
case _Job():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Job value)?  $default,){
final _that = this;
switch (_that) {
case _Job() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'job_id')  String jobId,  String status,  String preset,  JobProgress progress, @JsonKey(name: 'outputs_ready')  List<JobItem> outputsReady)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Job() when $default != null:
return $default(_that.jobId,_that.status,_that.preset,_that.progress,_that.outputsReady);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'job_id')  String jobId,  String status,  String preset,  JobProgress progress, @JsonKey(name: 'outputs_ready')  List<JobItem> outputsReady)  $default,) {final _that = this;
switch (_that) {
case _Job():
return $default(_that.jobId,_that.status,_that.preset,_that.progress,_that.outputsReady);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'job_id')  String jobId,  String status,  String preset,  JobProgress progress, @JsonKey(name: 'outputs_ready')  List<JobItem> outputsReady)?  $default,) {final _that = this;
switch (_that) {
case _Job() when $default != null:
return $default(_that.jobId,_that.status,_that.preset,_that.progress,_that.outputsReady);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Job implements Job {
  const _Job({@JsonKey(name: 'job_id') required this.jobId, required this.status, required this.preset, required this.progress, @JsonKey(name: 'outputs_ready') required final  List<JobItem> outputsReady}): _outputsReady = outputsReady;
  factory _Job.fromJson(Map<String, dynamic> json) => _$JobFromJson(json);

@override@JsonKey(name: 'job_id') final  String jobId;
@override final  String status;
// 'created' | 'uploaded' | 'queued' | 'running' | 'done' | 'failed' | 'canceled'
@override final  String preset;
@override final  JobProgress progress;
 final  List<JobItem> _outputsReady;
@override@JsonKey(name: 'outputs_ready') List<JobItem> get outputsReady {
  if (_outputsReady is EqualUnmodifiableListView) return _outputsReady;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_outputsReady);
}


/// Create a copy of Job
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$JobCopyWith<_Job> get copyWith => __$JobCopyWithImpl<_Job>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$JobToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Job&&(identical(other.jobId, jobId) || other.jobId == jobId)&&(identical(other.status, status) || other.status == status)&&(identical(other.preset, preset) || other.preset == preset)&&(identical(other.progress, progress) || other.progress == progress)&&const DeepCollectionEquality().equals(other._outputsReady, _outputsReady));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,jobId,status,preset,progress,const DeepCollectionEquality().hash(_outputsReady));

@override
String toString() {
  return 'Job(jobId: $jobId, status: $status, preset: $preset, progress: $progress, outputsReady: $outputsReady)';
}


}

/// @nodoc
abstract mixin class _$JobCopyWith<$Res> implements $JobCopyWith<$Res> {
  factory _$JobCopyWith(_Job value, $Res Function(_Job) _then) = __$JobCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'job_id') String jobId, String status, String preset, JobProgress progress,@JsonKey(name: 'outputs_ready') List<JobItem> outputsReady
});


@override $JobProgressCopyWith<$Res> get progress;

}
/// @nodoc
class __$JobCopyWithImpl<$Res>
    implements _$JobCopyWith<$Res> {
  __$JobCopyWithImpl(this._self, this._then);

  final _Job _self;
  final $Res Function(_Job) _then;

/// Create a copy of Job
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? jobId = null,Object? status = null,Object? preset = null,Object? progress = null,Object? outputsReady = null,}) {
  return _then(_Job(
jobId: null == jobId ? _self.jobId : jobId // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,preset: null == preset ? _self.preset : preset // ignore: cast_nullable_to_non_nullable
as String,progress: null == progress ? _self.progress : progress // ignore: cast_nullable_to_non_nullable
as JobProgress,outputsReady: null == outputsReady ? _self._outputsReady : outputsReady // ignore: cast_nullable_to_non_nullable
as List<JobItem>,
  ));
}

/// Create a copy of Job
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$JobProgressCopyWith<$Res> get progress {
  
  return $JobProgressCopyWith<$Res>(_self.progress, (value) {
    return _then(_self.copyWith(progress: value));
  });
}
}

// dart format on
