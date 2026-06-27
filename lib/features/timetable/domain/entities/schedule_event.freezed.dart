// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'schedule_event.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ScheduleEvent {

 String get id; String get title; String get location; String get teacher; DateTime get start; DateTime get end; bool get enableNotification; DateTime? get notifyTime;
/// Create a copy of ScheduleEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ScheduleEventCopyWith<ScheduleEvent> get copyWith => _$ScheduleEventCopyWithImpl<ScheduleEvent>(this as ScheduleEvent, _$identity);

  /// Serializes this ScheduleEvent to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ScheduleEvent&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.location, location) || other.location == location)&&(identical(other.teacher, teacher) || other.teacher == teacher)&&(identical(other.start, start) || other.start == start)&&(identical(other.end, end) || other.end == end)&&(identical(other.enableNotification, enableNotification) || other.enableNotification == enableNotification)&&(identical(other.notifyTime, notifyTime) || other.notifyTime == notifyTime));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,title,location,teacher,start,end,enableNotification,notifyTime);

@override
String toString() {
  return 'ScheduleEvent(id: $id, title: $title, location: $location, teacher: $teacher, start: $start, end: $end, enableNotification: $enableNotification, notifyTime: $notifyTime)';
}


}

/// @nodoc
abstract mixin class $ScheduleEventCopyWith<$Res>  {
  factory $ScheduleEventCopyWith(ScheduleEvent value, $Res Function(ScheduleEvent) _then) = _$ScheduleEventCopyWithImpl;
@useResult
$Res call({
 String id, String title, String location, String teacher, DateTime start, DateTime end, bool enableNotification, DateTime? notifyTime
});




}
/// @nodoc
class _$ScheduleEventCopyWithImpl<$Res>
    implements $ScheduleEventCopyWith<$Res> {
  _$ScheduleEventCopyWithImpl(this._self, this._then);

  final ScheduleEvent _self;
  final $Res Function(ScheduleEvent) _then;

/// Create a copy of ScheduleEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? title = null,Object? location = null,Object? teacher = null,Object? start = null,Object? end = null,Object? enableNotification = null,Object? notifyTime = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,location: null == location ? _self.location : location // ignore: cast_nullable_to_non_nullable
as String,teacher: null == teacher ? _self.teacher : teacher // ignore: cast_nullable_to_non_nullable
as String,start: null == start ? _self.start : start // ignore: cast_nullable_to_non_nullable
as DateTime,end: null == end ? _self.end : end // ignore: cast_nullable_to_non_nullable
as DateTime,enableNotification: null == enableNotification ? _self.enableNotification : enableNotification // ignore: cast_nullable_to_non_nullable
as bool,notifyTime: freezed == notifyTime ? _self.notifyTime : notifyTime // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [ScheduleEvent].
extension ScheduleEventPatterns on ScheduleEvent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ScheduleEvent value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ScheduleEvent() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ScheduleEvent value)  $default,){
final _that = this;
switch (_that) {
case _ScheduleEvent():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ScheduleEvent value)?  $default,){
final _that = this;
switch (_that) {
case _ScheduleEvent() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String title,  String location,  String teacher,  DateTime start,  DateTime end,  bool enableNotification,  DateTime? notifyTime)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ScheduleEvent() when $default != null:
return $default(_that.id,_that.title,_that.location,_that.teacher,_that.start,_that.end,_that.enableNotification,_that.notifyTime);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String title,  String location,  String teacher,  DateTime start,  DateTime end,  bool enableNotification,  DateTime? notifyTime)  $default,) {final _that = this;
switch (_that) {
case _ScheduleEvent():
return $default(_that.id,_that.title,_that.location,_that.teacher,_that.start,_that.end,_that.enableNotification,_that.notifyTime);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String title,  String location,  String teacher,  DateTime start,  DateTime end,  bool enableNotification,  DateTime? notifyTime)?  $default,) {final _that = this;
switch (_that) {
case _ScheduleEvent() when $default != null:
return $default(_that.id,_that.title,_that.location,_that.teacher,_that.start,_that.end,_that.enableNotification,_that.notifyTime);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ScheduleEvent implements ScheduleEvent {
  const _ScheduleEvent({required this.id, required this.title, this.location = '', this.teacher = '', required this.start, required this.end, this.enableNotification = false, this.notifyTime});
  factory _ScheduleEvent.fromJson(Map<String, dynamic> json) => _$ScheduleEventFromJson(json);

@override final  String id;
@override final  String title;
@override@JsonKey() final  String location;
@override@JsonKey() final  String teacher;
@override final  DateTime start;
@override final  DateTime end;
@override@JsonKey() final  bool enableNotification;
@override final  DateTime? notifyTime;

/// Create a copy of ScheduleEvent
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ScheduleEventCopyWith<_ScheduleEvent> get copyWith => __$ScheduleEventCopyWithImpl<_ScheduleEvent>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ScheduleEventToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ScheduleEvent&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.location, location) || other.location == location)&&(identical(other.teacher, teacher) || other.teacher == teacher)&&(identical(other.start, start) || other.start == start)&&(identical(other.end, end) || other.end == end)&&(identical(other.enableNotification, enableNotification) || other.enableNotification == enableNotification)&&(identical(other.notifyTime, notifyTime) || other.notifyTime == notifyTime));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,title,location,teacher,start,end,enableNotification,notifyTime);

@override
String toString() {
  return 'ScheduleEvent(id: $id, title: $title, location: $location, teacher: $teacher, start: $start, end: $end, enableNotification: $enableNotification, notifyTime: $notifyTime)';
}


}

/// @nodoc
abstract mixin class _$ScheduleEventCopyWith<$Res> implements $ScheduleEventCopyWith<$Res> {
  factory _$ScheduleEventCopyWith(_ScheduleEvent value, $Res Function(_ScheduleEvent) _then) = __$ScheduleEventCopyWithImpl;
@override @useResult
$Res call({
 String id, String title, String location, String teacher, DateTime start, DateTime end, bool enableNotification, DateTime? notifyTime
});




}
/// @nodoc
class __$ScheduleEventCopyWithImpl<$Res>
    implements _$ScheduleEventCopyWith<$Res> {
  __$ScheduleEventCopyWithImpl(this._self, this._then);

  final _ScheduleEvent _self;
  final $Res Function(_ScheduleEvent) _then;

/// Create a copy of ScheduleEvent
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? title = null,Object? location = null,Object? teacher = null,Object? start = null,Object? end = null,Object? enableNotification = null,Object? notifyTime = freezed,}) {
  return _then(_ScheduleEvent(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,location: null == location ? _self.location : location // ignore: cast_nullable_to_non_nullable
as String,teacher: null == teacher ? _self.teacher : teacher // ignore: cast_nullable_to_non_nullable
as String,start: null == start ? _self.start : start // ignore: cast_nullable_to_non_nullable
as DateTime,end: null == end ? _self.end : end // ignore: cast_nullable_to_non_nullable
as DateTime,enableNotification: null == enableNotification ? _self.enableNotification : enableNotification // ignore: cast_nullable_to_non_nullable
as bool,notifyTime: freezed == notifyTime ? _self.notifyTime : notifyTime // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
