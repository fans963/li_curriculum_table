// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'course_occurrence.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$CourseOccurrence {

 String get courseName; String get teacher; String get location; String get credit; String get courseType; String get stage; DateTime get start; DateTime get end; int? get startWeek; int? get endWeek; String get weekText;@ColorConverter() Color get color;
/// Create a copy of CourseOccurrence
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CourseOccurrenceCopyWith<CourseOccurrence> get copyWith => _$CourseOccurrenceCopyWithImpl<CourseOccurrence>(this as CourseOccurrence, _$identity);

  /// Serializes this CourseOccurrence to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CourseOccurrence&&(identical(other.courseName, courseName) || other.courseName == courseName)&&(identical(other.teacher, teacher) || other.teacher == teacher)&&(identical(other.location, location) || other.location == location)&&(identical(other.credit, credit) || other.credit == credit)&&(identical(other.courseType, courseType) || other.courseType == courseType)&&(identical(other.stage, stage) || other.stage == stage)&&(identical(other.start, start) || other.start == start)&&(identical(other.end, end) || other.end == end)&&(identical(other.startWeek, startWeek) || other.startWeek == startWeek)&&(identical(other.endWeek, endWeek) || other.endWeek == endWeek)&&(identical(other.weekText, weekText) || other.weekText == weekText)&&(identical(other.color, color) || other.color == color));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,courseName,teacher,location,credit,courseType,stage,start,end,startWeek,endWeek,weekText,color);

@override
String toString() {
  return 'CourseOccurrence(courseName: $courseName, teacher: $teacher, location: $location, credit: $credit, courseType: $courseType, stage: $stage, start: $start, end: $end, startWeek: $startWeek, endWeek: $endWeek, weekText: $weekText, color: $color)';
}


}

/// @nodoc
abstract mixin class $CourseOccurrenceCopyWith<$Res>  {
  factory $CourseOccurrenceCopyWith(CourseOccurrence value, $Res Function(CourseOccurrence) _then) = _$CourseOccurrenceCopyWithImpl;
@useResult
$Res call({
 String courseName, String teacher, String location, String credit, String courseType, String stage, DateTime start, DateTime end, int? startWeek, int? endWeek, String weekText,@ColorConverter() Color color
});




}
/// @nodoc
class _$CourseOccurrenceCopyWithImpl<$Res>
    implements $CourseOccurrenceCopyWith<$Res> {
  _$CourseOccurrenceCopyWithImpl(this._self, this._then);

  final CourseOccurrence _self;
  final $Res Function(CourseOccurrence) _then;

/// Create a copy of CourseOccurrence
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? courseName = null,Object? teacher = null,Object? location = null,Object? credit = null,Object? courseType = null,Object? stage = null,Object? start = null,Object? end = null,Object? startWeek = freezed,Object? endWeek = freezed,Object? weekText = null,Object? color = null,}) {
  return _then(_self.copyWith(
courseName: null == courseName ? _self.courseName : courseName // ignore: cast_nullable_to_non_nullable
as String,teacher: null == teacher ? _self.teacher : teacher // ignore: cast_nullable_to_non_nullable
as String,location: null == location ? _self.location : location // ignore: cast_nullable_to_non_nullable
as String,credit: null == credit ? _self.credit : credit // ignore: cast_nullable_to_non_nullable
as String,courseType: null == courseType ? _self.courseType : courseType // ignore: cast_nullable_to_non_nullable
as String,stage: null == stage ? _self.stage : stage // ignore: cast_nullable_to_non_nullable
as String,start: null == start ? _self.start : start // ignore: cast_nullable_to_non_nullable
as DateTime,end: null == end ? _self.end : end // ignore: cast_nullable_to_non_nullable
as DateTime,startWeek: freezed == startWeek ? _self.startWeek : startWeek // ignore: cast_nullable_to_non_nullable
as int?,endWeek: freezed == endWeek ? _self.endWeek : endWeek // ignore: cast_nullable_to_non_nullable
as int?,weekText: null == weekText ? _self.weekText : weekText // ignore: cast_nullable_to_non_nullable
as String,color: null == color ? _self.color : color // ignore: cast_nullable_to_non_nullable
as Color,
  ));
}

}


