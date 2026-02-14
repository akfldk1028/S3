// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'rule.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Rule {

 String get id; String get name;@JsonKey(name: 'preset_id') String get presetId;@JsonKey(name: 'created_at') String get createdAt;// Detail/create view fields (optional for list view)
 Map<String, ConceptAction>? get concepts; List<String>? get protect;
/// Create a copy of Rule
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RuleCopyWith<Rule> get copyWith => _$RuleCopyWithImpl<Rule>(this as Rule, _$identity);

  /// Serializes this Rule to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Rule&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.presetId, presetId) || other.presetId == presetId)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&const DeepCollectionEquality().equals(other.concepts, concepts)&&const DeepCollectionEquality().equals(other.protect, protect));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,presetId,createdAt,const DeepCollectionEquality().hash(concepts),const DeepCollectionEquality().hash(protect));

@override
String toString() {
  return 'Rule(id: $id, name: $name, presetId: $presetId, createdAt: $createdAt, concepts: $concepts, protect: $protect)';
}


}

/// @nodoc
abstract mixin class $RuleCopyWith<$Res>  {
  factory $RuleCopyWith(Rule value, $Res Function(Rule) _then) = _$RuleCopyWithImpl;
@useResult
$Res call({
 String id, String name,@JsonKey(name: 'preset_id') String presetId,@JsonKey(name: 'created_at') String createdAt, Map<String, ConceptAction>? concepts, List<String>? protect
});




}
/// @nodoc
class _$RuleCopyWithImpl<$Res>
    implements $RuleCopyWith<$Res> {
  _$RuleCopyWithImpl(this._self, this._then);

  final Rule _self;
  final $Res Function(Rule) _then;

/// Create a copy of Rule
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? presetId = null,Object? createdAt = null,Object? concepts = freezed,Object? protect = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,presetId: null == presetId ? _self.presetId : presetId // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as String,concepts: freezed == concepts ? _self.concepts : concepts // ignore: cast_nullable_to_non_nullable
as Map<String, ConceptAction>?,protect: freezed == protect ? _self.protect : protect // ignore: cast_nullable_to_non_nullable
as List<String>?,
  ));
}

}


/// Adds pattern-matching-related methods to [Rule].
extension RulePatterns on Rule {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Rule value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Rule() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Rule value)  $default,){
final _that = this;
switch (_that) {
case _Rule():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Rule value)?  $default,){
final _that = this;
switch (_that) {
case _Rule() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name, @JsonKey(name: 'preset_id')  String presetId, @JsonKey(name: 'created_at')  String createdAt,  Map<String, ConceptAction>? concepts,  List<String>? protect)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Rule() when $default != null:
return $default(_that.id,_that.name,_that.presetId,_that.createdAt,_that.concepts,_that.protect);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name, @JsonKey(name: 'preset_id')  String presetId, @JsonKey(name: 'created_at')  String createdAt,  Map<String, ConceptAction>? concepts,  List<String>? protect)  $default,) {final _that = this;
switch (_that) {
case _Rule():
return $default(_that.id,_that.name,_that.presetId,_that.createdAt,_that.concepts,_that.protect);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name, @JsonKey(name: 'preset_id')  String presetId, @JsonKey(name: 'created_at')  String createdAt,  Map<String, ConceptAction>? concepts,  List<String>? protect)?  $default,) {final _that = this;
switch (_that) {
case _Rule() when $default != null:
return $default(_that.id,_that.name,_that.presetId,_that.createdAt,_that.concepts,_that.protect);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Rule implements Rule {
  const _Rule({required this.id, required this.name, @JsonKey(name: 'preset_id') required this.presetId, @JsonKey(name: 'created_at') required this.createdAt, final  Map<String, ConceptAction>? concepts, final  List<String>? protect}): _concepts = concepts,_protect = protect;
  factory _Rule.fromJson(Map<String, dynamic> json) => _$RuleFromJson(json);

@override final  String id;
@override final  String name;
@override@JsonKey(name: 'preset_id') final  String presetId;
@override@JsonKey(name: 'created_at') final  String createdAt;
// Detail/create view fields (optional for list view)
 final  Map<String, ConceptAction>? _concepts;
// Detail/create view fields (optional for list view)
@override Map<String, ConceptAction>? get concepts {
  final value = _concepts;
  if (value == null) return null;
  if (_concepts is EqualUnmodifiableMapView) return _concepts;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(value);
}

 final  List<String>? _protect;
@override List<String>? get protect {
  final value = _protect;
  if (value == null) return null;
  if (_protect is EqualUnmodifiableListView) return _protect;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}


/// Create a copy of Rule
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RuleCopyWith<_Rule> get copyWith => __$RuleCopyWithImpl<_Rule>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$RuleToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Rule&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.presetId, presetId) || other.presetId == presetId)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&const DeepCollectionEquality().equals(other._concepts, _concepts)&&const DeepCollectionEquality().equals(other._protect, _protect));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,presetId,createdAt,const DeepCollectionEquality().hash(_concepts),const DeepCollectionEquality().hash(_protect));

