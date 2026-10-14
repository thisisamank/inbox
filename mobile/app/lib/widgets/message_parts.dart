import 'package:api/api.dart';
import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

import '../models/email.dart';
import '../utils/format.dart';
import 'email_body.dart';

class MessageCard extends StatelessWidget {
  const MessageCard({
    super.key,
    required this.message,
    required this.attachmentPath,
    required this.access,
    required this.expanded,
    required this.loadImages,
    required this.onToggle,
    required this.onLoadImages,
    required this.onShare,
  });

  final EmailMessage message;
  final String Function(String attachmentId) attachmentPath;
  final AccessSession? access;
  final bool expanded;
  final bool loadImages;
  final VoidCallback onToggle;
  final VoidCallback onLoadImages;
  final Future<void> Function(Attachment attachment) onShare;

  @override
  Widget build(BuildContext context) {
    final c = InColors.of(context);
    final session = access;
    final html = session == null
        ? bodyToHtml(message.body)
        : rewriteInlineImages(bodyToHtml(message.body), {
            for (final a in message.attachments.where((a) => a.isInline))
              a.contentId!: session.baseUrl
                  .resolve(attachmentPath(a.id))
                  .toString(),
          });
    final files = message.attachments.where((a) => !a.isInline).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InkWell(
          onTap: onToggle,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              InSpace.gutter,
              14,
              InSpace.gutter,
              InSpace.s5,
            ),
            child: Row(
              children: [
                InAvatar(message.senderName),
                const SizedBox(width: InSpace.rowGap),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        message.senderName,
                        style: InType.body.copyWith(
                          fontWeight: FontWeight.w600,
                          color: c.ink,
                        ),
                      ),
                      Text(
                        expanded
                            ? 'to ${message.recipient}'
                            : snippetText(message.body, maxLength: 90),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: InType.caption.copyWith(color: c.ink3),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: InSpace.s4),
                Text(
                  formatDetailDate(context, message.date),
                  style: InType.caption.copyWith(color: c.ink3),
                ),
              ],
            ),
          ),
        ),
        if (expanded) ...[
          if (!loadImages && hasRemoteImages(html))
            Padding(
              padding: const EdgeInsets.fromLTRB(
                InSpace.gutter,
                0,
                InSpace.gutter,
                InSpace.s5,
              ),
              child: Material(
                color: c.surface2,
                borderRadius: BorderRadius.circular(InRadius.field),
                child: Padding(
                  padding: const EdgeInsets.only(left: InSpace.s6),
                  child: Row(
                    children: [
                      Icon(
                        Icons.image_not_supported_outlined,
                        size: 18,
                        color: c.ink2,
                      ),
                      const SizedBox(width: InSpace.s4),
                      Expanded(
                        child: Text(
                          'Remote images blocked',
                          style: InType.meta.copyWith(color: c.ink2),
                        ),
                      ),
                      TextButton(
                        onPressed: onLoadImages,
                        child: const Text('Load'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          if (session != null)
            EmailBody(
              html: html,
              rich: looksLikeHtml(message.body),
              loadImages: loadImages,
              access: session,
            ),
          for (final a in files)
            AttachmentTile(attachment: a, onShare: () => onShare(a)),
          const SizedBox(height: InSpace.rowGap),
        ],
        const Divider(),
      ],
    );
  }
}

class AttachmentTile extends StatefulWidget {
  const AttachmentTile({
    super.key,
    required this.attachment,
    required this.onShare,
  });

  final Attachment attachment;
  final Future<void> Function() onShare;

  @override
  State<AttachmentTile> createState() => _AttachmentTileState();
}

class _AttachmentTileState extends State<AttachmentTile> {
  bool _busy = false;

  Future<void> _share() async {
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = true);
    try {
      await widget.onShare();
    } on Exception catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('Could not open ${widget.attachment.filename}: $e'),
        ),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = InColors.of(context);
    final a = widget.attachment;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        InSpace.gutter,
        InSpace.s4,
        InSpace.gutter,
        0,
      ),
      child: Material(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(InRadius.field),
          side: BorderSide(color: c.line),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: _busy ? null : _share,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              InSpace.s6,
              InSpace.s5,
              InSpace.s2,
              InSpace.s5,
            ),
            child: Row(
              children: [
                Icon(Icons.insert_drive_file_outlined, color: c.danger),
                const SizedBox(width: InSpace.s5),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        a.filename,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: InType.meta.copyWith(color: c.ink),
                      ),
                      Text(
                        formatBytes(a.size),
                        style: InType.caption.copyWith(color: c.ink3),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  width: InSpace.touch,
                  height: InSpace.touch,
                  child: _busy
                      ? const Padding(
                          padding: EdgeInsets.all(InSpace.s6),
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(
                          Icons.ios_share,
                          size: 20,
                          semanticLabel: 'Open or share ${a.filename}',
                          color: c.ink2,
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class DraftCard extends StatelessWidget {
  const DraftCard({
    super.key,
    required this.message,
    required this.busy,
    required this.onDiscard,
    required this.onEdit,
    required this.onSend,
  });

  final EmailMessage message;
  final bool busy;
  final VoidCallback onDiscard;
  final VoidCallback onEdit;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    final c = InColors.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        InSpace.gutter,
        14,
        InSpace.gutter,
        14,
      ),
      child: InAgentCard(
        title: 'Draft · not sent',
        children: [
          Padding(
            padding: const EdgeInsets.all(InSpace.s6),
            child: Text(
              htmlToPlainText(message.body),
              style: InType.row.copyWith(color: c.ink, height: 1.5),
            ),
          ),
          if (message.recipient.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                InSpace.s6,
                0,
                InSpace.s6,
                InSpace.s4,
              ),
              child: Text(
                'To ${message.recipient}',
                style: InType.caption.copyWith(color: c.ink3),
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              InSpace.s6,
              0,
              InSpace.s6,
              InSpace.s6,
            ),
            child: Row(
              spacing: InSpace.s4,
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: busy ? null : onDiscard,
                    child: const Text('Discard'),
                  ),
                ),
                Expanded(
                  child: OutlinedButton(
                    onPressed: busy ? null : onEdit,
                    child: const Text('Edit'),
                  ),
                ),
                Expanded(
                  child: FilledButton(
                    onPressed: busy ? null : onSend,
                    child: const Text('Send'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
