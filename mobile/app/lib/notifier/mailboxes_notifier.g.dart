// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mailboxes_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(Mailboxes)
const mailboxesProvider = MailboxesProvider._();

final class MailboxesProvider
    extends $AsyncNotifierProvider<Mailboxes, List<MailboxSummary>> {
  const MailboxesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'mailboxesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$mailboxesHash();

  @$internal
  @override
  Mailboxes create() => Mailboxes();
}

String _$mailboxesHash() => r'a7c863d6dbb65857adfd23129fd7a3479487d589';

abstract class _$Mailboxes extends $AsyncNotifier<List<MailboxSummary>> {
  FutureOr<List<MailboxSummary>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref =
        this.ref
            as $Ref<AsyncValue<List<MailboxSummary>>, List<MailboxSummary>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<List<MailboxSummary>>,
                List<MailboxSummary>
              >,
              AsyncValue<List<MailboxSummary>>,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}

@ProviderFor(MailboxCreation)
const mailboxCreationProvider = MailboxCreationProvider._();

final class MailboxCreationProvider
    extends $AsyncNotifierProvider<MailboxCreation, Mailbox?> {
  const MailboxCreationProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'mailboxCreationProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$mailboxCreationHash();

  @$internal
  @override
  MailboxCreation create() => MailboxCreation();
}

String _$mailboxCreationHash() => r'3bad8564b73f6a3605eac88056fb0fa82663fb61';

abstract class _$MailboxCreation extends $AsyncNotifier<Mailbox?> {
  FutureOr<Mailbox?> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<AsyncValue<Mailbox?>, Mailbox?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<Mailbox?>, Mailbox?>,
              AsyncValue<Mailbox?>,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}

@ProviderFor(domains)
const domainsProvider = DomainsProvider._();

final class DomainsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<String>>,
          List<String>,
          FutureOr<List<String>>
        >
    with $FutureModifier<List<String>>, $FutureProvider<List<String>> {
  const DomainsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'domainsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$domainsHash();

  @$internal
  @override
  $FutureProviderElement<List<String>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<String>> create(Ref ref) {
    return domains(ref);
  }
}

String _$domainsHash() => r'4ea0b716825047884b317ee2db0d74af3008c458';

@ProviderFor(mailboxDetails)
const mailboxDetailsProvider = MailboxDetailsFamily._();

final class MailboxDetailsProvider
    extends
        $FunctionalProvider<
          AsyncValue<MailboxDetails>,
          MailboxDetails,
          FutureOr<MailboxDetails>
        >
    with $FutureModifier<MailboxDetails>, $FutureProvider<MailboxDetails> {
  const MailboxDetailsProvider._({
    required MailboxDetailsFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'mailboxDetailsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$mailboxDetailsHash();

  @override
  String toString() {
    return r'mailboxDetailsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<MailboxDetails> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<MailboxDetails> create(Ref ref) {
    final argument = this.argument as String;
    return mailboxDetails(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is MailboxDetailsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$mailboxDetailsHash() => r'6ab186b876d634a85f9f17fe581345dfe7141135';

final class MailboxDetailsFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<MailboxDetails>, String> {
  const MailboxDetailsFamily._()
    : super(
        retry: null,
        name: r'mailboxDetailsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  MailboxDetailsProvider call(String mailboxId) =>
      MailboxDetailsProvider._(argument: mailboxId, from: this);

  @override
  String toString() => r'mailboxDetailsProvider';
}
