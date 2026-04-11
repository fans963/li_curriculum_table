// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'classroom_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(classroomRemoteDataSource)
final classroomRemoteDataSourceProvider = ClassroomRemoteDataSourceProvider._();

final class ClassroomRemoteDataSourceProvider
    extends
        $FunctionalProvider<
          ClassroomRemoteDataSource,
          ClassroomRemoteDataSource,
          ClassroomRemoteDataSource
        >
    with $Provider<ClassroomRemoteDataSource> {
  ClassroomRemoteDataSourceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'classroomRemoteDataSourceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$classroomRemoteDataSourceHash();

  @$internal
  @override
  $ProviderElement<ClassroomRemoteDataSource> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ClassroomRemoteDataSource create(Ref ref) {
    return classroomRemoteDataSource(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ClassroomRemoteDataSource value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ClassroomRemoteDataSource>(value),
    );
  }
}

String _$classroomRemoteDataSourceHash() =>
    r'52c31536b5574a3d40844156690cfa1e7d153d86';

@ProviderFor(classroomLocalDataSource)
final classroomLocalDataSourceProvider = ClassroomLocalDataSourceProvider._();

final class ClassroomLocalDataSourceProvider
    extends
        $FunctionalProvider<
          ClassroomLocalDataSource,
          ClassroomLocalDataSource,
          ClassroomLocalDataSource
        >
    with $Provider<ClassroomLocalDataSource> {
  ClassroomLocalDataSourceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'classroomLocalDataSourceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$classroomLocalDataSourceHash();

  @$internal
  @override
  $ProviderElement<ClassroomLocalDataSource> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ClassroomLocalDataSource create(Ref ref) {
    return classroomLocalDataSource(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ClassroomLocalDataSource value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ClassroomLocalDataSource>(value),
    );
  }
}

String _$classroomLocalDataSourceHash() =>
    r'69e3d6ed062d5a22311ef9b7a13e507c88d9ae81';

@ProviderFor(classroomRepository)
final classroomRepositoryProvider = ClassroomRepositoryProvider._();

final class ClassroomRepositoryProvider
    extends
        $FunctionalProvider<
          ClassroomRepository,
          ClassroomRepository,
          ClassroomRepository
        >
    with $Provider<ClassroomRepository> {
  ClassroomRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'classroomRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$classroomRepositoryHash();

  @$internal
  @override
  $ProviderElement<ClassroomRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ClassroomRepository create(Ref ref) {
    return classroomRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ClassroomRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ClassroomRepository>(value),
    );
  }
}

String _$classroomRepositoryHash() =>
    r'f4311dbff5bf8479b80cb30dbe28ddcac1e80541';
