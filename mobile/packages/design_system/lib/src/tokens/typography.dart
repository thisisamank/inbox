import 'package:flutter/painting.dart';

import 'fonts.dart';

abstract final class InType {
  static const TextStyle title = TextStyle(
    fontFamily: InFonts.sans,
    fontSize: 22,
    height: 1.25,
    fontWeight: FontWeight.w600,
  );
  static const TextStyle heading = TextStyle(
    fontFamily: InFonts.sans,
    fontSize: 20,
    height: 1.25,
    fontWeight: FontWeight.w600,
  );
  static const TextStyle subheading = TextStyle(
    fontFamily: InFonts.sans,
    fontSize: 18,
    height: 1.3,
    fontWeight: FontWeight.w600,
  );
  static const TextStyle body = TextStyle(
    fontFamily: InFonts.sans,
    fontSize: 15,
    height: 1.5,
  );
  static const TextStyle row = TextStyle(
    fontFamily: InFonts.sans,
    fontSize: 14,
    height: 1.4,
  );
  static const TextStyle meta = TextStyle(
    fontFamily: InFonts.sans,
    fontSize: 13,
    height: 1.4,
  );
  static const TextStyle caption = TextStyle(
    fontFamily: InFonts.sans,
    fontSize: 12,
    height: 1.4,
  );
  static const TextStyle overline = TextStyle(
    fontFamily: InFonts.sans,
    fontSize: 12,
    letterSpacing: 0.7,
  );
  static const TextStyle button = TextStyle(
    fontFamily: InFonts.sans,
    fontSize: 15,
    fontWeight: FontWeight.w500,
  );
  static const TextStyle mono = TextStyle(
    fontFamily: InFonts.mono,
    fontSize: 13,
  );
  static const TextStyle monoSmall = TextStyle(
    fontFamily: InFonts.mono,
    fontSize: 12,
  );
}
