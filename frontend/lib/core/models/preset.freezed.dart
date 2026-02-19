// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'preset.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Preset {

 String get id; String get name;@JsonKey(name: 'concept_count') int get conceptCount;// Detail view fields (optional for list view)
 List<String>? get concepts;@JsonKey(name: 'protect_defaults') List<String>? get protectDefaults;@JsonKey(name: 'output_templates') List<OutputTemplate>? get outputTemplates;
/// Create a copy of Preset
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PresetCopyWith<Preset> get copyWith => _$PresetCopyWithImpl<Preset>(this as Preset, _$identity);

  /// Serializes this Preset to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Preset&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.conceptCount, conceptCount) || other.conceptCount == conceptCount)&&const DeepCollectionEquality().equals(other.concepts, concepts)&&const DeepCollectionEquality().equals(other.protectDefaults, protectDefaults)&&const DeepCollectionEquality().equals(other.outputTemplates, outputTemplates));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,conceptCount,const DeepCollectionEquality().hash(concepts),const DeepCollectionEquality().hash(protectDefaults),const DeepCollectionEquality().hash(outputTemplates));

@override
String toString() {
  return 'Preset(id: $id, name: $name, conceptCount: $conceptCount, concepts: $concepts, protectDefaults: $protectDefaults, outputTemplates: $outputTemplates)';
}


}

/// @nodoc
abstract mixin class $PresetCopyWith<$Res>  {
  factory $PresetCopyWith(Preset value, $Res Function(Preset) _then) = _$PresetCopyWithImpl;
@useResult
$Res call({
 String id, String name,@JsonKey(name: 'concept_count') int conceptCount, List<String>? concepts,@JsonKey(name: 'protect_defaults') List<String>? protectDefaults,@JsonKey(name: 'output_templates') List<OutputTemplate>? outputTemplates
});




}
/// @nodoc
class _$PresetCopyWithImpl<$Res>
    implements $PresetCopyWith<$Res> {
  _$PresetCopyWithImpl(this._self, this._then);

  final Preset _self;
  final $Res Function(Preset) _then;

/// Create a copy of Preset
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? conceptCount = null,Object? concepts = freezed,Object? protectDefaults = freezed,Object? outputTemplates = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,conceptCount: null == conceptCount ? _self.conceptCount : conceptCount // ignore: cast_nullable_to_non_nullable
as int,concepts: freezed == concepts ? _self.concepts : concepts // ignore: cast_nullable_to_non_nullable
as List<String>?,protectDefaults: freezed == protectDefaults ? _self.protectDefaults : protectDefaults // ignore: cast_nullable_to_non_nullable
as List<String>?,outputTemplates: freezed == outputTemplates ? _self.outputTemplates : outputTemplates // ignore: cast_nullable_to_non_nullable
as List<OutputTemplate>?,
  ));
}

}


