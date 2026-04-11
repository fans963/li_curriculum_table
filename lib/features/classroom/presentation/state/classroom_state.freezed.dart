// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'classroom_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ClassroomState {

 List<Campus> get campuses; Campus? get selectedCampus; List<Building> get buildings; Building? get selectedBuilding; DateTime get selectedDate; List<ClassroomAvailability> get results; bool get isLoading; String? get error; bool get needsLogin; String get currentTerm;
/// Create a copy of ClassroomState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ClassroomStateCopyWith<ClassroomState> get copyWith => _$ClassroomStateCopyWithImpl<ClassroomState>(this as ClassroomState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ClassroomState&&const DeepCollectionEquality().equals(other.campuses, campuses)&&(identical(other.selectedCampus, selectedCampus) || other.selectedCampus == selectedCampus)&&const DeepCollectionEquality().equals(other.buildings, buildings)&&(identical(other.selectedBuilding, selectedBuilding) || other.selectedBuilding == selectedBuilding)&&(identical(other.selectedDate, selectedDate) || other.selectedDate == selectedDate)&&const DeepCollectionEquality().equals(other.results, results)&&(identical(other.isLoading, isLoading) || other.isLoading == isLoading)&&(identical(other.error, error) || other.error == error)&&(identical(other.needsLogin, needsLogin) || other.needsLogin == needsLogin)&&(identical(other.currentTerm, currentTerm) || other.currentTerm == currentTerm));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(campuses),selectedCampus,const DeepCollectionEquality().hash(buildings),selectedBuilding,selectedDate,const DeepCollectionEquality().hash(results),isLoading,error,needsLogin,currentTerm);

@override
String toString() {
  return 'ClassroomState(campuses: $campuses, selectedCampus: $selectedCampus, buildings: $buildings, selectedBuilding: $selectedBuilding, selectedDate: $selectedDate, results: $results, isLoading: $isLoading, error: $error, needsLogin: $needsLogin, currentTerm: $currentTerm)';
}


}

/// @nodoc
abstract mixin class $ClassroomStateCopyWith<$Res>  {
  factory $ClassroomStateCopyWith(ClassroomState value, $Res Function(ClassroomState) _then) = _$ClassroomStateCopyWithImpl;
@useResult
$Res call({
 List<Campus> campuses, Campus? selectedCampus, List<Building> buildings, Building? selectedBuilding, DateTime selectedDate, List<ClassroomAvailability> results, bool isLoading, String? error, bool needsLogin, String currentTerm
});


$CampusCopyWith<$Res>? get selectedCampus;$BuildingCopyWith<$Res>? get selectedBuilding;

}
/// @nodoc
class _$ClassroomStateCopyWithImpl<$Res>
    implements $ClassroomStateCopyWith<$Res> {
  _$ClassroomStateCopyWithImpl(this._self, this._then);

  final ClassroomState _self;
  final $Res Function(ClassroomState) _then;

/// Create a copy of ClassroomState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? campuses = null,Object? selectedCampus = freezed,Object? buildings = null,Object? selectedBuilding = freezed,Object? selectedDate = null,Object? results = null,Object? isLoading = null,Object? error = freezed,Object? needsLogin = null,Object? currentTerm = null,}) {
  return _then(_self.copyWith(
campuses: null == campuses ? _self.campuses : campuses // ignore: cast_nullable_to_non_nullable
as List<Campus>,selectedCampus: freezed == selectedCampus ? _self.selectedCampus : selectedCampus // ignore: cast_nullable_to_non_nullable
as Campus?,buildings: null == buildings ? _self.buildings : buildings // ignore: cast_nullable_to_non_nullable
as List<Building>,selectedBuilding: freezed == selectedBuilding ? _self.selectedBuilding : selectedBuilding // ignore: cast_nullable_to_non_nullable
as Building?,selectedDate: null == selectedDate ? _self.selectedDate : selectedDate // ignore: cast_nullable_to_non_nullable
as DateTime,results: null == results ? _self.results : results // ignore: cast_nullable_to_non_nullable
as List<ClassroomAvailability>,isLoading: null == isLoading ? _self.isLoading : isLoading // ignore: cast_nullable_to_non_nullable
as bool,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as String?,needsLogin: null == needsLogin ? _self.needsLogin : needsLogin // ignore: cast_nullable_to_non_nullable
as bool,currentTerm: null == currentTerm ? _self.currentTerm : currentTerm // ignore: cast_nullable_to_non_nullable
as String,
  ));
}
/// Create a copy of ClassroomState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CampusCopyWith<$Res>? get selectedCampus {
    if (_self.selectedCampus == null) {
    return null;
  }

  return $CampusCopyWith<$Res>(_self.selectedCampus!, (value) {
    return _then(_self.copyWith(selectedCampus: value));
  });
}/// Create a copy of ClassroomState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BuildingCopyWith<$Res>? get selectedBuilding {
    if (_self.selectedBuilding == null) {
    return null;
  }

  return $BuildingCopyWith<$Res>(_self.selectedBuilding!, (value) {
    return _then(_self.copyWith(selectedBuilding: value));
  });
}
}


