// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'timetable_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(TimetableController)
final timetableControllerProvider = TimetableControllerProvider._();

final class TimetableControllerProvider
    extends $NotifierProvider<TimetableController, TimetableState> {
  TimetableControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'timetableControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$timetableControllerHash();

  @$internal
  @override
  TimetableController create() => TimetableController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TimetableState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TimetableState>(value),
    );
  }
}

String _$timetableControllerHash() =>
    r'021bedd11c31b68c5b01a304aa1cec4c21c9e6bc';

abstract class _$TimetableController extends $Notifier<TimetableState> {
  TimetableState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<TimetableState, TimetableState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<TimetableState, TimetableState>,
              TimetableState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
