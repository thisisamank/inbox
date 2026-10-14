import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/compose.dart';
import '../../models/thread.dart';
import '../../notifier/compose_notifier.dart';
import '../../notifier/mailboxes_notifier.dart';
import '../../widgets/rewrite_sheet.dart';

class ComposeScreen extends ConsumerStatefulWidget {
  const ComposeScreen({super.key, required this.mailboxId, required this.args});

  final String mailboxId;
  final ComposeArgs args;

  @override
  ConsumerState<ComposeScreen> createState() => _ComposeScreenState();
}

class _ComposeScreenState extends ConsumerState<ComposeScreen> {
  final _to = TextEditingController();
  final _cc = TextEditingController();
  final _bcc = TextEditingController();
  final _subject = TextEditingController();
  final _body = TextEditingController();
  bool _showCcBcc = false;
  late String _initial;

  ComposeProvider get _provider =>
      composeProvider(widget.mailboxId, widget.args);

  Compose get _compose => ref.read(_provider.notifier);

  ComposeFields get _fields => ComposeFields(
    to: _to.text,
    cc: _cc.text,
    bcc: _bcc.text,
    subject: _subject.text,
    body: _body.text,
  );

  String get _snapshot => [
    _to.text,
    _cc.text,
    _bcc.text,
    _subject.text,
    _body.text,
    ref.read(_provider).attachments.length,
  ].join('\u0000');

  @override
  void initState() {
    super.initState();
    final args = widget.args;
    final draft = args.draft;
    final original = args.original;
    if (draft != null) {
      _to.text = draft.recipient;
      _cc.text = draft.cc ?? '';
      _bcc.text = draft.bcc ?? '';
      _subject.text = draft.subject;
      _body.text = htmlToPlainText(draft.body);
      _showCcBcc = _cc.text.isNotEmpty || _bcc.text.isNotEmpty;
    } else if (original != null) {
      switch (args.mode) {
        case ComposeMode.reply:
          _to.text = original.sender;
          _subject.text = prefixedSubject(original.subject, 'Re');
        case ComposeMode.replyAll:
          final r = replyAllRecipients(
            sender: original.sender,
            recipient: original.recipient,
            cc: original.cc,
            self: widget.mailboxId,
          );
          _to.text = r.to;
          _cc.text = r.cc;
          _showCcBcc = r.cc.isNotEmpty;
          _subject.text = prefixedSubject(original.subject, 'Re');
        case ComposeMode.forward:
          _subject.text = prefixedSubject(original.subject, 'Fwd');
        case ComposeMode.compose:
          break;
      }
    }
    _initial = [
      _to.text,
      _cc.text,
      _bcc.text,
      _subject.text,
      _body.text,
      0,
    ].join('\u0000');
  }

  @override
  void dispose() {
    for (final c in [_to, _cc, _bcc, _subject, _body]) {
      c.dispose();
    }
    super.dispose();
  }

  void _finish(Outcome? outcome) {
    if (outcome != null && mounted) Navigator.of(context).pop(outcome);
  }

  Future<void> _close() async {
    if (ref.read(_provider).busy) return;
    if (_snapshot == _initial) {
      Navigator.of(context).pop();
      return;
    }
    _finish(await _compose.saveDraft(_fields));
  }

  Future<void> _rewrite() async {
    if (_body.text.trim().isEmpty) {
      _compose.fail('Write something first, then ask the agent to rewrite it.');
      return;
    }
    final result = await showRewriteSheet(
      context,
      mailboxId: widget.mailboxId,
      text: _body.text.trim(),
    );
    if (result != null && mounted) setState(() => _body.text = result);
  }

  String get _title => switch (widget.args.effectiveMode) {
    ComposeMode.compose => widget.args.draft != null ? 'Draft' : 'New message',
    ComposeMode.reply => 'Reply',
    ComposeMode.replyAll => 'Reply all',
    ComposeMode.forward => 'Forward',
  };

