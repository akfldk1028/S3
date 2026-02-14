// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'user.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$User {

@JsonKey(name: 'user_id') String get userId; String get plan;// 'free' | 'pro'
 int get credits;@JsonKey(name: 'active_jobs') int get activeJobs;@JsonKey(name: 'rule_slots') RuleSlots get ruleSlots;
/// Create a copy of User
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UserCopyWith<User> get copyWith => _$UserCopyWithImpl<User>(this as User, _$identity);

  /// Serializes this User to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is User&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.plan, plan) || other.plan == plan)&&(identical(other.credits, credits) || other.credits == credits)&&(identical(other.activeJobs, activeJobs) || other.activeJobs == activeJobs)&&(identical(other.ruleSlots, ruleSlots) || other.ruleSlots == ruleSlots));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,userId,plan,credits,activeJobs,ruleSlots);

@override
String toString() {
  return 'User(userId: $userId, plan: $plan, credits: $credits, activeJobs: $activeJobs, ruleSlots: $ruleSlots)';
}


}

/// @nodoc
abstract mixin class $UserCopyWith<$Res>  {
  factory $UserCopyWith(User value, $Res Function(User) _then) = _$UserCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'user_id') String userId, String plan, int credits,@JsonKey(name: 'active_jobs') int activeJobs,@JsonKey(name: 'rule_slots') RuleSlots ruleSlots
});


$RuleSlotsCopyWith<$Res> get ruleSlots;

}
/// @nodoc
class _$UserCopyWithImpl<$Res>
    implements $UserCopyWith<$Res> {
  _$UserCopyWithImpl(this._self, this._then);

  final User _self;
  final $Res Function(User) _then;

/// Create a copy of User
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? userId = null,Object? plan = null,Object? credits = null,Object? activeJobs = null,Object? ruleSlots = null,}) {
  return _then(_self.copyWith(
userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,plan: null == plan ? _self.plan : plan // ignore: cast_nullable_to_non_nullable
as String,credits: null == credits ? _self.credits : credits // ignore: cast_nullable_to_non_nullable
as int,activeJobs: null == activeJobs ? _self.activeJobs : activeJobs // ignore: cast_nullable_to_non_nullable
as int,ruleSlots: null == ruleSlots ? _self.ruleSlots : ruleSlots // ignore: cast_nullable_to_non_nullable
as RuleSlots,
  ));
}
/// Create a copy of User
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$RuleSlotsCopyWith<$Res> get ruleSlots {
  
  return $RuleSlotsCopyWith<$Res>(_self.ruleSlots, (value) {
    return _then(_self.copyWith(ruleSlots: value));
  });
}
}


/// Adds pattern-matching-related methods to [User].
extension UserPatterns on User {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _User value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _User() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _User value)  $default,){
final _that = this;
switch (_that) {
case _User():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _User value)?  $default,){
final _that = this;
switch (_that) {
case _User() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'user_id')  String userId,  String plan,  int credits, @JsonKey(name: 'active_jobs')  int activeJobs, @JsonKey(name: 'rule_slots')  RuleSlots ruleSlots)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _User() when $default != null:
return $default(_that.userId,_that.plan,_that.credits,_that.activeJobs,_that.ruleSlots);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'user_id')  String userId,  String plan,  int credits, @JsonKey(name: 'active_jobs')  int activeJobs, @JsonKey(name: 'rule_slots')  RuleSlots ruleSlots)  $default,) {final _that = this;
switch (_that) {
case _User():
return $default(_that.userId,_that.plan,_that.credits,_that.activeJobs,_that.ruleSlots);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'user_id')  String userId,  String plan,  int credits, @JsonKey(name: 'active_jobs')  int activeJobs, @JsonKey(name: 'rule_slots')  RuleSlots ruleSlots)?  $default,) {final _that = this;
switch (_that) {
case _User() when $default != null:
return $default(_that.userId,_that.plan,_that.credits,_that.activeJobs,_that.ruleSlots);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _User implements User {
  const _User({@JsonKey(name: 'user_id') required this.userId, required this.plan, required this.credits, @JsonKey(name: 'active_jobs') required this.activeJobs, @JsonKey(name: 'rule_slots') required this.ruleSlots});
  factory _User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);

@override@JsonKey(name: 'user_id') final  String userId;
@override final  String plan;
// 'free' | 'pro'
@override final  int credits;
@override@JsonKey(name: 'active_jobs') final  int activeJobs;
@override@JsonKey(name: 'rule_slots') final  RuleSlots ruleSlots;

/// Create a copy of User
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$UserCopyWith<_User> get copyWith => __$UserCopyWithImpl<_User>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$UserToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _User&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.plan, plan) || other.plan == plan)&&(identical(other.credits, credits) || other.credits == credits)&&(identical(other.activeJobs, activeJobs) || other.activeJobs == activeJobs)&&(identical(other.ruleSlots, ruleSlots) || other.ruleSlots == ruleSlots));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,userId,plan,credits,activeJobs,ruleSlots);

@override
String toString() {
  return 'User(userId: $userId, plan: $plan, credits: $credits, activeJobs: $activeJobs, ruleSlots: $ruleSlots)';
}


}

