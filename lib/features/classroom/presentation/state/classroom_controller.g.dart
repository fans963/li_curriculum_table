// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'classroom_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(ClassroomController)
final classroomControllerProvider = ClassroomControllerProvider._();

final class ClassroomControllerProvider
    extends $NotifierProvider<ClassroomController, ClassroomState> {
  ClassroomControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'classroomControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$classroomControllerHash();

  @$internal
  @override
  ClassroomController create() => ClassroomController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ClassroomState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ClassroomState>(value),
    );
  }
}

String _$classroomControllerHash() =>
    r'71e539e10a7a91172a9aec208f4fb82024b26ec6';

abstract class _$ClassroomController extends $Notifier<ClassroomState> {
  ClassroomState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<ClassroomState, ClassroomState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ClassroomState, ClassroomState>,
              ClassroomState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
