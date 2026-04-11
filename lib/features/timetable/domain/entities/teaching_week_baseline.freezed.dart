// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'teaching_week_baseline.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$TeachingWeekBaseline {

 DateTime get referenceDate; int get referenceWeek;
/// Create a copy of TeachingWeekBaseline
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TeachingWeekBaselineCopyWith<TeachingWeekBaseline> get copyWith => _$TeachingWeekBaselineCopyWithImpl<TeachingWeekBaseline>(this as TeachingWeekBaseline, _$identity);

  /// Serializes this TeachingWeekBaseline to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TeachingWeekBaseline&&(identical(other.referenceDate, referenceDate) || other.referenceDate == referenceDate)&&(identical(other.referenceWeek, referenceWeek) || other.referenceWeek == referenceWeek));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,referenceDate,referenceWeek);

@override
String toString() {
  return 'TeachingWeekBaseline(referenceDate: $referenceDate, referenceWeek: $referenceWeek)';
}


}

/// @nodoc
abstract mixin class $TeachingWeekBaselineCopyWith<$Res>  {
  factory $TeachingWeekBaselineCopyWith(TeachingWeekBaseline value, $Res Function(TeachingWeekBaseline) _then) = _$TeachingWeekBaselineCopyWithImpl;
@useResult
$Res call({
 DateTime referenceDate, int referenceWeek
});




}
/// @nodoc
class _$TeachingWeekBaselineCopyWithImpl<$Res>
    implements $TeachingWeekBaselineCopyWith<$Res> {
  _$TeachingWeekBaselineCopyWithImpl(this._self, this._then);

  final TeachingWeekBaseline _self;
  final $Res Function(TeachingWeekBaseline) _then;

/// Create a copy of TeachingWeekBaseline
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? referenceDate = null,Object? referenceWeek = null,}) {
  return _then(_self.copyWith(
referenceDate: null == referenceDate ? _self.referenceDate : referenceDate // ignore: cast_nullable_to_non_nullable
as DateTime,referenceWeek: null == referenceWeek ? _self.referenceWeek : referenceWeek // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [TeachingWeekBaseline].
extension TeachingWeekBaselinePatterns on TeachingWeekBaseline {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TeachingWeekBaseline value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TeachingWeekBaseline() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TeachingWeekBaseline value)  $default,){
final _that = this;
switch (_that) {
case _TeachingWeekBaseline():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TeachingWeekBaseline value)?  $default,){
final _that = this;
switch (_that) {
case _TeachingWeekBaseline() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( DateTime referenceDate,  int referenceWeek)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TeachingWeekBaseline() when $default != null:
return $default(_that.referenceDate,_that.referenceWeek);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( DateTime referenceDate,  int referenceWeek)  $default,) {final _that = this;
switch (_that) {
case _TeachingWeekBaseline():
return $default(_that.referenceDate,_that.referenceWeek);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( DateTime referenceDate,  int referenceWeek)?  $default,) {final _that = this;
switch (_that) {
case _TeachingWeekBaseline() when $default != null:
return $default(_that.referenceDate,_that.referenceWeek);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _TeachingWeekBaseline extends TeachingWeekBaseline {
  const _TeachingWeekBaseline({required this.referenceDate, required this.referenceWeek}): super._();
  factory _TeachingWeekBaseline.fromJson(Map<String, dynamic> json) => _$TeachingWeekBaselineFromJson(json);

@override final  DateTime referenceDate;
@override final  int referenceWeek;

/// Create a copy of TeachingWeekBaseline
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TeachingWeekBaselineCopyWith<_TeachingWeekBaseline> get copyWith => __$TeachingWeekBaselineCopyWithImpl<_TeachingWeekBaseline>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TeachingWeekBaselineToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TeachingWeekBaseline&&(identical(other.referenceDate, referenceDate) || other.referenceDate == referenceDate)&&(identical(other.referenceWeek, referenceWeek) || other.referenceWeek == referenceWeek));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,referenceDate,referenceWeek);

@override
String toString() {
  return 'TeachingWeekBaseline(referenceDate: $referenceDate, referenceWeek: $referenceWeek)';
}


}

/// @nodoc
abstract mixin class _$TeachingWeekBaselineCopyWith<$Res> implements $TeachingWeekBaselineCopyWith<$Res> {
  factory _$TeachingWeekBaselineCopyWith(_TeachingWeekBaseline value, $Res Function(_TeachingWeekBaseline) _then) = __$TeachingWeekBaselineCopyWithImpl;
@override @useResult
$Res call({
 DateTime referenceDate, int referenceWeek
});




}
/// @nodoc
class __$TeachingWeekBaselineCopyWithImpl<$Res>
    implements _$TeachingWeekBaselineCopyWith<$Res> {
  __$TeachingWeekBaselineCopyWithImpl(this._self, this._then);

  final _TeachingWeekBaseline _self;
  final $Res Function(_TeachingWeekBaseline) _then;

/// Create a copy of TeachingWeekBaseline
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? referenceDate = null,Object? referenceWeek = null,}) {
  return _then(_TeachingWeekBaseline(
referenceDate: null == referenceDate ? _self.referenceDate : referenceDate // ignore: cast_nullable_to_non_nullable
as DateTime,referenceWeek: null == referenceWeek ? _self.referenceWeek : referenceWeek // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
