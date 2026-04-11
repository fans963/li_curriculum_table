// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'timetable_data.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$TimetableData {

 List<CourseRow> get rows; List<CourseOccurrence> get occurrences; bool get loginLikelySuccess;
/// Create a copy of TimetableData
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TimetableDataCopyWith<TimetableData> get copyWith => _$TimetableDataCopyWithImpl<TimetableData>(this as TimetableData, _$identity);

  /// Serializes this TimetableData to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TimetableData&&const DeepCollectionEquality().equals(other.rows, rows)&&const DeepCollectionEquality().equals(other.occurrences, occurrences)&&(identical(other.loginLikelySuccess, loginLikelySuccess) || other.loginLikelySuccess == loginLikelySuccess));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(rows),const DeepCollectionEquality().hash(occurrences),loginLikelySuccess);

@override
String toString() {
  return 'TimetableData(rows: $rows, occurrences: $occurrences, loginLikelySuccess: $loginLikelySuccess)';
}


}

/// @nodoc
abstract mixin class $TimetableDataCopyWith<$Res>  {
  factory $TimetableDataCopyWith(TimetableData value, $Res Function(TimetableData) _then) = _$TimetableDataCopyWithImpl;
@useResult
$Res call({
 List<CourseRow> rows, List<CourseOccurrence> occurrences, bool loginLikelySuccess
});




}
/// @nodoc
class _$TimetableDataCopyWithImpl<$Res>
    implements $TimetableDataCopyWith<$Res> {
  _$TimetableDataCopyWithImpl(this._self, this._then);

  final TimetableData _self;
  final $Res Function(TimetableData) _then;

/// Create a copy of TimetableData
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? rows = null,Object? occurrences = null,Object? loginLikelySuccess = null,}) {
  return _then(_self.copyWith(
rows: null == rows ? _self.rows : rows // ignore: cast_nullable_to_non_nullable
as List<CourseRow>,occurrences: null == occurrences ? _self.occurrences : occurrences // ignore: cast_nullable_to_non_nullable
as List<CourseOccurrence>,loginLikelySuccess: null == loginLikelySuccess ? _self.loginLikelySuccess : loginLikelySuccess // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [TimetableData].
extension TimetableDataPatterns on TimetableData {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TimetableData value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TimetableData() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TimetableData value)  $default,){
final _that = this;
switch (_that) {
case _TimetableData():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TimetableData value)?  $default,){
final _that = this;
switch (_that) {
case _TimetableData() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<CourseRow> rows,  List<CourseOccurrence> occurrences,  bool loginLikelySuccess)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TimetableData() when $default != null:
return $default(_that.rows,_that.occurrences,_that.loginLikelySuccess);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<CourseRow> rows,  List<CourseOccurrence> occurrences,  bool loginLikelySuccess)  $default,) {final _that = this;
switch (_that) {
case _TimetableData():
return $default(_that.rows,_that.occurrences,_that.loginLikelySuccess);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<CourseRow> rows,  List<CourseOccurrence> occurrences,  bool loginLikelySuccess)?  $default,) {final _that = this;
switch (_that) {
case _TimetableData() when $default != null:
return $default(_that.rows,_that.occurrences,_that.loginLikelySuccess);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _TimetableData implements TimetableData {
  const _TimetableData({required final  List<CourseRow> rows, required final  List<CourseOccurrence> occurrences, required this.loginLikelySuccess}): _rows = rows,_occurrences = occurrences;
  factory _TimetableData.fromJson(Map<String, dynamic> json) => _$TimetableDataFromJson(json);

 final  List<CourseRow> _rows;
@override List<CourseRow> get rows {
  if (_rows is EqualUnmodifiableListView) return _rows;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_rows);
}

 final  List<CourseOccurrence> _occurrences;
@override List<CourseOccurrence> get occurrences {
  if (_occurrences is EqualUnmodifiableListView) return _occurrences;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_occurrences);
}

@override final  bool loginLikelySuccess;

/// Create a copy of TimetableData
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TimetableDataCopyWith<_TimetableData> get copyWith => __$TimetableDataCopyWithImpl<_TimetableData>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TimetableDataToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TimetableData&&const DeepCollectionEquality().equals(other._rows, _rows)&&const DeepCollectionEquality().equals(other._occurrences, _occurrences)&&(identical(other.loginLikelySuccess, loginLikelySuccess) || other.loginLikelySuccess == loginLikelySuccess));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_rows),const DeepCollectionEquality().hash(_occurrences),loginLikelySuccess);

@override
String toString() {
  return 'TimetableData(rows: $rows, occurrences: $occurrences, loginLikelySuccess: $loginLikelySuccess)';
}


}

/// @nodoc
abstract mixin class _$TimetableDataCopyWith<$Res> implements $TimetableDataCopyWith<$Res> {
  factory _$TimetableDataCopyWith(_TimetableData value, $Res Function(_TimetableData) _then) = __$TimetableDataCopyWithImpl;
@override @useResult
$Res call({
 List<CourseRow> rows, List<CourseOccurrence> occurrences, bool loginLikelySuccess
});




}
/// @nodoc
class __$TimetableDataCopyWithImpl<$Res>
    implements _$TimetableDataCopyWith<$Res> {
  __$TimetableDataCopyWithImpl(this._self, this._then);

  final _TimetableData _self;
  final $Res Function(_TimetableData) _then;

/// Create a copy of TimetableData
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? rows = null,Object? occurrences = null,Object? loginLikelySuccess = null,}) {
  return _then(_TimetableData(
rows: null == rows ? _self._rows : rows // ignore: cast_nullable_to_non_nullable
as List<CourseRow>,occurrences: null == occurrences ? _self._occurrences : occurrences // ignore: cast_nullable_to_non_nullable
as List<CourseOccurrence>,loginLikelySuccess: null == loginLikelySuccess ? _self.loginLikelySuccess : loginLikelySuccess // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
