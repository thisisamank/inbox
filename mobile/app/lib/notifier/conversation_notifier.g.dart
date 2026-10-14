// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'conversation_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(Conversation)
const conversationProvider = ConversationFamily._();

final class ConversationProvider
    extends $AsyncNotifierProvider<Conversation, List<EmailMessage>> {
  const ConversationProvider._({
    required ConversationFamily super.from,
    required (String, ThreadRef) super.argument,
  }) : super(
         retry: null,
         name: r'conversationProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$conversationHash();

  @override
  String toString() {
    return r'conversationProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  Conversation create() => Conversation();

  @override
  bool operator ==(Object other) {
    return other is ConversationProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$conversationHash() => r'84fa7df26164e37ccc14617825800bb39eecc9dc';

final class ConversationFamily extends $Family
    with
        $ClassFamilyOverride<
          Conversation,
          AsyncValue<List<EmailMessage>>,
          List<EmailMessage>,
          FutureOr<List<EmailMessage>>,
          (String, ThreadRef)
        > {
  const ConversationFamily._()
    : super(
        retry: null,
        name: r'conversationProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  ConversationProvider call(String mailboxId, ThreadRef thread) =>
      ConversationProvider._(argument: (mailboxId, thread), from: this);

  @override
  String toString() => r'conversationProvider';
}

abstract class _$Conversation extends $AsyncNotifier<List<EmailMessage>> {
  late final _$args = ref.$arg as (String, ThreadRef);
  String get mailboxId => _$args.$1;
  ThreadRef get thread => _$args.$2;

  FutureOr<List<EmailMessage>> build(String mailboxId, ThreadRef thread);
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build(_$args.$1, _$args.$2);
    final ref =
        this.ref as $Ref<AsyncValue<List<EmailMessage>>, List<EmailMessage>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<EmailMessage>>, List<EmailMessage>>,
              AsyncValue<List<EmailMessage>>,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}

@ProviderFor(email)
const emailProvider = EmailFamily._();

final class EmailProvider
    extends
        $FunctionalProvider<
          AsyncValue<EmailMessage>,
          EmailMessage,
          FutureOr<EmailMessage>
        >
    with $FutureModifier<EmailMessage>, $FutureProvider<EmailMessage> {
  const EmailProvider._({
    required EmailFamily super.from,
    required (String, String) super.argument,
  }) : super(
         retry: null,
         name: r'emailProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$emailHash();

  @override
  String toString() {
    return r'emailProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<EmailMessage> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<EmailMessage> create(Ref ref) {
    final argument = this.argument as (String, String);
    return email(ref, argument.$1, argument.$2);
  }

  @override
  bool operator ==(Object other) {
    return other is EmailProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$emailHash() => r'fc1d97ad3cc47f2ad7fbe56a8d1e5f32908f4a0d';

final class EmailFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<EmailMessage>, (String, String)> {
  const EmailFamily._()
    : super(
        retry: null,
        name: r'emailProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  EmailProvider call(String mailboxId, String emailId) =>
      EmailProvider._(argument: (mailboxId, emailId), from: this);

  @override
  String toString() => r'emailProvider';
}

@ProviderFor(inboxAccess)
const inboxAccessProvider = InboxAccessProvider._();

final class InboxAccessProvider
    extends
        $FunctionalProvider<
          AsyncValue<AccessSession>,
          AccessSession,
          FutureOr<AccessSession>
        >
    with $FutureModifier<AccessSession>, $FutureProvider<AccessSession> {
  const InboxAccessProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'inboxAccessProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$inboxAccessHash();

  @$internal
  @override
  $FutureProviderElement<AccessSession> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<AccessSession> create(Ref ref) {
    return inboxAccess(ref);
  }
}

String _$inboxAccessHash() => r'9bfba57a4c8b458c3c7fe38ab622045b3ac3cd82';
