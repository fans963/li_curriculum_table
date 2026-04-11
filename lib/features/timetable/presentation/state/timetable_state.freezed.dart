// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'timetable_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$TimetableState {

 bool get isLoading; String get status; int get currentTeachingWeek; int get displayWeek; int get referenceWeek; int get minWeek; int get maxWeek; DateTime? get termStartMonday; TimetableData? get data; bool get needsLogin;
/// Create a copy of TimetableState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TimetableStateCopyWith<TimetableState> get copyWith => _$TimetableStateCopyWithImpl<TimetableState>(this as TimetableState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TimetableState&&(identical(other.isLoading, isLoading) || other.isLoading == isLoading)&&(identical(other.status, status) || other.status == status)&&(identical(other.currentTeachingWeek, currentTeachingWeek) || other.currentTeachingWeek == currentTeachingWeek)&&(identical(other.displayWeek, displayWeek) || other.displayWeek == displayWeek)&&(identical(other.referenceWeek, referenceWeek) || other.referenceWeek == referenceWeek)&&(identical(other.minWeek, minWeek) || other.minWeek == minWeek)&&(identical(other.maxWeek, maxWeek) || other.maxWeek == maxWeek)&&(identical(other.termStartMonday, termStartMonday) || other.termStartMonday == termStartMonday)&&(identical(other.data, data) || other.data == data)&&(identical(other.needsLogin, needsLogin) || other.needsLogin == needsLogin));
}


@override
int get hashCode => Object.hash(runtimeType,isLoading,status,currentTeachingWeek,displayWeek,referenceWeek,minWeek,maxWeek,termStartMonday,data,needsLogin);

@override
String toString() {
  return 'TimetableState(isLoading: $isLoading, status: $status, currentTeachingWeek: $currentTeachingWeek, displayWeek: $displayWeek, referenceWeek: $referenceWeek, minWeek: $minWeek, maxWeek: $maxWeek, termStartMonday: $termStartMonday, data: $data, needsLogin: $needsLogin)';
}


}

/// @nodoc
abstract mixin class $TimetableStateCopyWith<$Res>  {
  factory $TimetableStateCopyWith(TimetableState value, $Res Function(TimetableState) _then) = _$TimetableStateCopyWithImpl;
@useResult
$Res call({
 bool isLoading, String status, int currentTeachingWeek, int displayWeek, int referenceWeek, int minWeek, int maxWeek, DateTime? termStartMonday, TimetableData? data, bool needsLogin
});


$TimetableDataCopyWith<$Res>? get data;

}
/// @nodoc
class _$TimetableStateCopyWithImpl<$Res>
    implements $TimetableStateCopyWith<$Res> {
  _$TimetableStateCopyWithImpl(this._self, this._then);

  final TimetableState _self;
  final $Res Function(TimetableState) _then;

/// Create a copy of TimetableState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? isLoading = null,Object? status = null,Object? currentTeachingWeek = null,Object? displayWeek = null,Object? referenceWeek = null,Object? minWeek = null,Object? maxWeek = null,Object? termStartMonday = freezed,Object? data = freezed,Object? needsLogin = null,}) {
  return _then(_self.copyWith(
isLoading: null == isLoading ? _self.isLoading : isLoading // ignore: cast_nullable_to_non_nullable
as bool,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,currentTeachingWeek: null == currentTeachingWeek ? _self.currentTeachingWeek : currentTeachingWeek // ignore: cast_nullable_to_non_nullable
as int,displayWeek: null == displayWeek ? _self.displayWeek : displayWeek // ignore: cast_nullable_to_non_nullable
as int,referenceWeek: null == referenceWeek ? _self.referenceWeek : referenceWeek // ignore: cast_nullable_to_non_nullable
as int,minWeek: null == minWeek ? _self.minWeek : minWeek // ignore: cast_nullable_to_non_nullable
as int,maxWeek: null == maxWeek ? _self.maxWeek : maxWeek // ignore: cast_nullable_to_non_nullable
as int,termStartMonday: freezed == termStartMonday ? _self.termStartMonday : termStartMonday // ignore: cast_nullable_to_non_nullable
as DateTime?,data: freezed == data ? _self.data : data // ignore: cast_nullable_to_non_nullable
as TimetableData?,needsLogin: null == needsLogin ? _self.needsLogin : needsLogin // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}
/// Create a copy of TimetableState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TimetableDataCopyWith<$Res>? get data {
    if (_self.data == null) {
    return null;
  }

  return $TimetableDataCopyWith<$Res>(_self.data!, (value) {
    return _then(_self.copyWith(data: value));
  });
}
}


/// Adds pattern-matching-related methods to [TimetableState].
extension TimetableStatePatterns on TimetableState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TimetableState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TimetableState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TimetableState value)  $default,){
final _that = this;
switch (_that) {
case _TimetableState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TimetableState value)?  $default,){
final _that = this;
switch (_that) {
case _TimetableState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool isLoading,  String status,  int currentTeachingWeek,  int displayWeek,  int referenceWeek,  int minWeek,  int maxWeek,  DateTime? termStartMonday,  TimetableData? data,  bool needsLogin)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TimetableState() when $default != null:
return $default(_that.isLoading,_that.status,_that.currentTeachingWeek,_that.displayWeek,_that.referenceWeek,_that.minWeek,_that.maxWeek,_that.termStartMonday,_that.data,_that.needsLogin);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool isLoading,  String status,  int currentTeachingWeek,  int displayWeek,  int referenceWeek,  int minWeek,  int maxWeek,  DateTime? termStartMonday,  TimetableData? data,  bool needsLogin)  $default,) {final _that = this;
switch (_that) {
case _TimetableState():
return $default(_that.isLoading,_that.status,_that.currentTeachingWeek,_that.displayWeek,_that.referenceWeek,_that.minWeek,_that.maxWeek,_that.termStartMonday,_that.data,_that.needsLogin);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool isLoading,  String status,  int currentTeachingWeek,  int displayWeek,  int referenceWeek,  int minWeek,  int maxWeek,  DateTime? termStartMonday,  TimetableData? data,  bool needsLogin)?  $default,) {final _that = this;
switch (_that) {
case _TimetableState() when $default != null:
return $default(_that.isLoading,_that.status,_that.currentTeachingWeek,_that.displayWeek,_that.referenceWeek,_that.minWeek,_that.maxWeek,_that.termStartMonday,_that.data,_that.needsLogin);case _:
  return null;

}
}

}