@override
String toString() {
  return 'Rule(id: $id, name: $name, presetId: $presetId, createdAt: $createdAt, concepts: $concepts, protect: $protect)';
}


}

/// @nodoc
abstract mixin class _$RuleCopyWith<$Res> implements $RuleCopyWith<$Res> {
  factory _$RuleCopyWith(_Rule value, $Res Function(_Rule) _then) = __$RuleCopyWithImpl;
@override @useResult
$Res call({
 String id, String name,@JsonKey(name: 'preset_id') String presetId,@JsonKey(name: 'created_at') String createdAt, Map<String, ConceptAction>? concepts, List<String>? protect
});




}
/// @nodoc
class __$RuleCopyWithImpl<$Res>
    implements _$RuleCopyWith<$Res> {
  __$RuleCopyWithImpl(this._self, this._then);

  final _Rule _self;
  final $Res Function(_Rule) _then;

/// Create a copy of Rule
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? presetId = null,Object? createdAt = null,Object? concepts = freezed,Object? protect = freezed,}) {
  return _then(_Rule(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,presetId: null == presetId ? _self.presetId : presetId // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as String,concepts: freezed == concepts ? _self._concepts : concepts // ignore: cast_nullable_to_non_nullable
as Map<String, ConceptAction>?,protect: freezed == protect ? _self._protect : protect // ignore: cast_nullable_to_non_nullable
as List<String>?,
  ));
}


}


/// @nodoc
mixin _$ConceptAction {

 String get action;// 'recolor' | 'tone' | 'texture' | 'remove'
 String? get value;
/// Create a copy of ConceptAction
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ConceptActionCopyWith<ConceptAction> get copyWith => _$ConceptActionCopyWithImpl<ConceptAction>(this as ConceptAction, _$identity);

  /// Serializes this ConceptAction to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ConceptAction&&(identical(other.action, action) || other.action == action)&&(identical(other.value, value) || other.value == value));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,action,value);

@override
String toString() {
  return 'ConceptAction(action: $action, value: $value)';
}


}

/// @nodoc
abstract mixin class $ConceptActionCopyWith<$Res>  {
  factory $ConceptActionCopyWith(ConceptAction value, $Res Function(ConceptAction) _then) = _$ConceptActionCopyWithImpl;
@useResult
$Res call({
 String action, String? value
});




}
/// @nodoc
class _$ConceptActionCopyWithImpl<$Res>
    implements $ConceptActionCopyWith<$Res> {
  _$ConceptActionCopyWithImpl(this._self, this._then);

  final ConceptAction _self;
  final $Res Function(ConceptAction) _then;

/// Create a copy of ConceptAction
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? action = null,Object? value = freezed,}) {
  return _then(_self.copyWith(
action: null == action ? _self.action : action // ignore: cast_nullable_to_non_nullable
as String,value: freezed == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [ConceptAction].
extension ConceptActionPatterns on ConceptAction {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ConceptAction value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ConceptAction() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ConceptAction value)  $default,){
final _that = this;
switch (_that) {
case _ConceptAction():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ConceptAction value)?  $default,){
final _that = this;
switch (_that) {
case _ConceptAction() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String action,  String? value)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ConceptAction() when $default != null:
return $default(_that.action,_that.value);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String action,  String? value)  $default,) {final _that = this;
switch (_that) {
case _ConceptAction():
return $default(_that.action,_that.value);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String action,  String? value)?  $default,) {final _that = this;
switch (_that) {
case _ConceptAction() when $default != null:
return $default(_that.action,_that.value);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ConceptAction implements ConceptAction {
  const _ConceptAction({required this.action, this.value});
  factory _ConceptAction.fromJson(Map<String, dynamic> json) => _$ConceptActionFromJson(json);

@override final  String action;
// 'recolor' | 'tone' | 'texture' | 'remove'
@override final  String? value;

/// Create a copy of ConceptAction
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ConceptActionCopyWith<_ConceptAction> get copyWith => __$ConceptActionCopyWithImpl<_ConceptAction>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ConceptActionToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ConceptAction&&(identical(other.action, action) || other.action == action)&&(identical(other.value, value) || other.value == value));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,action,value);

@override
String toString() {
  return 'ConceptAction(action: $action, value: $value)';
}


}

/// @nodoc
abstract mixin class _$ConceptActionCopyWith<$Res> implements $ConceptActionCopyWith<$Res> {
  factory _$ConceptActionCopyWith(_ConceptAction value, $Res Function(_ConceptAction) _then) = __$ConceptActionCopyWithImpl;
@override @useResult
$Res call({
 String action, String? value
});




}
/// @nodoc
class __$ConceptActionCopyWithImpl<$Res>
    implements _$ConceptActionCopyWith<$Res> {
  __$ConceptActionCopyWithImpl(this._self, this._then);

  final _ConceptAction _self;
  final $Res Function(_ConceptAction) _then;

/// Create a copy of ConceptAction
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? action = null,Object? value = freezed,}) {
  return _then(_ConceptAction(
action: null == action ? _self.action : action // ignore: cast_nullable_to_non_nullable
as String,value: freezed == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