/// Adds pattern-matching-related methods to [Preset].
extension PresetPatterns on Preset {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Preset value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Preset() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Preset value)  $default,){
final _that = this;
switch (_that) {
case _Preset():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Preset value)?  $default,){
final _that = this;
switch (_that) {
case _Preset() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name, @JsonKey(name: 'concept_count')  int conceptCount,  List<String>? concepts, @JsonKey(name: 'protect_defaults')  List<String>? protectDefaults, @JsonKey(name: 'output_templates')  List<OutputTemplate>? outputTemplates)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Preset() when $default != null:
return $default(_that.id,_that.name,_that.conceptCount,_that.concepts,_that.protectDefaults,_that.outputTemplates);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name, @JsonKey(name: 'concept_count')  int conceptCount,  List<String>? concepts, @JsonKey(name: 'protect_defaults')  List<String>? protectDefaults, @JsonKey(name: 'output_templates')  List<OutputTemplate>? outputTemplates)  $default,) {final _that = this;
switch (_that) {
case _Preset():
return $default(_that.id,_that.name,_that.conceptCount,_that.concepts,_that.protectDefaults,_that.outputTemplates);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name, @JsonKey(name: 'concept_count')  int conceptCount,  List<String>? concepts, @JsonKey(name: 'protect_defaults')  List<String>? protectDefaults, @JsonKey(name: 'output_templates')  List<OutputTemplate>? outputTemplates)?  $default,) {final _that = this;
switch (_that) {
case _Preset() when $default != null:
return $default(_that.id,_that.name,_that.conceptCount,_that.concepts,_that.protectDefaults,_that.outputTemplates);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Preset implements Preset {
  const _Preset({required this.id, required this.name, @JsonKey(name: 'concept_count') this.conceptCount = 0, final  List<String>? concepts, @JsonKey(name: 'protect_defaults') final  List<String>? protectDefaults, @JsonKey(name: 'output_templates') final  List<OutputTemplate>? outputTemplates}): _concepts = concepts,_protectDefaults = protectDefaults,_outputTemplates = outputTemplates;
  factory _Preset.fromJson(Map<String, dynamic> json) => _$PresetFromJson(json);

@override final  String id;
@override final  String name;
@override@JsonKey(name: 'concept_count') final  int conceptCount;
// Detail view fields (optional for list view)
 final  List<String>? _concepts;
// Detail view fields (optional for list view)
@override List<String>? get concepts {
  final value = _concepts;
  if (value == null) return null;
  if (_concepts is EqualUnmodifiableListView) return _concepts;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}

 final  List<String>? _protectDefaults;
@override@JsonKey(name: 'protect_defaults') List<String>? get protectDefaults {
  final value = _protectDefaults;
  if (value == null) return null;
  if (_protectDefaults is EqualUnmodifiableListView) return _protectDefaults;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}

 final  List<OutputTemplate>? _outputTemplates;
@override@JsonKey(name: 'output_templates') List<OutputTemplate>? get outputTemplates {
  final value = _outputTemplates;
  if (value == null) return null;
  if (_outputTemplates is EqualUnmodifiableListView) return _outputTemplates;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}


/// Create a copy of Preset
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PresetCopyWith<_Preset> get copyWith => __$PresetCopyWithImpl<_Preset>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PresetToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Preset&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.conceptCount, conceptCount) || other.conceptCount == conceptCount)&&const DeepCollectionEquality().equals(other._concepts, _concepts)&&const DeepCollectionEquality().equals(other._protectDefaults, _protectDefaults)&&const DeepCollectionEquality().equals(other._outputTemplates, _outputTemplates));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,conceptCount,const DeepCollectionEquality().hash(_concepts),const DeepCollectionEquality().hash(_protectDefaults),const DeepCollectionEquality().hash(_outputTemplates));

@override
String toString() {
  return 'Preset(id: $id, name: $name, conceptCount: $conceptCount, concepts: $concepts, protectDefaults: $protectDefaults, outputTemplates: $outputTemplates)';
}


}

/// @nodoc
abstract mixin class _$PresetCopyWith<$Res> implements $PresetCopyWith<$Res> {
  factory _$PresetCopyWith(_Preset value, $Res Function(_Preset) _then) = __$PresetCopyWithImpl;
@override @useResult
$Res call({
 String id, String name,@JsonKey(name: 'concept_count') int conceptCount, List<String>? concepts,@JsonKey(name: 'protect_defaults') List<String>? protectDefaults,@JsonKey(name: 'output_templates') List<OutputTemplate>? outputTemplates
});




}
/// @nodoc
class __$PresetCopyWithImpl<$Res>
    implements _$PresetCopyWith<$Res> {
  __$PresetCopyWithImpl(this._self, this._then);

  final _Preset _self;
  final $Res Function(_Preset) _then;

/// Create a copy of Preset
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? conceptCount = null,Object? concepts = freezed,Object? protectDefaults = freezed,Object? outputTemplates = freezed,}) {
  return _then(_Preset(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,conceptCount: null == conceptCount ? _self.conceptCount : conceptCount // ignore: cast_nullable_to_non_nullable
as int,concepts: freezed == concepts ? _self._concepts : concepts // ignore: cast_nullable_to_non_nullable
as List<String>?,protectDefaults: freezed == protectDefaults ? _self._protectDefaults : protectDefaults // ignore: cast_nullable_to_non_nullable
as List<String>?,outputTemplates: freezed == outputTemplates ? _self._outputTemplates : outputTemplates // ignore: cast_nullable_to_non_nullable
as List<OutputTemplate>?,
  ));
}


}


