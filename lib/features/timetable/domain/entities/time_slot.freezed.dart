// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'time_slot.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$TimeSlot {

 int get weekday; int get startSection; int get endSection; int get startWeek; int get endWeek; String get weekText;
/// Create a copy of TimeSlot
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TimeSlotCopyWith<TimeSlot> get copyWith => _$TimeSlotCopyWithImpl<TimeSlot>(this as TimeSlot, _$identity);

  /// Serializes this TimeSlot to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TimeSlot&&(identical(other.weekday, weekday) || other.weekday == weekday)&&(identical(other.startSection, startSection) || other.startSection == startSection)&&(identical(other.endSection, endSection) || other.endSection == endSection)&&(identical(other.startWeek, startWeek) || other.startWeek == startWeek)&&(identical(other.endWeek, endWeek) || other.endWeek == endWeek)&&(identical(other.weekText, weekText) || other.weekText == weekText));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,weekday,startSection,endSection,startWeek,endWeek,weekText);

@override
String toString() {
  return 'TimeSlot(weekday: $weekday, startSection: $startSection, endSection: $endSection, startWeek: $startWeek, endWeek: $endWeek, weekText: $weekText)';
}


}

/// @nodoc
abstract mixin class $TimeSlotCopyWith<$Res>  {
  factory $TimeSlotCopyWith(TimeSlot value, $Res Function(TimeSlot) _then) = _$TimeSlotCopyWithImpl;
@useResult
$Res call({
 int weekday, int startSection, int endSection, int startWeek, int endWeek, String weekText
});




}
/// @nodoc
class _$TimeSlotCopyWithImpl<$Res>
    implements $TimeSlotCopyWith<$Res> {
  _$TimeSlotCopyWithImpl(this._self, this._then);

  final TimeSlot _self;
  final $Res Function(TimeSlot) _then;

/// Create a copy of TimeSlot
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? weekday = null,Object? startSection = null,Object? endSection = null,Object? startWeek = null,Object? endWeek = null,Object? weekText = null,}) {
  return _then(_self.copyWith(
weekday: null == weekday ? _self.weekday : weekday // ignore: cast_nullable_to_non_nullable
as int,startSection: null == startSection ? _self.startSection : startSection // ignore: cast_nullable_to_non_nullable
as int,endSection: null == endSection ? _self.endSection : endSection // ignore: cast_nullable_to_non_nullable
as int,startWeek: null == startWeek ? _self.startWeek : startWeek // ignore: cast_nullable_to_non_nullable
as int,endWeek: null == endWeek ? _self.endWeek : endWeek // ignore: cast_nullable_to_non_nullable
as int,weekText: null == weekText ? _self.weekText : weekText // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [TimeSlot].
extension TimeSlotPatterns on TimeSlot {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TimeSlot value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TimeSlot() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TimeSlot value)  $default,){
final _that = this;
switch (_that) {
case _TimeSlot():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TimeSlot value)?  $default,){
final _that = this;
switch (_that) {
case _TimeSlot() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int weekday,  int startSection,  int endSection,  int startWeek,  int endWeek,  String weekText)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TimeSlot() when $default != null:
return $default(_that.weekday,_that.startSection,_that.endSection,_that.startWeek,_that.endWeek,_that.weekText);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int weekday,  int startSection,  int endSection,  int startWeek,  int endWeek,  String weekText)  $default,) {final _that = this;
switch (_that) {
case _TimeSlot():
return $default(_that.weekday,_that.startSection,_that.endSection,_that.startWeek,_that.endWeek,_that.weekText);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int weekday,  int startSection,  int endSection,  int startWeek,  int endWeek,  String weekText)?  $default,) {final _that = this;
switch (_that) {
case _TimeSlot() when $default != null:
return $default(_that.weekday,_that.startSection,_that.endSection,_that.startWeek,_that.endWeek,_that.weekText);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _TimeSlot implements TimeSlot {
  const _TimeSlot({required this.weekday, required this.startSection, required this.endSection, required this.startWeek, required this.endWeek, required this.weekText});
  factory _TimeSlot.fromJson(Map<String, dynamic> json) => _$TimeSlotFromJson(json);

@override final  int weekday;
@override final  int startSection;
@override final  int endSection;
@override final  int startWeek;
@override final  int endWeek;
@override final  String weekText;

/// Create a copy of TimeSlot
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TimeSlotCopyWith<_TimeSlot> get copyWith => __$TimeSlotCopyWithImpl<_TimeSlot>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TimeSlotToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TimeSlot&&(identical(other.weekday, weekday) || other.weekday == weekday)&&(identical(other.startSection, startSection) || other.startSection == startSection)&&(identical(other.endSection, endSection) || other.endSection == endSection)&&(identical(other.startWeek, startWeek) || other.startWeek == startWeek)&&(identical(other.endWeek, endWeek) || other.endWeek == endWeek)&&(identical(other.weekText, weekText) || other.weekText == weekText));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,weekday,startSection,endSection,startWeek,endWeek,weekText);

@override
String toString() {
  return 'TimeSlot(weekday: $weekday, startSection: $startSection, endSection: $endSection, startWeek: $startWeek, endWeek: $endWeek, weekText: $weekText)';
}


}

/// @nodoc
abstract mixin class _$TimeSlotCopyWith<$Res> implements $TimeSlotCopyWith<$Res> {
  factory _$TimeSlotCopyWith(_TimeSlot value, $Res Function(_TimeSlot) _then) = __$TimeSlotCopyWithImpl;
@override @useResult
$Res call({
 int weekday, int startSection, int endSection, int startWeek, int endWeek, String weekText
});




}
/// @nodoc
class __$TimeSlotCopyWithImpl<$Res>
    implements _$TimeSlotCopyWith<$Res> {
  __$TimeSlotCopyWithImpl(this._self, this._then);

  final _TimeSlot _self;
  final $Res Function(_TimeSlot) _then;

/// Create a copy of TimeSlot
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? weekday = null,Object? startSection = null,Object? endSection = null,Object? startWeek = null,Object? endWeek = null,Object? weekText = null,}) {
  return _then(_TimeSlot(
weekday: null == weekday ? _self.weekday : weekday // ignore: cast_nullable_to_non_nullable
as int,startSection: null == startSection ? _self.startSection : startSection // ignore: cast_nullable_to_non_nullable
as int,endSection: null == endSection ? _self.endSection : endSection // ignore: cast_nullable_to_non_nullable
as int,startWeek: null == startWeek ? _self.startWeek : startWeek // ignore: cast_nullable_to_non_nullable
as int,endWeek: null == endWeek ? _self.endWeek : endWeek // ignore: cast_nullable_to_non_nullable
as int,weekText: null == weekText ? _self.weekText : weekText // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
