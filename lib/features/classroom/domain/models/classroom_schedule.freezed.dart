// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'classroom_schedule.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$OccupiedSlot {

 int get startWeek; int get endWeek; int get weekday; int get slotIndex;
/// Create a copy of OccupiedSlot
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OccupiedSlotCopyWith<OccupiedSlot> get copyWith => _$OccupiedSlotCopyWithImpl<OccupiedSlot>(this as OccupiedSlot, _$identity);

  /// Serializes this OccupiedSlot to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OccupiedSlot&&(identical(other.startWeek, startWeek) || other.startWeek == startWeek)&&(identical(other.endWeek, endWeek) || other.endWeek == endWeek)&&(identical(other.weekday, weekday) || other.weekday == weekday)&&(identical(other.slotIndex, slotIndex) || other.slotIndex == slotIndex));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,startWeek,endWeek,weekday,slotIndex);

@override
String toString() {
  return 'OccupiedSlot(startWeek: $startWeek, endWeek: $endWeek, weekday: $weekday, slotIndex: $slotIndex)';
}


}

/// @nodoc
abstract mixin class $OccupiedSlotCopyWith<$Res>  {
  factory $OccupiedSlotCopyWith(OccupiedSlot value, $Res Function(OccupiedSlot) _then) = _$OccupiedSlotCopyWithImpl;
@useResult
$Res call({
 int startWeek, int endWeek, int weekday, int slotIndex
});




}
/// @nodoc
class _$OccupiedSlotCopyWithImpl<$Res>
    implements $OccupiedSlotCopyWith<$Res> {
  _$OccupiedSlotCopyWithImpl(this._self, this._then);

  final OccupiedSlot _self;
  final $Res Function(OccupiedSlot) _then;

/// Create a copy of OccupiedSlot
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? startWeek = null,Object? endWeek = null,Object? weekday = null,Object? slotIndex = null,}) {
  return _then(_self.copyWith(
startWeek: null == startWeek ? _self.startWeek : startWeek // ignore: cast_nullable_to_non_nullable
as int,endWeek: null == endWeek ? _self.endWeek : endWeek // ignore: cast_nullable_to_non_nullable
as int,weekday: null == weekday ? _self.weekday : weekday // ignore: cast_nullable_to_non_nullable
as int,slotIndex: null == slotIndex ? _self.slotIndex : slotIndex // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [OccupiedSlot].
extension OccupiedSlotPatterns on OccupiedSlot {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _OccupiedSlot value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _OccupiedSlot() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _OccupiedSlot value)  $default,){
final _that = this;
switch (_that) {
case _OccupiedSlot():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _OccupiedSlot value)?  $default,){
final _that = this;
switch (_that) {
case _OccupiedSlot() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int startWeek,  int endWeek,  int weekday,  int slotIndex)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _OccupiedSlot() when $default != null:
return $default(_that.startWeek,_that.endWeek,_that.weekday,_that.slotIndex);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int startWeek,  int endWeek,  int weekday,  int slotIndex)  $default,) {final _that = this;
switch (_that) {
case _OccupiedSlot():
return $default(_that.startWeek,_that.endWeek,_that.weekday,_that.slotIndex);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int startWeek,  int endWeek,  int weekday,  int slotIndex)?  $default,) {final _that = this;
switch (_that) {
case _OccupiedSlot() when $default != null:
return $default(_that.startWeek,_that.endWeek,_that.weekday,_that.slotIndex);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _OccupiedSlot implements OccupiedSlot {
  const _OccupiedSlot({required this.startWeek, required this.endWeek, required this.weekday, required this.slotIndex});
  factory _OccupiedSlot.fromJson(Map<String, dynamic> json) => _$OccupiedSlotFromJson(json);

@override final  int startWeek;
@override final  int endWeek;
@override final  int weekday;
@override final  int slotIndex;

/// Create a copy of OccupiedSlot
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$OccupiedSlotCopyWith<_OccupiedSlot> get copyWith => __$OccupiedSlotCopyWithImpl<_OccupiedSlot>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$OccupiedSlotToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _OccupiedSlot&&(identical(other.startWeek, startWeek) || other.startWeek == startWeek)&&(identical(other.endWeek, endWeek) || other.endWeek == endWeek)&&(identical(other.weekday, weekday) || other.weekday == weekday)&&(identical(other.slotIndex, slotIndex) || other.slotIndex == slotIndex));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,startWeek,endWeek,weekday,slotIndex);

@override
String toString() {
  return 'OccupiedSlot(startWeek: $startWeek, endWeek: $endWeek, weekday: $weekday, slotIndex: $slotIndex)';
}


}

/// @nodoc
abstract mixin class _$OccupiedSlotCopyWith<$Res> implements $OccupiedSlotCopyWith<$Res> {
  factory _$OccupiedSlotCopyWith(_OccupiedSlot value, $Res Function(_OccupiedSlot) _then) = __$OccupiedSlotCopyWithImpl;
@override @useResult
$Res call({
 int startWeek, int endWeek, int weekday, int slotIndex
});




}
/// @nodoc
class __$OccupiedSlotCopyWithImpl<$Res>
    implements _$OccupiedSlotCopyWith<$Res> {
  __$OccupiedSlotCopyWithImpl(this._self, this._then);

  final _OccupiedSlot _self;
  final $Res Function(_OccupiedSlot) _then;

/// Create a copy of OccupiedSlot
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? startWeek = null,Object? endWeek = null,Object? weekday = null,Object? slotIndex = null,}) {
  return _then(_OccupiedSlot(
startWeek: null == startWeek ? _self.startWeek : startWeek // ignore: cast_nullable_to_non_nullable
as int,endWeek: null == endWeek ? _self.endWeek : endWeek // ignore: cast_nullable_to_non_nullable
as int,weekday: null == weekday ? _self.weekday : weekday // ignore: cast_nullable_to_non_nullable
as int,slotIndex: null == slotIndex ? _self.slotIndex : slotIndex // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$ClassroomSchedule {

 String get classroomName; List<OccupiedSlot> get occupiedSlots;
/// Create a copy of ClassroomSchedule
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ClassroomScheduleCopyWith<ClassroomSchedule> get copyWith => _$ClassroomScheduleCopyWithImpl<ClassroomSchedule>(this as ClassroomSchedule, _$identity);

  /// Serializes this ClassroomSchedule to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ClassroomSchedule&&(identical(other.classroomName, classroomName) || other.classroomName == classroomName)&&const DeepCollectionEquality().equals(other.occupiedSlots, occupiedSlots));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,classroomName,const DeepCollectionEquality().hash(occupiedSlots));

@override
String toString() {
  return 'ClassroomSchedule(classroomName: $classroomName, occupiedSlots: $occupiedSlots)';
}


}

/// @nodoc
abstract mixin class $ClassroomScheduleCopyWith<$Res>  {
  factory $ClassroomScheduleCopyWith(ClassroomSchedule value, $Res Function(ClassroomSchedule) _then) = _$ClassroomScheduleCopyWithImpl;
@useResult
$Res call({
 String classroomName, List<OccupiedSlot> occupiedSlots
});




}
/// @nodoc
class _$ClassroomScheduleCopyWithImpl<$Res>
    implements $ClassroomScheduleCopyWith<$Res> {
  _$ClassroomScheduleCopyWithImpl(this._self, this._then);

  final ClassroomSchedule _self;
  final $Res Function(ClassroomSchedule) _then;

/// Create a copy of ClassroomSchedule
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? classroomName = null,Object? occupiedSlots = null,}) {
  return _then(_self.copyWith(
classroomName: null == classroomName ? _self.classroomName : classroomName // ignore: cast_nullable_to_non_nullable
as String,occupiedSlots: null == occupiedSlots ? _self.occupiedSlots : occupiedSlots // ignore: cast_nullable_to_non_nullable
as List<OccupiedSlot>,
  ));
}

}


