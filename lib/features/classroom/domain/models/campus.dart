import 'package:freezed_annotation/freezed_annotation.dart';

part 'campus.freezed.dart';
part 'campus.g.dart';

@freezed
abstract class Campus with _$Campus {
  const factory Campus({
    required String id,
    required String name,
  }) = _Campus;

  factory Campus.fromJson(Map<String, dynamic> json) => _$CampusFromJson(json);
}
