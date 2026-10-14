// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'compose_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(Compose)
const composeProvider = ComposeFamily._();

final class ComposeProvider extends $NotifierProvider<Compose, ComposeState> {
  const ComposeProvider._({
    required ComposeFamily super.from,
    required (String, ComposeArgs) super.argument,
  }) : super(
         retry: null,
         name: r'composeProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$composeHash();

  @override
  String toString() {
    return r'composeProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  Compose create() => Compose();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ComposeState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ComposeState>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is ComposeProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$composeHash() => r'039f91ca62ace45c55d65aeed118c33e69a259a5';

final class ComposeFamily extends $Family
    with
        $ClassFamilyOverride<
          Compose,
          ComposeState,
          ComposeState,
          ComposeState,
          (String, ComposeArgs)
        > {
  const ComposeFamily._()
    : super(
        retry: null,
        name: r'composeProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  ComposeProvider call(String mailboxId, ComposeArgs args) =>
      ComposeProvider._(argument: (mailboxId, args), from: this);

  @override
  String toString() => r'composeProvider';
}

abstract class _$Compose extends $Notifier<ComposeState> {
  late final _$args = ref.$arg as (String, ComposeArgs);
  String get mailboxId => _$args.$1;
  ComposeArgs get args => _$args.$2;

  ComposeState build(String mailboxId, ComposeArgs args);
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build(_$args.$1, _$args.$2);
    final ref = this.ref as $Ref<ComposeState, ComposeState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ComposeState, ComposeState>,
              ComposeState,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
