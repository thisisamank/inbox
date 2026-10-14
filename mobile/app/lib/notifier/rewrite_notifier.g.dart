// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'rewrite_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(Rewrite)
const rewriteProvider = RewriteFamily._();

final class RewriteProvider extends $NotifierProvider<Rewrite, RewriteState> {
  const RewriteProvider._({
    required RewriteFamily super.from,
    required (String, String) super.argument,
  }) : super(
         retry: null,
         name: r'rewriteProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$rewriteHash();

  @override
  String toString() {
    return r'rewriteProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  Rewrite create() => Rewrite();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(RewriteState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<RewriteState>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is RewriteProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$rewriteHash() => r'08af1971fd03b07ee7e70079465be9dbb438ce2b';

final class RewriteFamily extends $Family
    with
        $ClassFamilyOverride<
          Rewrite,
          RewriteState,
          RewriteState,
          RewriteState,
          (String, String)
        > {
  const RewriteFamily._()
    : super(
        retry: null,
        name: r'rewriteProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  RewriteProvider call(String mailboxId, String text) =>
      RewriteProvider._(argument: (mailboxId, text), from: this);

  @override
  String toString() => r'rewriteProvider';
}

abstract class _$Rewrite extends $Notifier<RewriteState> {
  late final _$args = ref.$arg as (String, String);
  String get mailboxId => _$args.$1;
  String get text => _$args.$2;

  RewriteState build(String mailboxId, String text);
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build(_$args.$1, _$args.$2);
    final ref = this.ref as $Ref<RewriteState, RewriteState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<RewriteState, RewriteState>,
              RewriteState,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