  @override
  Widget build(BuildContext context) {
    final c = InColors.of(context);
    final state = ref.watch(_provider);
    final details = ref.watch(mailboxDetailsProvider(widget.mailboxId)).value;
    final original = state.original;
    final quotes = _compose.quotes;
    final mode = widget.args.effectiveMode;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _close();
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            tooltip: 'Close and save draft',
            onPressed: _close,
            icon: const Icon(Icons.close),
          ),
          title: Text(
            _title,
            style: InType.subheading.copyWith(fontSize: 17, color: c.ink),
          ),
          actions: [
            IconButton(
              tooltip: 'Attach file',
              onPressed: state.busy ? null : _compose.attach,
              icon: const Icon(Icons.attach_file),
            ),
            PopupMenuButton<String>(
              enabled: !state.busy,
              onSelected: (v) async {
                if (v == 'discard') _finish(await _compose.discard());
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'discard', child: Text('Discard')),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(right: InSpace.s4),
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  minimumSize: const Size(0, 40),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                ),
                onPressed: state.busy
                    ? null
                    : () async => _finish(await _compose.send(_fields)),
                icon: state.busy
                    ? SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: c.onAccent,
                        ),
                      )
                    : const Icon(Icons.send, size: 18),
                label: const Text('Send'),
              ),
            ),
          ],
        ),
        body: ListView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          children: [
            InFieldRow(
              label: 'From',
              child: Text(
                details == null || details.fromName.isEmpty
                    ? widget.mailboxId
                    : '${details.fromName} <${widget.mailboxId}>',
                style: InType.mono.copyWith(color: c.ink),
              ),
            ),
            InFieldRow(
              label: 'To',
              trailing: _showCcBcc
                  ? null
                  : TextButton(
                      style: TextButton.styleFrom(
                        minimumSize: const Size(InSpace.touch, 36),
                      ),
                      onPressed: () => setState(() => _showCcBcc = true),
                      child: const Text('Cc/Bcc'),
                    ),
              child: _AddressField(
                controller: _to,
                label: 'To',
                autofocus: _to.text.isEmpty,
              ),
            ),
            if (_showCcBcc) ...[
              InFieldRow(
                label: 'Cc',
                child: _AddressField(controller: _cc, label: 'Cc'),
              ),
              InFieldRow(
                label: 'Bcc',
                child: _AddressField(controller: _bcc, label: 'Bcc'),
              ),
            ],
            InFieldRow(
              label: 'Subject',
              child: TextField(
                controller: _subject,
                textCapitalization: TextCapitalization.sentences,
                decoration: inBareField(''),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                InSpace.gutter,
                InSpace.gutter,
                InSpace.gutter,
                InSpace.s4,
              ),
              child: TextField(
                controller: _body,
                autofocus: _to.text.isNotEmpty,
                maxLines: null,
                minLines: 8,
                keyboardType: TextInputType.multiline,
                textCapitalization: TextCapitalization.sentences,
                style: InType.body.copyWith(height: 1.6),
                decoration: inBareField('Write your message'),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                InSpace.gutter,
                0,
                InSpace.gutter,
                InSpace.s4,
              ),
              child: Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 40),
                    foregroundColor: c.agent,
                    side: BorderSide(color: c.agent),
                  ),
                  onPressed: state.busy ? null : _rewrite,
                  icon: const Icon(Icons.auto_awesome, size: 18),
                  label: const Text('Rewrite with agent'),
                ),
              ),
            ),
            for (final a in state.attachments)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  InSpace.gutter,
                  InSpace.s2,
                  InSpace.gutter,
                  InSpace.s2,
                ),
                child: Material(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(InRadius.field),
                    side: BorderSide(color: c.line),
                  ),
                  child: ListTile(
                    leading: Icon(
                      Icons.insert_drive_file_outlined,
                      color: c.danger,
                    ),
                    title: Text(
                      a.filename,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: InType.meta,
                    ),
                    subtitle: Text(formatBytes(a.bytes.length)),
                    trailing: IconButton(
                      tooltip: 'Remove ${a.filename}',
                      onPressed: () => _compose.remove(a),
                      icon: const Icon(Icons.close),
                    ),
                  ),
                ),
              ),
            if (quotes && original != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  InSpace.gutter,
                  InSpace.rowGap,
                  InSpace.gutter,
                  InSpace.s9,
                ),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    border: Border(left: BorderSide(color: c.line, width: 2)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.only(left: InSpace.rowGap),
                    child: Text(
                      mode == ComposeMode.forward
                          ? forwardText(
                              original.date,
                              original.sender,
                              original.subject,
                              original.body,
                            )
                          : 'On ${composeDate(original.date)}, ${original.sender} wrote:\n\n${htmlToPlainText(original.body)}',
                      maxLines: 12,
                      overflow: TextOverflow.ellipsis,
                      style: InType.meta.copyWith(color: c.ink3, height: 1.5),
                    ),
                  ),
                ),
              ),
            if (state.error != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  InSpace.gutter,
                  InSpace.s4,
                  InSpace.gutter,
                  InSpace.s9,
                ),
                child: Text(
                  state.error!,
                  style: InType.body.copyWith(color: c.danger),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _AddressField extends StatelessWidget {
  const _AddressField({
    required this.controller,
    required this.label,
    this.autofocus = false,
  });

  final TextEditingController controller;
  final String label;
  final bool autofocus;

  @override
  Widget build(BuildContext context) => Semantics(
    label: label,
    child: TextField(
      controller: controller,
      autofocus: autofocus,
      autocorrect: false,
      enableSuggestions: false,
      keyboardType: TextInputType.emailAddress,
      maxLines: null,
      style: InType.mono,
      decoration: inBareField('name@example.com, …'),
    ),
  );
}
