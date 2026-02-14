// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'job_progress.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$JobProgress {

 int get done; int get failed; int get total;
/// Create a copy of JobProgress
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$JobProgressCopyWith<JobProgress> get copyWith => _$JobProgressCopyWithImpl<JobProgress>(this as JobProgress, _$identity);

  /// Serializes this JobProgress to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is JobProgress&&(identical(other.done, done) || other.done == done)&&(identical(other.failed, failed) || other.failed == failed)&&(identical(other.total, total) || other.total == total));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,done,failed,total);

@override
String toString() {
  return 'JobProgress(done: $done, failed: $failed, total: $total)';
}


}

/// @nodoc
abstract mixin class $JobProgressCopyWith<$Res>  {
  factory $JobProgressCopyWith(JobProgress value, $Res Function(JobProgress) _then) = _$JobProgressCopyWithImpl;
@useResult
$Res call({
 int done, int failed, int total
});




}
/// @nodoc
class _$JobProgressCopyWithImpl<$Res>
    implements $JobProgressCopyWith<$Res> {
  _$JobProgressCopyWithImpl(this._self, this._then);

  final JobProgress _self;
  final $Res Function(JobProgress) _then;

/// Create a copy of JobProgress
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? done = null,Object? failed = null,Object? total = null,}) {
  return _then(_self.copyWith(
done: null == done ? _self.done : done // ignore: cast_nullable_to_non_nullable
as int,failed: null == failed ? _self.failed : failed // ignore: cast_nullable_to_non_nullable
as int,total: null == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [JobProgress].
extension JobProgressPatterns on JobProgress {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _JobProgress value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _JobProgress() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _JobProgress value)  $default,){
final _that = this;
switch (_that) {
case _JobProgress():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _JobProgress value)?  $default,){
final _that = this;
switch (_that) {
case _JobProgress() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int done,  int failed,  int total)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _JobProgress() when $default != null:
return $default(_that.done,_that.failed,_that.total);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int done,  int failed,  int total)  $default,) {final _that = this;
switch (_that) {
case _JobProgress():
return $default(_that.done,_that.failed,_that.total);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int done,  int failed,  int total)?  $default,) {final _that = this;
switch (_that) {
case _JobProgress() when $default != null:
return $default(_that.done,_that.failed,_that.total);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _JobProgress implements JobProgress {
  const _JobProgress({required this.done, required this.failed, required this.total});
  factory _JobProgress.fromJson(Map<String, dynamic> json) => _$JobProgressFromJson(json);

@override final  int done;
@override final  int failed;
@override final  int total;

/// Create a copy of JobProgress
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$JobProgressCopyWith<_JobProgress> get copyWith => __$JobProgressCopyWithImpl<_JobProgress>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$JobProgressToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _JobProgress&&(identical(other.done, done) || other.done == done)&&(identical(other.failed, failed) || other.failed == failed)&&(identical(other.total, total) || other.total == total));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,done,failed,total);

@override
String toString() {
  return 'JobProgress(done: $done, failed: $failed, total: $total)';
}


}

/// @nodoc
abstract mixin class _$JobProgressCopyWith<$Res> implements $JobProgressCopyWith<$Res> {
  factory _$JobProgressCopyWith(_JobProgress value, $Res Function(_JobProgress) _then) = __$JobProgressCopyWithImpl;
@override @useResult
$Res call({
 int done, int failed, int total
});




}
/// @nodoc
class __$JobProgressCopyWithImpl<$Res>
    implements _$JobProgressCopyWith<$Res> {
  __$JobProgressCopyWithImpl(this._self, this._then);

  final _JobProgress _self;
  final $Res Function(_JobProgress) _then;

/// Create a copy of JobProgress
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? done = null,Object? failed = null,Object? total = null,}) {
  return _then(_JobProgress(
done: null == done ? _self.done : done // ignore: cast_nullable_to_non_nullable
as int,failed: null == failed ? _self.failed : failed // ignore: cast_nullable_to_non_nullable
as int,total: null == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