/// @nodoc
abstract mixin class _$UserCopyWith<$Res> implements $UserCopyWith<$Res> {
  factory _$UserCopyWith(_User value, $Res Function(_User) _then) = __$UserCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'user_id') String userId, String plan, int credits,@JsonKey(name: 'active_jobs') int activeJobs,@JsonKey(name: 'rule_slots') RuleSlots ruleSlots
});


@override $RuleSlotsCopyWith<$Res> get ruleSlots;

}
/// @nodoc
class __$UserCopyWithImpl<$Res>
    implements _$UserCopyWith<$Res> {
  __$UserCopyWithImpl(this._self, this._then);

  final _User _self;
  final $Res Function(_User) _then;

/// Create a copy of User
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? userId = null,Object? plan = null,Object? credits = null,Object? activeJobs = null,Object? ruleSlots = null,}) {
  return _then(_User(
userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,plan: null == plan ? _self.plan : plan // ignore: cast_nullable_to_non_nullable
as String,credits: null == credits ? _self.credits : credits // ignore: cast_nullable_to_non_nullable
as int,activeJobs: null == activeJobs ? _self.activeJobs : activeJobs // ignore: cast_nullable_to_non_nullable
as int,ruleSlots: null == ruleSlots ? _self.ruleSlots : ruleSlots // ignore: cast_nullable_to_non_nullable
as RuleSlots,
  ));
}

/// Create a copy of User
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$RuleSlotsCopyWith<$Res> get ruleSlots {
  
  return $RuleSlotsCopyWith<$Res>(_self.ruleSlots, (value) {
    return _then(_self.copyWith(ruleSlots: value));
  });
}
}


/// @nodoc
mixin _$RuleSlots {

 int get used; int get max;
/// Create a copy of RuleSlots
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RuleSlotsCopyWith<RuleSlots> get copyWith => _$RuleSlotsCopyWithImpl<RuleSlots>(this as RuleSlots, _$identity);

  /// Serializes this RuleSlots to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RuleSlots&&(identical(other.used, used) || other.used == used)&&(identical(other.max, max) || other.max == max));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,used,max);

@override
String toString() {
  return 'RuleSlots(used: $used, max: $max)';
}


}

/// @nodoc
abstract mixin class $RuleSlotsCopyWith<$Res>  {
  factory $RuleSlotsCopyWith(RuleSlots value, $Res Function(RuleSlots) _then) = _$RuleSlotsCopyWithImpl;
@useResult
$Res call({
 int used, int max
});




}
/// @nodoc
class _$RuleSlotsCopyWithImpl<$Res>
    implements $RuleSlotsCopyWith<$Res> {
  _$RuleSlotsCopyWithImpl(this._self, this._then);

  final RuleSlots _self;
  final $Res Function(RuleSlots) _then;

/// Create a copy of RuleSlots
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? used = null,Object? max = null,}) {
  return _then(_self.copyWith(
used: null == used ? _self.used : used // ignore: cast_nullable_to_non_nullable
as int,max: null == max ? _self.max : max // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [RuleSlots].
extension RuleSlotsPatterns on RuleSlots {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RuleSlots value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RuleSlots() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RuleSlots value)  $default,){
final _that = this;
switch (_that) {
case _RuleSlots():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RuleSlots value)?  $default,){
final _that = this;
switch (_that) {
case _RuleSlots() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int used,  int max)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RuleSlots() when $default != null:
return $default(_that.used,_that.max);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int used,  int max)  $default,) {final _that = this;
switch (_that) {
case _RuleSlots():
return $default(_that.used,_that.max);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int used,  int max)?  $default,) {final _that = this;
switch (_that) {
case _RuleSlots() when $default != null:
return $default(_that.used,_that.max);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _RuleSlots implements RuleSlots {
  const _RuleSlots({required this.used, required this.max});
  factory _RuleSlots.fromJson(Map<String, dynamic> json) => _$RuleSlotsFromJson(json);

@override final  int used;
@override final  int max;

/// Create a copy of RuleSlots
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RuleSlotsCopyWith<_RuleSlots> get copyWith => __$RuleSlotsCopyWithImpl<_RuleSlots>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$RuleSlotsToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _RuleSlots&&(identical(other.used, used) || other.used == used)&&(identical(other.max, max) || other.max == max));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,used,max);

@override
String toString() {
  return 'RuleSlots(used: $used, max: $max)';
}


}

/// @nodoc
abstract mixin class _$RuleSlotsCopyWith<$Res> implements $RuleSlotsCopyWith<$Res> {
  factory _$RuleSlotsCopyWith(_RuleSlots value, $Res Function(_RuleSlots) _then) = __$RuleSlotsCopyWithImpl;
@override @useResult
$Res call({
 int used, int max
});




}
/// @nodoc
class __$RuleSlotsCopyWithImpl<$Res>
    implements _$RuleSlotsCopyWith<$Res> {
  __$RuleSlotsCopyWithImpl(this._self, this._then);

  final _RuleSlots _self;
  final $Res Function(_RuleSlots) _then;

/// Create a copy of RuleSlots
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? used = null,Object? max = null,}) {
  return _then(_RuleSlots(
used: null == used ? _self.used : used // ignore: cast_nullable_to_non_nullable
as int,max: null == max ? _self.max : max // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