/// Adds pattern-matching-related methods to [CourseOccurrence].
extension CourseOccurrencePatterns on CourseOccurrence {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CourseOccurrence value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CourseOccurrence() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CourseOccurrence value)  $default,){
final _that = this;
switch (_that) {
case _CourseOccurrence():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CourseOccurrence value)?  $default,){
final _that = this;
switch (_that) {
case _CourseOccurrence() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String courseName,  String teacher,  String location,  String credit,  String courseType,  String stage,  DateTime start,  DateTime end,  int? startWeek,  int? endWeek,  String weekText, @ColorConverter()  Color color)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CourseOccurrence() when $default != null:
return $default(_that.courseName,_that.teacher,_that.location,_that.credit,_that.courseType,_that.stage,_that.start,_that.end,_that.startWeek,_that.endWeek,_that.weekText,_that.color);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String courseName,  String teacher,  String location,  String credit,  String courseType,  String stage,  DateTime start,  DateTime end,  int? startWeek,  int? endWeek,  String weekText, @ColorConverter()  Color color)  $default,) {final _that = this;
switch (_that) {
case _CourseOccurrence():
return $default(_that.courseName,_that.teacher,_that.location,_that.credit,_that.courseType,_that.stage,_that.start,_that.end,_that.startWeek,_that.endWeek,_that.weekText,_that.color);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String courseName,  String teacher,  String location,  String credit,  String courseType,  String stage,  DateTime start,  DateTime end,  int? startWeek,  int? endWeek,  String weekText, @ColorConverter()  Color color)?  $default,) {final _that = this;
switch (_that) {
case _CourseOccurrence() when $default != null:
return $default(_that.courseName,_that.teacher,_that.location,_that.credit,_that.courseType,_that.stage,_that.start,_that.end,_that.startWeek,_that.endWeek,_that.weekText,_that.color);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CourseOccurrence implements CourseOccurrence {
  const _CourseOccurrence({required this.courseName, required this.teacher, required this.location, required this.credit, required this.courseType, required this.stage, required this.start, required this.end, this.startWeek, this.endWeek, this.weekText = '', @ColorConverter() required this.color});
  factory _CourseOccurrence.fromJson(Map<String, dynamic> json) => _$CourseOccurrenceFromJson(json);

@override final  String courseName;
@override final  String teacher;
@override final  String location;
@override final  String credit;
@override final  String courseType;
@override final  String stage;
@override final  DateTime start;
@override final  DateTime end;
@override final  int? startWeek;
@override final  int? endWeek;
@override@JsonKey() final  String weekText;
@override@ColorConverter() final  Color color;

/// Create a copy of CourseOccurrence
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CourseOccurrenceCopyWith<_CourseOccurrence> get copyWith => __$CourseOccurrenceCopyWithImpl<_CourseOccurrence>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CourseOccurrenceToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CourseOccurrence&&(identical(other.courseName, courseName) || other.courseName == courseName)&&(identical(other.teacher, teacher) || other.teacher == teacher)&&(identical(other.location, location) || other.location == location)&&(identical(other.credit, credit) || other.credit == credit)&&(identical(other.courseType, courseType) || other.courseType == courseType)&&(identical(other.stage, stage) || other.stage == stage)&&(identical(other.start, start) || other.start == start)&&(identical(other.end, end) || other.end == end)&&(identical(other.startWeek, startWeek) || other.startWeek == startWeek)&&(identical(other.endWeek, endWeek) || other.endWeek == endWeek)&&(identical(other.weekText, weekText) || other.weekText == weekText)&&(identical(other.color, color) || other.color == color));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,courseName,teacher,location,credit,courseType,stage,start,end,startWeek,endWeek,weekText,color);

@override
String toString() {
  return 'CourseOccurrence(courseName: $courseName, teacher: $teacher, location: $location, credit: $credit, courseType: $courseType, stage: $stage, start: $start, end: $end, startWeek: $startWeek, endWeek: $endWeek, weekText: $weekText, color: $color)';
}


}

/// @nodoc
abstract mixin class _$CourseOccurrenceCopyWith<$Res> implements $CourseOccurrenceCopyWith<$Res> {
  factory _$CourseOccurrenceCopyWith(_CourseOccurrence value, $Res Function(_CourseOccurrence) _then) = __$CourseOccurrenceCopyWithImpl;
@override @useResult
$Res call({
 String courseName, String teacher, String location, String credit, String courseType, String stage, DateTime start, DateTime end, int? startWeek, int? endWeek, String weekText,@ColorConverter() Color color
});




}
/// @nodoc
class __$CourseOccurrenceCopyWithImpl<$Res>
    implements _$CourseOccurrenceCopyWith<$Res> {
  __$CourseOccurrenceCopyWithImpl(this._self, this._then);

  final _CourseOccurrence _self;
  final $Res Function(_CourseOccurrence) _then;

/// Create a copy of CourseOccurrence
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? courseName = null,Object? teacher = null,Object? location = null,Object? credit = null,Object? courseType = null,Object? stage = null,Object? start = null,Object? end = null,Object? startWeek = freezed,Object? endWeek = freezed,Object? weekText = null,Object? color = null,}) {
  return _then(_CourseOccurrence(
courseName: null == courseName ? _self.courseName : courseName // ignore: cast_nullable_to_non_nullable
as String,teacher: null == teacher ? _self.teacher : teacher // ignore: cast_nullable_to_non_nullable
as String,location: null == location ? _self.location : location // ignore: cast_nullable_to_non_nullable
as String,credit: null == credit ? _self.credit : credit // ignore: cast_nullable_to_non_nullable
as String,courseType: null == courseType ? _self.courseType : courseType // ignore: cast_nullable_to_non_nullable
as String,stage: null == stage ? _self.stage : stage // ignore: cast_nullable_to_non_nullable
as String,start: null == start ? _self.start : start // ignore: cast_nullable_to_non_nullable
as DateTime,end: null == end ? _self.end : end // ignore: cast_nullable_to_non_nullable
as DateTime,startWeek: freezed == startWeek ? _self.startWeek : startWeek // ignore: cast_nullable_to_non_nullable
as int?,endWeek: freezed == endWeek ? _self.endWeek : endWeek // ignore: cast_nullable_to_non_nullable
as int?,weekText: null == weekText ? _self.weekText : weekText // ignore: cast_nullable_to_non_nullable
as String,color: null == color ? _self.color : color // ignore: cast_nullable_to_non_nullable
as Color,
  ));
}


}

// dart format on
