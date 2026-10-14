import 'package:url_launcher/url_launcher.dart';

abstract interface class Browser {
  Future<bool> open(Uri url, {bool inApp = true});
  Future<void> close();
}

class SystemBrowser implements Browser {
  const SystemBrowser();

  @override
  Future<bool> open(Uri url, {bool inApp = true}) => launchUrl(
    url,
    mode: inApp ? LaunchMode.inAppBrowserView : LaunchMode.externalApplication,
  );

  @override
  Future<void> close() async {
    try {
      await closeInAppWebView();
    } on Object catch (_) {}
  }
}
