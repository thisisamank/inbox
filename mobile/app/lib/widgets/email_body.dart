import 'package:api/api.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart';

import '../di/service_locator.dart';

class EmailBody extends StatelessWidget {
  const EmailBody({
    super.key,
    required this.html,
    required this.rich,
    required this.loadImages,
    required this.access,
  });

  final String html;
  final bool rich;
  final bool loadImages;
  final AccessSession access;

  @override
  Widget build(BuildContext context) {
    final c = InColors.of(context);
    final paper = rich && Theme.of(context).brightness == Brightness.dark;
    final body = HtmlWidget(
      html,
      key: ValueKey(loadImages),
      factoryBuilder: () =>
          _EmailWidgetFactory(access: access, allowRemote: loadImages),
      textStyle: InType.body.copyWith(color: paper ? InColors.paperInk : c.ink),
      onTapUrl: (url) async {
        final uri = Uri.tryParse(url);
        if (uri == null ||
            !const {'http', 'https', 'mailto'}.contains(uri.scheme)) {
          return true;
        }
        await browser.open(uri, inApp: false);
        return true;
      },
    );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: InSpace.gutter),
      child: paper
          ? DecoratedBox(
              decoration: BoxDecoration(
                color: InColors.paper,
                borderRadius: BorderRadius.circular(InRadius.field),
              ),
              child: Padding(
                padding: const EdgeInsets.all(InSpace.s6),
                child: body,
              ),
            )
          : body,
    );
  }
}

bool isOwnAttachment(Uri uri, Uri inbox) =>
    uri.origin == inbox.origin &&
    uri.path.startsWith('/api/v1/mailboxes/') &&
    uri.path.contains('/attachments/');

class _EmailWidgetFactory extends WidgetFactory {
  _EmailWidgetFactory({required this.access, required this.allowRemote});

  final AccessSession access;
  final bool allowRemote;

  @override
  ImageProvider? imageProviderFromNetwork(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null || (uri.scheme != 'https' && uri.scheme != 'http')) {
      return null;
    }
    if (isOwnAttachment(uri, access.baseUrl)) {
      return NetworkImage(url, headers: access.headers);
    }
    return allowRemote ? NetworkImage(url) : null;
  }

  @override
  ImageProvider? imageProviderFromAsset(String url) => null;

  @override
  ImageProvider? imageProviderFromFileUri(String url) => null;
}