/// @nodoc
mixin _$OutputTemplate {

 String get id; String get name; String get description;
/// Create a copy of OutputTemplate
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OutputTemplateCopyWith<OutputTemplate> get copyWith => _$OutputTemplateCopyWithImpl<OutputTemplate>(this as OutputTemplate, _$identity);

  /// Serializes this OutputTemplate to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OutputTemplate&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.description, description) || other.description == description));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,description);

@override
String toString() {
  return 'OutputTemplate(id: $id, name: $name, description: $description)';
}


}

/// @nodoc
abstract mixin class $OutputTemplateCopyWith<$Res>  {
  factory $OutputTemplateCopyWith(OutputTemplate value, $Res Function(OutputTemplate) _then) = _$OutputTemplateCopyWithImpl;
@useResult
$Res call({
 String id, String name, String description
});




}
/// @nodoc
class _$OutputTemplateCopyWithImpl<$Res>
    implements $OutputTemplateCopyWith<$Res> {
  _$OutputTemplateCopyWithImpl(this._self, this._then);

  final OutputTemplate _self;
  final $Res Function(OutputTemplate) _then;

/// Create a copy of OutputTemplate
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? description = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [OutputTemplate].
extension OutputTemplatePatterns on OutputTemplate {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _OutputTemplate value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _OutputTemplate() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _OutputTemplate value)  $default,){
final _that = this;
switch (_that) {
case _OutputTemplate():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _OutputTemplate value)?  $default,){
final _that = this;
switch (_that) {
case _OutputTemplate() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  String description)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _OutputTemplate() when $default != null:
return $default(_that.id,_that.name,_that.description);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  String description)  $default,) {final _that = this;
switch (_that) {
case _OutputTemplate():
return $default(_that.id,_that.name,_that.description);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  String description)?  $default,) {final _that = this;
switch (_that) {
case _OutputTemplate() when $default != null:
return $default(_that.id,_that.name,_that.description);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _OutputTemplate implements OutputTemplate {
  const _OutputTemplate({required this.id, required this.name, required this.description});
  factory _OutputTemplate.fromJson(Map<String, dynamic> json) => _$OutputTemplateFromJson(json);

@override final  String id;
@override final  String name;
@override final  String description;

/// Create a copy of OutputTemplate
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$OutputTemplateCopyWith<_OutputTemplate> get copyWith => __$OutputTemplateCopyWithImpl<_OutputTemplate>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$OutputTemplateToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _OutputTemplate&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.description, description) || other.description == description));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,description);

@override
String toString() {
  return 'OutputTemplate(id: $id, name: $name, description: $description)';
}


}

/// @nodoc
abstract mixin class _$OutputTemplateCopyWith<$Res> implements $OutputTemplateCopyWith<$Res> {
  factory _$OutputTemplateCopyWith(_OutputTemplate value, $Res Function(_OutputTemplate) _then) = __$OutputTemplateCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, String description
});




}
/// @nodoc
class __$OutputTemplateCopyWithImpl<$Res>
    implements _$OutputTemplateCopyWith<$Res> {
  __$OutputTemplateCopyWithImpl(this._self, this._then);

  final _OutputTemplate _self;
  final $Res Function(_OutputTemplate) _then;

/// Create a copy of OutputTemplate
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? description = null,}) {
  return _then(_OutputTemplate(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
