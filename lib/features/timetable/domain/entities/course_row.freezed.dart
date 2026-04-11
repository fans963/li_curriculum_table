// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'course_row.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$CourseRow {

 String get courseId; String get order; String get courseName; String get teacher; String get timeText; String get credit; String get location; String get courseType; String get stage; List<TimeSlot> get slots;
/// Create a copy of CourseRow
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CourseRowCopyWith<CourseRow> get copyWith => _$CourseRowCopyWithImpl<CourseRow>(this as CourseRow, _$identity);

  /// Serializes this CourseRow to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CourseRow&&(identical(other.courseId, courseId) || other.courseId == courseId)&&(identical(other.order, order) || other.order == order)&&(identical(other.courseName, courseName) || other.courseName == courseName)&&(identical(other.teacher, teacher) || other.teacher == teacher)&&(identical(other.timeText, timeText) || other.timeText == timeText)&&(identical(other.credit, credit) || other.credit == credit)&&(identical(other.location, location) || other.location == location)&&(identical(other.courseType, courseType) || other.courseType == courseType)&&(identical(other.stage, stage) || other.stage == stage)&&const DeepCollectionEquality().equals(other.slots, slots));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,courseId,order,courseName,teacher,timeText,credit,location,courseType,stage,const DeepCollectionEquality().hash(slots));

@override
String toString() {
  return 'CourseRow(courseId: $courseId, order: $order, courseName: $courseName, teacher: $teacher, timeText: $timeText, credit: $credit, location: $location, courseType: $courseType, stage: $stage, slots: $slots)';
}


}

/// @nodoc
abstract mixin class $CourseRowCopyWith<$Res>  {
  factory $CourseRowCopyWith(CourseRow value, $Res Function(CourseRow) _then) = _$CourseRowCopyWithImpl;
@useResult
$Res call({
 String courseId, String order, String courseName, String teacher, String timeText, String credit, String location, String courseType, String stage, List<TimeSlot> slots
});




}
/// @nodoc
class _$CourseRowCopyWithImpl<$Res>
    implements $CourseRowCopyWith<$Res> {
  _$CourseRowCopyWithImpl(this._self, this._then);

  final CourseRow _self;
  final $Res Function(CourseRow) _then;

/// Create a copy of CourseRow
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? courseId = null,Object? order = null,Object? courseName = null,Object? teacher = null,Object? timeText = null,Object? credit = null,Object? location = null,Object? courseType = null,Object? stage = null,Object? slots = null,}) {
  return _then(_self.copyWith(
courseId: null == courseId ? _self.courseId : courseId // ignore: cast_nullable_to_non_nullable
as String,order: null == order ? _self.order : order // ignore: cast_nullable_to_non_nullable
as String,courseName: null == courseName ? _self.courseName : courseName // ignore: cast_nullable_to_non_nullable
as String,teacher: null == teacher ? _self.teacher : teacher // ignore: cast_nullable_to_non_nullable
as String,timeText: null == timeText ? _self.timeText : timeText // ignore: cast_nullable_to_non_nullable
as String,credit: null == credit ? _self.credit : credit // ignore: cast_nullable_to_non_nullable
as String,location: null == location ? _self.location : location // ignore: cast_nullable_to_non_nullable
as String,courseType: null == courseType ? _self.courseType : courseType // ignore: cast_nullable_to_non_nullable
as String,stage: null == stage ? _self.stage : stage // ignore: cast_nullable_to_non_nullable
as String,slots: null == slots ? _self.slots : slots // ignore: cast_nullable_to_non_nullable
as List<TimeSlot>,
  ));
}

}


