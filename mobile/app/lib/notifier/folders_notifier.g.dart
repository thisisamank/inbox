// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'folders_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(Folders)
const foldersProvider = FoldersFamily._();

final class FoldersProvider
    extends $AsyncNotifierProvider<Folders, List<Folder>> {
  const FoldersProvider._({
    required FoldersFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'foldersProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$foldersHash();

  @override
  String toString() {
    return r'foldersProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  Folders create() => Folders();

  @override
  bool operator ==(Object other) {
    return other is FoldersProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$foldersHash() => r'0c921f181b554442f2122a0cf2a0d760e05adc53';

final class FoldersFamily extends $Family
    with
        $ClassFamilyOverride<
          Folders,
          AsyncValue<List<Folder>>,
          List<Folder>,
          FutureOr<List<Folder>>,
          String
        > {
  const FoldersFamily._()
    : super(
        retry: null,
        name: r'foldersProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  FoldersProvider call(String mailboxId) =>
      FoldersProvider._(argument: mailboxId, from: this);

  @override
  String toString() => r'foldersProvider';
}

abstract class _$Folders extends $AsyncNotifier<List<Folder>> {
  late final _$args = ref.$arg as String;
  String get mailboxId => _$args;

  FutureOr<List<Folder>> build(String mailboxId);
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build(_$args);
    final ref = this.ref as $Ref<AsyncValue<List<Folder>>, List<Folder>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<Folder>>, List<Folder>>,
              AsyncValue<List<Folder>>,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}

@ProviderFor(SelectedFolder)
const selectedFolderProvider = SelectedFolderFamily._();

final class SelectedFolderProvider
    extends $NotifierProvider<SelectedFolder, String> {
  const SelectedFolderProvider._({
    required SelectedFolderFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'selectedFolderProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$selectedFolderHash();

  @override
  String toString() {
    return r'selectedFolderProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  SelectedFolder create() => SelectedFolder();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is SelectedFolderProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$selectedFolderHash() => r'6c1d0968b19f1ba28dcdc03a2da134c3c7356912';

final class SelectedFolderFamily extends $Family
    with $ClassFamilyOverride<SelectedFolder, String, String, String, String> {
  const SelectedFolderFamily._()
    : super(
        retry: null,
        name: r'selectedFolderProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  SelectedFolderProvider call(String mailboxId) =>
      SelectedFolderProvider._(argument: mailboxId, from: this);

  @override
  String toString() => r'selectedFolderProvider';
}

abstract class _$SelectedFolder extends $Notifier<String> {
  late final _$args = ref.$arg as String;
  String get mailboxId => _$args;

  String build(String mailboxId);
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build(_$args);
    final ref = this.ref as $Ref<String, String>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<String, String>,
              String,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
