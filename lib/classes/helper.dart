import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:universal_html/html.dart' as html;

enum PlatformCustom {
  android,
  desktop,
  iOS,
  webDesktop,
  webMobile,
}

PlatformCustom getPlatform() {
  if (kIsWeb) {
    String userAgent = html.window.navigator.userAgent.toString().toLowerCase();
    // Smartphone
    if (userAgent.contains("iphone")) return PlatformCustom.webMobile;
    if (userAgent.contains("android")) return PlatformCustom.webMobile;

    // Tablet
    if (userAgent.contains("ipad")) return PlatformCustom.webMobile;
    if (html.window.navigator.platform!.toLowerCase().contains("macintel") &&
        (html.window.navigator.maxTouchPoints ?? 0) > 0)
      return PlatformCustom.webMobile;

    return PlatformCustom.webDesktop;
  } else {
    if (Platform.isAndroid) {
      return PlatformCustom.android;
    };
    if (Platform.isIOS) {
      return PlatformCustom.iOS;
    };
    if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
      return PlatformCustom.desktop;
    };
  }
  throw Exception("Error: Cannot detect platform");
}