/// Adds pattern-matching-related methods to [CourseRow].
extension CourseRowPatterns on CourseRow {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CourseRow value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CourseRow() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CourseRow value)  $default,){
final _that = this;
switch (_that) {
case _CourseRow():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CourseRow value)?  $default,){
final _that = this;
switch (_that) {
case _CourseRow() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String courseId,  String order,  String courseName,  String teacher,  String timeText,  String credit,  String location,  String courseType,  String stage,  List<TimeSlot> slots)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CourseRow() when $default != null:
return $default(_that.courseId,_that.order,_that.courseName,_that.teacher,_that.timeText,_that.credit,_that.location,_that.courseType,_that.stage,_that.slots);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String courseId,  String order,  String courseName,  String teacher,  String timeText,  String credit,  String location,  String courseType,  String stage,  List<TimeSlot> slots)  $default,) {final _that = this;
switch (_that) {
case _CourseRow():
return $default(_that.courseId,_that.order,_that.courseName,_that.teacher,_that.timeText,_that.credit,_that.location,_that.courseType,_that.stage,_that.slots);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String courseId,  String order,  String courseName,  String teacher,  String timeText,  String credit,  String location,  String courseType,  String stage,  List<TimeSlot> slots)?  $default,) {final _that = this;
switch (_that) {
case _CourseRow() when $default != null:
return $default(_that.courseId,_that.order,_that.courseName,_that.teacher,_that.timeText,_that.credit,_that.location,_that.courseType,_that.stage,_that.slots);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CourseRow implements CourseRow {
  const _CourseRow({required this.courseId, required this.order, required this.courseName, required this.teacher, required this.timeText, required this.credit, required this.location, required this.courseType, required this.stage, required final  List<TimeSlot> slots}): _slots = slots;
  factory _CourseRow.fromJson(Map<String, dynamic> json) => _$CourseRowFromJson(json);

@override final  String courseId;
@override final  String order;
@override final  String courseName;
@override final  String teacher;
@override final  String timeText;
@override final  String credit;
@override final  String location;
@override final  String courseType;
@override final  String stage;
 final  List<TimeSlot> _slots;
@override List<TimeSlot> get slots {
  if (_slots is EqualUnmodifiableListView) return _slots;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_slots);
}


/// Create a copy of CourseRow
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CourseRowCopyWith<_CourseRow> get copyWith => __$CourseRowCopyWithImpl<_CourseRow>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CourseRowToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CourseRow&&(identical(other.courseId, courseId) || other.courseId == courseId)&&(identical(other.order, order) || other.order == order)&&(identical(other.courseName, courseName) || other.courseName == courseName)&&(identical(other.teacher, teacher) || other.teacher == teacher)&&(identical(other.timeText, timeText) || other.timeText == timeText)&&(identical(other.credit, credit) || other.credit == credit)&&(identical(other.location, location) || other.location == location)&&(identical(other.courseType, courseType) || other.courseType == courseType)&&(identical(other.stage, stage) || other.stage == stage)&&const DeepCollectionEquality().equals(other._slots, _slots));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,courseId,order,courseName,teacher,timeText,credit,location,courseType,stage,const DeepCollectionEquality().hash(_slots));

@override
String toString() {
  return 'CourseRow(courseId: $courseId, order: $order, courseName: $courseName, teacher: $teacher, timeText: $timeText, credit: $credit, location: $location, courseType: $courseType, stage: $stage, slots: $slots)';
}


}

/// @nodoc
abstract mixin class _$CourseRowCopyWith<$Res> implements $CourseRowCopyWith<$Res> {
  factory _$CourseRowCopyWith(_CourseRow value, $Res Function(_CourseRow) _then) = __$CourseRowCopyWithImpl;
@override @useResult
$Res call({
 String courseId, String order, String courseName, String teacher, String timeText, String credit, String location, String courseType, String stage, List<TimeSlot> slots
});




}
/// @nodoc
class __$CourseRowCopyWithImpl<$Res>
    implements _$CourseRowCopyWith<$Res> {
  __$CourseRowCopyWithImpl(this._self, this._then);

  final _CourseRow _self;
  final $Res Function(_CourseRow) _then;

/// Create a copy of CourseRow
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? courseId = null,Object? order = null,Object? courseName = null,Object? teacher = null,Object? timeText = null,Object? credit = null,Object? location = null,Object? courseType = null,Object? stage = null,Object? slots = null,}) {
  return _then(_CourseRow(
courseId: null == courseId ? _self.courseId : courseId // ignore: cast_nullable_to_non_nullable
as String,order: null == order ? _self.order : order // ignore: cast_nullable_to_non_nullable
as String,courseName: null == courseName ? _self.courseName : courseName // ignore: cast_nullable_to_non_nullable
as String,teacher: null == teacher ? _self.teacher : teacher // ignore: cast_nullable_to_non_nullable
as String,timeText: null == timeText ? _self.timeText : timeText // ignore: cast_nullable_to_non_nullable
as String,credit: null == credit ? _self.credit : credit // ignore: cast_nullable_to_non_nullable
as String,location: null == location ? _self.location : location // ignore: cast_nullable_to_non_nullable
as String,courseType: null == courseType ? _self.courseType : courseType // ignore: cast_nullable_to_non_nullable
as String,stage: null == stage ? _self.stage : stage // ignore: cast_nullable_to_non_nullable
as String,slots: null == slots ? _self._slots : slots // ignore: cast_nullable_to_non_nullable
as List<TimeSlot>,
  ));
}


}

// dart format on
