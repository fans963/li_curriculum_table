// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'classroom_availability.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ClassroomAvailability {

 String get classroomName; List<bool> get availability;// List of 5 bools for the sessions
 bool get hasNoClassesThisTerm;
/// Create a copy of ClassroomAvailability
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ClassroomAvailabilityCopyWith<ClassroomAvailability> get copyWith => _$ClassroomAvailabilityCopyWithImpl<ClassroomAvailability>(this as ClassroomAvailability, _$identity);

  /// Serializes this ClassroomAvailability to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ClassroomAvailability&&(identical(other.classroomName, classroomName) || other.classroomName == classroomName)&&const DeepCollectionEquality().equals(other.availability, availability)&&(identical(other.hasNoClassesThisTerm, hasNoClassesThisTerm) || other.hasNoClassesThisTerm == hasNoClassesThisTerm));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,classroomName,const DeepCollectionEquality().hash(availability),hasNoClassesThisTerm);

@override
String toString() {
  return 'ClassroomAvailability(classroomName: $classroomName, availability: $availability, hasNoClassesThisTerm: $hasNoClassesThisTerm)';
}


}

/// @nodoc
abstract mixin class $ClassroomAvailabilityCopyWith<$Res>  {
  factory $ClassroomAvailabilityCopyWith(ClassroomAvailability value, $Res Function(ClassroomAvailability) _then) = _$ClassroomAvailabilityCopyWithImpl;
@useResult
$Res call({
 String classroomName, List<bool> availability, bool hasNoClassesThisTerm
});




}
/// @nodoc
class _$ClassroomAvailabilityCopyWithImpl<$Res>
    implements $ClassroomAvailabilityCopyWith<$Res> {
  _$ClassroomAvailabilityCopyWithImpl(this._self, this._then);

  final ClassroomAvailability _self;
  final $Res Function(ClassroomAvailability) _then;

/// Create a copy of ClassroomAvailability
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? classroomName = null,Object? availability = null,Object? hasNoClassesThisTerm = null,}) {
  return _then(_self.copyWith(
classroomName: null == classroomName ? _self.classroomName : classroomName // ignore: cast_nullable_to_non_nullable
as String,availability: null == availability ? _self.availability : availability // ignore: cast_nullable_to_non_nullable
as List<bool>,hasNoClassesThisTerm: null == hasNoClassesThisTerm ? _self.hasNoClassesThisTerm : hasNoClassesThisTerm // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [ClassroomAvailability].
extension ClassroomAvailabilityPatterns on ClassroomAvailability {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ClassroomAvailability value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ClassroomAvailability() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ClassroomAvailability value)  $default,){
final _that = this;
switch (_that) {
case _ClassroomAvailability():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ClassroomAvailability value)?  $default,){
final _that = this;
switch (_that) {
case _ClassroomAvailability() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String classroomName,  List<bool> availability,  bool hasNoClassesThisTerm)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ClassroomAvailability() when $default != null:
return $default(_that.classroomName,_that.availability,_that.hasNoClassesThisTerm);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String classroomName,  List<bool> availability,  bool hasNoClassesThisTerm)  $default,) {final _that = this;
switch (_that) {
case _ClassroomAvailability():
return $default(_that.classroomName,_that.availability,_that.hasNoClassesThisTerm);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String classroomName,  List<bool> availability,  bool hasNoClassesThisTerm)?  $default,) {final _that = this;
switch (_that) {
case _ClassroomAvailability() when $default != null:
return $default(_that.classroomName,_that.availability,_that.hasNoClassesThisTerm);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ClassroomAvailability extends ClassroomAvailability {
  const _ClassroomAvailability({required this.classroomName, required final  List<bool> availability, this.hasNoClassesThisTerm = false}): _availability = availability,super._();
  factory _ClassroomAvailability.fromJson(Map<String, dynamic> json) => _$ClassroomAvailabilityFromJson(json);

@override final  String classroomName;
 final  List<bool> _availability;
@override List<bool> get availability {
  if (_availability is EqualUnmodifiableListView) return _availability;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_availability);
}

// List of 5 bools for the sessions
@override@JsonKey() final  bool hasNoClassesThisTerm;

/// Create a copy of ClassroomAvailability
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ClassroomAvailabilityCopyWith<_ClassroomAvailability> get copyWith => __$ClassroomAvailabilityCopyWithImpl<_ClassroomAvailability>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ClassroomAvailabilityToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ClassroomAvailability&&(identical(other.classroomName, classroomName) || other.classroomName == classroomName)&&const DeepCollectionEquality().equals(other._availability, _availability)&&(identical(other.hasNoClassesThisTerm, hasNoClassesThisTerm) || other.hasNoClassesThisTerm == hasNoClassesThisTerm));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,classroomName,const DeepCollectionEquality().hash(_availability),hasNoClassesThisTerm);

@override
String toString() {
  return 'ClassroomAvailability(classroomName: $classroomName, availability: $availability, hasNoClassesThisTerm: $hasNoClassesThisTerm)';
}


}

/// @nodoc
abstract mixin class _$ClassroomAvailabilityCopyWith<$Res> implements $ClassroomAvailabilityCopyWith<$Res> {
  factory _$ClassroomAvailabilityCopyWith(_ClassroomAvailability value, $Res Function(_ClassroomAvailability) _then) = __$ClassroomAvailabilityCopyWithImpl;
@override @useResult
$Res call({
 String classroomName, List<bool> availability, bool hasNoClassesThisTerm
});




}
/// @nodoc
class __$ClassroomAvailabilityCopyWithImpl<$Res>
    implements _$ClassroomAvailabilityCopyWith<$Res> {
  __$ClassroomAvailabilityCopyWithImpl(this._self, this._then);

  final _ClassroomAvailability _self;
  final $Res Function(_ClassroomAvailability) _then;

/// Create a copy of ClassroomAvailability
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? classroomName = null,Object? availability = null,Object? hasNoClassesThisTerm = null,}) {
  return _then(_ClassroomAvailability(
classroomName: null == classroomName ? _self.classroomName : classroomName // ignore: cast_nullable_to_non_nullable
as String,availability: null == availability ? _self._availability : availability // ignore: cast_nullable_to_non_nullable
as List<bool>,hasNoClassesThisTerm: null == hasNoClassesThisTerm ? _self.hasNoClassesThisTerm : hasNoClassesThisTerm // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