/// Adds pattern-matching-related methods to [ClassroomState].
extension ClassroomStatePatterns on ClassroomState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ClassroomState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ClassroomState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ClassroomState value)  $default,){
final _that = this;
switch (_that) {
case _ClassroomState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ClassroomState value)?  $default,){
final _that = this;
switch (_that) {
case _ClassroomState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<Campus> campuses,  Campus? selectedCampus,  List<Building> buildings,  Building? selectedBuilding,  DateTime selectedDate,  List<ClassroomAvailability> results,  bool isLoading,  String? error,  bool needsLogin,  String currentTerm)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ClassroomState() when $default != null:
return $default(_that.campuses,_that.selectedCampus,_that.buildings,_that.selectedBuilding,_that.selectedDate,_that.results,_that.isLoading,_that.error,_that.needsLogin,_that.currentTerm);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<Campus> campuses,  Campus? selectedCampus,  List<Building> buildings,  Building? selectedBuilding,  DateTime selectedDate,  List<ClassroomAvailability> results,  bool isLoading,  String? error,  bool needsLogin,  String currentTerm)  $default,) {final _that = this;
switch (_that) {
case _ClassroomState():
return $default(_that.campuses,_that.selectedCampus,_that.buildings,_that.selectedBuilding,_that.selectedDate,_that.results,_that.isLoading,_that.error,_that.needsLogin,_that.currentTerm);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<Campus> campuses,  Campus? selectedCampus,  List<Building> buildings,  Building? selectedBuilding,  DateTime selectedDate,  List<ClassroomAvailability> results,  bool isLoading,  String? error,  bool needsLogin,  String currentTerm)?  $default,) {final _that = this;
switch (_that) {
case _ClassroomState() when $default != null:
return $default(_that.campuses,_that.selectedCampus,_that.buildings,_that.selectedBuilding,_that.selectedDate,_that.results,_that.isLoading,_that.error,_that.needsLogin,_that.currentTerm);case _:
  return null;

}
}

}

/// @nodoc


class _ClassroomState implements ClassroomState {
  const _ClassroomState({final  List<Campus> campuses = const [], this.selectedCampus, final  List<Building> buildings = const [], this.selectedBuilding, required this.selectedDate, final  List<ClassroomAvailability> results = const [], this.isLoading = false, this.error, this.needsLogin = false, this.currentTerm = ''}): _campuses = campuses,_buildings = buildings,_results = results;
  

 final  List<Campus> _campuses;
@override@JsonKey() List<Campus> get campuses {
  if (_campuses is EqualUnmodifiableListView) return _campuses;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_campuses);
}

@override final  Campus? selectedCampus;
 final  List<Building> _buildings;
@override@JsonKey() List<Building> get buildings {
  if (_buildings is EqualUnmodifiableListView) return _buildings;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_buildings);
}

@override final  Building? selectedBuilding;
@override final  DateTime selectedDate;
 final  List<ClassroomAvailability> _results;
@override@JsonKey() List<ClassroomAvailability> get results {
  if (_results is EqualUnmodifiableListView) return _results;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_results);
}

@override@JsonKey() final  bool isLoading;
@override final  String? error;
@override@JsonKey() final  bool needsLogin;
@override@JsonKey() final  String currentTerm;

