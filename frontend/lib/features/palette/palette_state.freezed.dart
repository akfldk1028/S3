// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'palette_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$PaletteState {

/// Map of concept name to selected instance index (1-based).
/// If a concept is in this map, it's considered "selected".
/// Example: {'sofa': 2, 'wall': 1} means sofa #2 and wall #1 are selected.
 Map<String, int> get selectedConcepts;/// Set of concept names that have "protect" enabled.
/// Protected concepts won't be modified during job processing.
/// Example: {'sofa', 'floor'} means sofa and floor are protected.
 Set<String> get protectConcepts;
/// Create a copy of PaletteState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PaletteStateCopyWith<PaletteState> get copyWith => _$PaletteStateCopyWithImpl<PaletteState>(this as PaletteState, _$identity);

  /// Serializes this PaletteState to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PaletteState&&const DeepCollectionEquality().equals(other.selectedConcepts, selectedConcepts)&&const DeepCollectionEquality().equals(other.protectConcepts, protectConcepts));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(selectedConcepts),const DeepCollectionEquality().hash(protectConcepts));

@override
String toString() {
  return 'PaletteState(selectedConcepts: $selectedConcepts, protectConcepts: $protectConcepts)';
}


}

/// @nodoc
abstract mixin class $PaletteStateCopyWith<$Res>  {
  factory $PaletteStateCopyWith(PaletteState value, $Res Function(PaletteState) _then) = _$PaletteStateCopyWithImpl;
@useResult
$Res call({
 Map<String, int> selectedConcepts, Set<String> protectConcepts
});




}
/// @nodoc
class _$PaletteStateCopyWithImpl<$Res>
    implements $PaletteStateCopyWith<$Res> {
  _$PaletteStateCopyWithImpl(this._self, this._then);

  final PaletteState _self;
  final $Res Function(PaletteState) _then;

/// Create a copy of PaletteState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? selectedConcepts = null,Object? protectConcepts = null,}) {
  return _then(_self.copyWith(
selectedConcepts: null == selectedConcepts ? _self.selectedConcepts : selectedConcepts // ignore: cast_nullable_to_non_nullable
as Map<String, int>,protectConcepts: null == protectConcepts ? _self.protectConcepts : protectConcepts // ignore: cast_nullable_to_non_nullable
as Set<String>,
  ));
}

}


/// Adds pattern-matching-related methods to [PaletteState].
extension PaletteStatePatterns on PaletteState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PaletteState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PaletteState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PaletteState value)  $default,){
final _that = this;
switch (_that) {
case _PaletteState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PaletteState value)?  $default,){
final _that = this;
switch (_that) {
case _PaletteState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( Map<String, int> selectedConcepts,  Set<String> protectConcepts)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PaletteState() when $default != null:
return $default(_that.selectedConcepts,_that.protectConcepts);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( Map<String, int> selectedConcepts,  Set<String> protectConcepts)  $default,) {final _that = this;
switch (_that) {
case _PaletteState():
return $default(_that.selectedConcepts,_that.protectConcepts);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( Map<String, int> selectedConcepts,  Set<String> protectConcepts)?  $default,) {final _that = this;
switch (_that) {
case _PaletteState() when $default != null:
return $default(_that.selectedConcepts,_that.protectConcepts);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PaletteState implements PaletteState {
  const _PaletteState({final  Map<String, int> selectedConcepts = const {}, final  Set<String> protectConcepts = const {}}): _selectedConcepts = selectedConcepts,_protectConcepts = protectConcepts;
  factory _PaletteState.fromJson(Map<String, dynamic> json) => _$PaletteStateFromJson(json);

/// Map of concept name to selected instance index (1-based).
/// If a concept is in this map, it's considered "selected".
/// Example: {'sofa': 2, 'wall': 1} means sofa #2 and wall #1 are selected.
 final  Map<String, int> _selectedConcepts;
/// Map of concept name to selected instance index (1-based).
/// If a concept is in this map, it's considered "selected".
/// Example: {'sofa': 2, 'wall': 1} means sofa #2 and wall #1 are selected.
@override@JsonKey() Map<String, int> get selectedConcepts {
  if (_selectedConcepts is EqualUnmodifiableMapView) return _selectedConcepts;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_selectedConcepts);
}

/// Set of concept names that have "protect" enabled.
/// Protected concepts won't be modified during job processing.
/// Example: {'sofa', 'floor'} means sofa and floor are protected.
 final  Set<String> _protectConcepts;
/// Set of concept names that have "protect" enabled.
/// Protected concepts won't be modified during job processing.
/// Example: {'sofa', 'floor'} means sofa and floor are protected.
@override@JsonKey() Set<String> get protectConcepts {
  if (_protectConcepts is EqualUnmodifiableSetView) return _protectConcepts;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableSetView(_protectConcepts);
}


/// Create a copy of PaletteState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PaletteStateCopyWith<_PaletteState> get copyWith => __$PaletteStateCopyWithImpl<_PaletteState>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PaletteStateToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PaletteState&&const DeepCollectionEquality().equals(other._selectedConcepts, _selectedConcepts)&&const DeepCollectionEquality().equals(other._protectConcepts, _protectConcepts));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_selectedConcepts),const DeepCollectionEquality().hash(_protectConcepts));

@override
String toString() {
  return 'PaletteState(selectedConcepts: $selectedConcepts, protectConcepts: $protectConcepts)';
}


}

/// @nodoc
abstract mixin class _$PaletteStateCopyWith<$Res> implements $PaletteStateCopyWith<$Res> {
  factory _$PaletteStateCopyWith(_PaletteState value, $Res Function(_PaletteState) _then) = __$PaletteStateCopyWithImpl;
@override @useResult
$Res call({
 Map<String, int> selectedConcepts, Set<String> protectConcepts
});




}
/// @nodoc
class __$PaletteStateCopyWithImpl<$Res>
    implements _$PaletteStateCopyWith<$Res> {
  __$PaletteStateCopyWithImpl(this._self, this._then);

  final _PaletteState _self;
  final $Res Function(_PaletteState) _then;

/// Create a copy of PaletteState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? selectedConcepts = null,Object? protectConcepts = null,}) {
  return _then(_PaletteState(
selectedConcepts: null == selectedConcepts ? _self._selectedConcepts : selectedConcepts // ignore: cast_nullable_to_non_nullable
as Map<String, int>,protectConcepts: null == protectConcepts ? _self._protectConcepts : protectConcepts // ignore: cast_nullable_to_non_nullable
as Set<String>,
  ));
}


}

// dart format on