/// Adds pattern-matching-related methods to [ClassroomSchedule].
extension ClassroomSchedulePatterns on ClassroomSchedule {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ClassroomSchedule value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ClassroomSchedule() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ClassroomSchedule value)  $default,){
final _that = this;
switch (_that) {
case _ClassroomSchedule():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ClassroomSchedule value)?  $default,){
final _that = this;
switch (_that) {
case _ClassroomSchedule() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String classroomName,  List<OccupiedSlot> occupiedSlots)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ClassroomSchedule() when $default != null:
return $default(_that.classroomName,_that.occupiedSlots);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String classroomName,  List<OccupiedSlot> occupiedSlots)  $default,) {final _that = this;
switch (_that) {
case _ClassroomSchedule():
return $default(_that.classroomName,_that.occupiedSlots);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String classroomName,  List<OccupiedSlot> occupiedSlots)?  $default,) {final _that = this;
switch (_that) {
case _ClassroomSchedule() when $default != null:
return $default(_that.classroomName,_that.occupiedSlots);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ClassroomSchedule implements ClassroomSchedule {
  const _ClassroomSchedule({required this.classroomName, required final  List<OccupiedSlot> occupiedSlots}): _occupiedSlots = occupiedSlots;
  factory _ClassroomSchedule.fromJson(Map<String, dynamic> json) => _$ClassroomScheduleFromJson(json);

@override final  String classroomName;
 final  List<OccupiedSlot> _occupiedSlots;
@override List<OccupiedSlot> get occupiedSlots {
  if (_occupiedSlots is EqualUnmodifiableListView) return _occupiedSlots;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_occupiedSlots);
}


/// Create a copy of ClassroomSchedule
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ClassroomScheduleCopyWith<_ClassroomSchedule> get copyWith => __$ClassroomScheduleCopyWithImpl<_ClassroomSchedule>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ClassroomScheduleToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ClassroomSchedule&&(identical(other.classroomName, classroomName) || other.classroomName == classroomName)&&const DeepCollectionEquality().equals(other._occupiedSlots, _occupiedSlots));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,classroomName,const DeepCollectionEquality().hash(_occupiedSlots));

@override
String toString() {
  return 'ClassroomSchedule(classroomName: $classroomName, occupiedSlots: $occupiedSlots)';
}


}

/// @nodoc
abstract mixin class _$ClassroomScheduleCopyWith<$Res> implements $ClassroomScheduleCopyWith<$Res> {
  factory _$ClassroomScheduleCopyWith(_ClassroomSchedule value, $Res Function(_ClassroomSchedule) _then) = __$ClassroomScheduleCopyWithImpl;
@override @useResult
$Res call({
 String classroomName, List<OccupiedSlot> occupiedSlots
});




}
/// @nodoc
class __$ClassroomScheduleCopyWithImpl<$Res>
    implements _$ClassroomScheduleCopyWith<$Res> {
  __$ClassroomScheduleCopyWithImpl(this._self, this._then);

  final _ClassroomSchedule _self;
  final $Res Function(_ClassroomSchedule) _then;

/// Create a copy of ClassroomSchedule
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? classroomName = null,Object? occupiedSlots = null,}) {
  return _then(_ClassroomSchedule(
classroomName: null == classroomName ? _self.classroomName : classroomName // ignore: cast_nullable_to_non_nullable
as String,occupiedSlots: null == occupiedSlots ? _self._occupiedSlots : occupiedSlots // ignore: cast_nullable_to_non_nullable
as List<OccupiedSlot>,
  ));
}


}

// dart format on