/// Create a copy of ClassroomState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ClassroomStateCopyWith<_ClassroomState> get copyWith => __$ClassroomStateCopyWithImpl<_ClassroomState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ClassroomState&&const DeepCollectionEquality().equals(other._campuses, _campuses)&&(identical(other.selectedCampus, selectedCampus) || other.selectedCampus == selectedCampus)&&const DeepCollectionEquality().equals(other._buildings, _buildings)&&(identical(other.selectedBuilding, selectedBuilding) || other.selectedBuilding == selectedBuilding)&&(identical(other.selectedDate, selectedDate) || other.selectedDate == selectedDate)&&const DeepCollectionEquality().equals(other._results, _results)&&(identical(other.isLoading, isLoading) || other.isLoading == isLoading)&&(identical(other.error, error) || other.error == error)&&(identical(other.needsLogin, needsLogin) || other.needsLogin == needsLogin)&&(identical(other.currentTerm, currentTerm) || other.currentTerm == currentTerm));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_campuses),selectedCampus,const DeepCollectionEquality().hash(_buildings),selectedBuilding,selectedDate,const DeepCollectionEquality().hash(_results),isLoading,error,needsLogin,currentTerm);

@override
String toString() {
  return 'ClassroomState(campuses: $campuses, selectedCampus: $selectedCampus, buildings: $buildings, selectedBuilding: $selectedBuilding, selectedDate: $selectedDate, results: $results, isLoading: $isLoading, error: $error, needsLogin: $needsLogin, currentTerm: $currentTerm)';
}


}

/// @nodoc
abstract mixin class _$ClassroomStateCopyWith<$Res> implements $ClassroomStateCopyWith<$Res> {
  factory _$ClassroomStateCopyWith(_ClassroomState value, $Res Function(_ClassroomState) _then) = __$ClassroomStateCopyWithImpl;
@override @useResult
$Res call({
 List<Campus> campuses, Campus? selectedCampus, List<Building> buildings, Building? selectedBuilding, DateTime selectedDate, List<ClassroomAvailability> results, bool isLoading, String? error, bool needsLogin, String currentTerm
});


@override $CampusCopyWith<$Res>? get selectedCampus;@override $BuildingCopyWith<$Res>? get selectedBuilding;

}
/// @nodoc
class __$ClassroomStateCopyWithImpl<$Res>
    implements _$ClassroomStateCopyWith<$Res> {
  __$ClassroomStateCopyWithImpl(this._self, this._then);

  final _ClassroomState _self;
  final $Res Function(_ClassroomState) _then;

/// Create a copy of ClassroomState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? campuses = null,Object? selectedCampus = freezed,Object? buildings = null,Object? selectedBuilding = freezed,Object? selectedDate = null,Object? results = null,Object? isLoading = null,Object? error = freezed,Object? needsLogin = null,Object? currentTerm = null,}) {
  return _then(_ClassroomState(
campuses: null == campuses ? _self._campuses : campuses // ignore: cast_nullable_to_non_nullable
as List<Campus>,selectedCampus: freezed == selectedCampus ? _self.selectedCampus : selectedCampus // ignore: cast_nullable_to_non_nullable
as Campus?,buildings: null == buildings ? _self._buildings : buildings // ignore: cast_nullable_to_non_nullable
as List<Building>,selectedBuilding: freezed == selectedBuilding ? _self.selectedBuilding : selectedBuilding // ignore: cast_nullable_to_non_nullable
as Building?,selectedDate: null == selectedDate ? _self.selectedDate : selectedDate // ignore: cast_nullable_to_non_nullable
as DateTime,results: null == results ? _self._results : results // ignore: cast_nullable_to_non_nullable
as List<ClassroomAvailability>,isLoading: null == isLoading ? _self.isLoading : isLoading // ignore: cast_nullable_to_non_nullable
as bool,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as String?,needsLogin: null == needsLogin ? _self.needsLogin : needsLogin // ignore: cast_nullable_to_non_nullable
as bool,currentTerm: null == currentTerm ? _self.currentTerm : currentTerm // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

/// Create a copy of ClassroomState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CampusCopyWith<$Res>? get selectedCampus {
    if (_self.selectedCampus == null) {
    return null;
  }

  return $CampusCopyWith<$Res>(_self.selectedCampus!, (value) {
    return _then(_self.copyWith(selectedCampus: value));
  });
}/// Create a copy of ClassroomState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BuildingCopyWith<$Res>? get selectedBuilding {
    if (_self.selectedBuilding == null) {
    return null;
  }

  return $BuildingCopyWith<$Res>(_self.selectedBuilding!, (value) {
    return _then(_self.copyWith(selectedBuilding: value));
  });
}
}

// dart format on
