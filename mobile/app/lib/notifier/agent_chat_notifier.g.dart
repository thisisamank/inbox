// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'agent_chat_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(AgentChat)
const agentChatProvider = AgentChatFamily._();

final class AgentChatProvider extends $NotifierProvider<AgentChat, ChatState> {
  const AgentChatProvider._({
    required AgentChatFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'agentChatProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$agentChatHash();

  @override
  String toString() {
    return r'agentChatProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  AgentChat create() => AgentChat();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ChatState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ChatState>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is AgentChatProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$agentChatHash() => r'385135ec6c65f87bb2a881b920e5c4a28ab187d9';

final class AgentChatFamily extends $Family
    with
        $ClassFamilyOverride<
          AgentChat,
          ChatState,
          ChatState,
          ChatState,
          String
        > {
  const AgentChatFamily._()
    : super(
        retry: null,
        name: r'agentChatProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  AgentChatProvider call(String mailboxId) =>
      AgentChatProvider._(argument: mailboxId, from: this);

  @override
  String toString() => r'agentChatProvider';
}

abstract class _$AgentChat extends $Notifier<ChatState> {
  late final _$args = ref.$arg as String;
  String get mailboxId => _$args;

  ChatState build(String mailboxId);
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build(_$args);
    final ref = this.ref as $Ref<ChatState, ChatState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ChatState, ChatState>,
              ChatState,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
