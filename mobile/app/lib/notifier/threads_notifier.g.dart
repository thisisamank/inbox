// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'threads_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(Threads)
const threadsProvider = ThreadsFamily._();

final class ThreadsProvider
    extends $AsyncNotifierProvider<Threads, ThreadList> {
  const ThreadsProvider._({
    required ThreadsFamily super.from,
    required (String, String) super.argument,
  }) : super(
         retry: null,
         name: r'threadsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$threadsHash();

  @override
  String toString() {
    return r'threadsProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  Threads create() => Threads();

  @override
  bool operator ==(Object other) {
    return other is ThreadsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$threadsHash() => r'e189febb34d33d1cddb87279fc9404b51bee773c';

final class ThreadsFamily extends $Family
    with
        $ClassFamilyOverride<
          Threads,
          AsyncValue<ThreadList>,
          ThreadList,
          FutureOr<ThreadList>,
          (String, String)
        > {
  const ThreadsFamily._()
    : super(
        retry: null,
        name: r'threadsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  ThreadsProvider call(String mailboxId, String folder) =>
      ThreadsProvider._(argument: (mailboxId, folder), from: this);

  @override
  String toString() => r'threadsProvider';
}

abstract class _$Threads extends $AsyncNotifier<ThreadList> {
  late final _$args = ref.$arg as (String, String);
  String get mailboxId => _$args.$1;
  String get folder => _$args.$2;

  FutureOr<ThreadList> build(String mailboxId, String folder);
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build(_$args.$1, _$args.$2);
    final ref = this.ref as $Ref<AsyncValue<ThreadList>, ThreadList>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<ThreadList>, ThreadList>,
              AsyncValue<ThreadList>,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