/// @nodoc


class _TimetableState implements TimetableState {
  const _TimetableState({required this.isLoading, required this.status, required this.currentTeachingWeek, required this.displayWeek, required this.referenceWeek, required this.minWeek, required this.maxWeek, this.termStartMonday, this.data, this.needsLogin = false});
  

@override final  bool isLoading;
@override final  String status;
@override final  int currentTeachingWeek;
@override final  int displayWeek;
@override final  int referenceWeek;
@override final  int minWeek;
@override final  int maxWeek;
@override final  DateTime? termStartMonday;
@override final  TimetableData? data;
@override@JsonKey() final  bool needsLogin;

/// Create a copy of TimetableState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TimetableStateCopyWith<_TimetableState> get copyWith => __$TimetableStateCopyWithImpl<_TimetableState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TimetableState&&(identical(other.isLoading, isLoading) || other.isLoading == isLoading)&&(identical(other.status, status) || other.status == status)&&(identical(other.currentTeachingWeek, currentTeachingWeek) || other.currentTeachingWeek == currentTeachingWeek)&&(identical(other.displayWeek, displayWeek) || other.displayWeek == displayWeek)&&(identical(other.referenceWeek, referenceWeek) || other.referenceWeek == referenceWeek)&&(identical(other.minWeek, minWeek) || other.minWeek == minWeek)&&(identical(other.maxWeek, maxWeek) || other.maxWeek == maxWeek)&&(identical(other.termStartMonday, termStartMonday) || other.termStartMonday == termStartMonday)&&(identical(other.data, data) || other.data == data)&&(identical(other.needsLogin, needsLogin) || other.needsLogin == needsLogin));
}


@override
int get hashCode => Object.hash(runtimeType,isLoading,status,currentTeachingWeek,displayWeek,referenceWeek,minWeek,maxWeek,termStartMonday,data,needsLogin);

@override
String toString() {
  return 'TimetableState(isLoading: $isLoading, status: $status, currentTeachingWeek: $currentTeachingWeek, displayWeek: $displayWeek, referenceWeek: $referenceWeek, minWeek: $minWeek, maxWeek: $maxWeek, termStartMonday: $termStartMonday, data: $data, needsLogin: $needsLogin)';
}


}

/// @nodoc
abstract mixin class _$TimetableStateCopyWith<$Res> implements $TimetableStateCopyWith<$Res> {
  factory _$TimetableStateCopyWith(_TimetableState value, $Res Function(_TimetableState) _then) = __$TimetableStateCopyWithImpl;
@override @useResult
$Res call({
 bool isLoading, String status, int currentTeachingWeek, int displayWeek, int referenceWeek, int minWeek, int maxWeek, DateTime? termStartMonday, TimetableData? data, bool needsLogin
});


@override $TimetableDataCopyWith<$Res>? get data;

}
/// @nodoc
class __$TimetableStateCopyWithImpl<$Res>
    implements _$TimetableStateCopyWith<$Res> {
  __$TimetableStateCopyWithImpl(this._self, this._then);

  final _TimetableState _self;
  final $Res Function(_TimetableState) _then;

/// Create a copy of TimetableState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? isLoading = null,Object? status = null,Object? currentTeachingWeek = null,Object? displayWeek = null,Object? referenceWeek = null,Object? minWeek = null,Object? maxWeek = null,Object? termStartMonday = freezed,Object? data = freezed,Object? needsLogin = null,}) {
  return _then(_TimetableState(
isLoading: null == isLoading ? _self.isLoading : isLoading // ignore: cast_nullable_to_non_nullable
as bool,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,currentTeachingWeek: null == currentTeachingWeek ? _self.currentTeachingWeek : currentTeachingWeek // ignore: cast_nullable_to_non_nullable
as int,displayWeek: null == displayWeek ? _self.displayWeek : displayWeek // ignore: cast_nullable_to_non_nullable
as int,referenceWeek: null == referenceWeek ? _self.referenceWeek : referenceWeek // ignore: cast_nullable_to_non_nullable
as int,minWeek: null == minWeek ? _self.minWeek : minWeek // ignore: cast_nullable_to_non_nullable
as int,maxWeek: null == maxWeek ? _self.maxWeek : maxWeek // ignore: cast_nullable_to_non_nullable
as int,termStartMonday: freezed == termStartMonday ? _self.termStartMonday : termStartMonday // ignore: cast_nullable_to_non_nullable
as DateTime?,data: freezed == data ? _self.data : data // ignore: cast_nullable_to_non_nullable
as TimetableData?,needsLogin: null == needsLogin ? _self.needsLogin : needsLogin // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

/// Create a copy of TimetableState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TimetableDataCopyWith<$Res>? get data {
    if (_self.data == null) {
    return null;
  }

  return $TimetableDataCopyWith<$Res>(_self.data!, (value) {
    return _then(_self.copyWith(data: value));
  });
}
}

// dart format on
