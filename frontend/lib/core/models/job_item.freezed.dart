// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'job_item.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$JobItem {

 int get idx;@JsonKey(name: 'result_url') String get resultUrl;@JsonKey(name: 'preview_url') String get previewUrl;
/// Create a copy of JobItem
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$JobItemCopyWith<JobItem> get copyWith => _$JobItemCopyWithImpl<JobItem>(this as JobItem, _$identity);

  /// Serializes this JobItem to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is JobItem&&(identical(other.idx, idx) || other.idx == idx)&&(identical(other.resultUrl, resultUrl) || other.resultUrl == resultUrl)&&(identical(other.previewUrl, previewUrl) || other.previewUrl == previewUrl));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,idx,resultUrl,previewUrl);

@override
String toString() {
  return 'JobItem(idx: $idx, resultUrl: $resultUrl, previewUrl: $previewUrl)';
}


}

/// @nodoc
abstract mixin class $JobItemCopyWith<$Res>  {
  factory $JobItemCopyWith(JobItem value, $Res Function(JobItem) _then) = _$JobItemCopyWithImpl;
@useResult
$Res call({
 int idx,@JsonKey(name: 'result_url') String resultUrl,@JsonKey(name: 'preview_url') String previewUrl
});




}
/// @nodoc
class _$JobItemCopyWithImpl<$Res>
    implements $JobItemCopyWith<$Res> {
  _$JobItemCopyWithImpl(this._self, this._then);

  final JobItem _self;
  final $Res Function(JobItem) _then;

/// Create a copy of JobItem
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? idx = null,Object? resultUrl = null,Object? previewUrl = null,}) {
  return _then(_self.copyWith(
idx: null == idx ? _self.idx : idx // ignore: cast_nullable_to_non_nullable
as int,resultUrl: null == resultUrl ? _self.resultUrl : resultUrl // ignore: cast_nullable_to_non_nullable
as String,previewUrl: null == previewUrl ? _self.previewUrl : previewUrl // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [JobItem].
extension JobItemPatterns on JobItem {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _JobItem value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _JobItem() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _JobItem value)  $default,){
final _that = this;
switch (_that) {
case _JobItem():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _JobItem value)?  $default,){
final _that = this;
switch (_that) {
case _JobItem() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int idx, @JsonKey(name: 'result_url')  String resultUrl, @JsonKey(name: 'preview_url')  String previewUrl)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _JobItem() when $default != null:
return $default(_that.idx,_that.resultUrl,_that.previewUrl);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int idx, @JsonKey(name: 'result_url')  String resultUrl, @JsonKey(name: 'preview_url')  String previewUrl)  $default,) {final _that = this;
switch (_that) {
case _JobItem():
return $default(_that.idx,_that.resultUrl,_that.previewUrl);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int idx, @JsonKey(name: 'result_url')  String resultUrl, @JsonKey(name: 'preview_url')  String previewUrl)?  $default,) {final _that = this;
switch (_that) {
case _JobItem() when $default != null:
return $default(_that.idx,_that.resultUrl,_that.previewUrl);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _JobItem implements JobItem {
  const _JobItem({required this.idx, @JsonKey(name: 'result_url') required this.resultUrl, @JsonKey(name: 'preview_url') required this.previewUrl});
  factory _JobItem.fromJson(Map<String, dynamic> json) => _$JobItemFromJson(json);

@override final  int idx;
@override@JsonKey(name: 'result_url') final  String resultUrl;
@override@JsonKey(name: 'preview_url') final  String previewUrl;

/// Create a copy of JobItem
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$JobItemCopyWith<_JobItem> get copyWith => __$JobItemCopyWithImpl<_JobItem>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$JobItemToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _JobItem&&(identical(other.idx, idx) || other.idx == idx)&&(identical(other.resultUrl, resultUrl) || other.resultUrl == resultUrl)&&(identical(other.previewUrl, previewUrl) || other.previewUrl == previewUrl));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,idx,resultUrl,previewUrl);

@override
String toString() {
  return 'JobItem(idx: $idx, resultUrl: $resultUrl, previewUrl: $previewUrl)';
}


}

/// @nodoc
abstract mixin class _$JobItemCopyWith<$Res> implements $JobItemCopyWith<$Res> {
  factory _$JobItemCopyWith(_JobItem value, $Res Function(_JobItem) _then) = __$JobItemCopyWithImpl;
@override @useResult
$Res call({
 int idx,@JsonKey(name: 'result_url') String resultUrl,@JsonKey(name: 'preview_url') String previewUrl
});




}
/// @nodoc
class __$JobItemCopyWithImpl<$Res>
    implements _$JobItemCopyWith<$Res> {
  __$JobItemCopyWithImpl(this._self, this._then);

  final _JobItem _self;
  final $Res Function(_JobItem) _then;

/// Create a copy of JobItem
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? idx = null,Object? resultUrl = null,Object? previewUrl = null,}) {
  return _then(_JobItem(
idx: null == idx ? _self.idx : idx // ignore: cast_nullable_to_non_nullable
as int,resultUrl: null == resultUrl ? _self.resultUrl : resultUrl // ignore: cast_nullable_to_non_nullable
as String,previewUrl: null == previewUrl ? _self.previewUrl : previewUrl // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
