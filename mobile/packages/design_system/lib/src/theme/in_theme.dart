import 'package:flutter/material.dart';

import '../tokens/colors.dart';
import '../tokens/fonts.dart';
import '../tokens/spacing.dart';
import '../tokens/typography.dart';

abstract final class InTheme {
  static ThemeData build(Brightness brightness) {
    final c = InColors.forBrightness(brightness);
    final scheme =
        ColorScheme.fromSeed(
          seedColor: c.accent,
          brightness: brightness,
        ).copyWith(
          primary: c.accent,
          onPrimary: c.onAccent,
          surface: c.surface,
          onSurface: c.ink,
          onSurfaceVariant: c.ink2,
          outline: c.line,
          outlineVariant: c.line,
          error: c.danger,
        );
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(InRadius.button),
    );
    const buttonSize = Size(48, 48);
    final fieldBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(InRadius.field),
      borderSide: BorderSide(color: c.line),
    );
    bool on(Set<WidgetState> s) => s.contains(WidgetState.selected);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      fontFamily: InFonts.sans,
      scaffoldBackgroundColor: c.surface,
      extensions: [c],
      dividerTheme: DividerThemeData(color: c.line, space: 1, thickness: 1),
      appBarTheme: AppBarTheme(
        backgroundColor: c.surface,
        foregroundColor: c.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: InType.heading.copyWith(color: c.ink),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: c.surface,
        indicatorColor: c.accentTint,
        height: 64,
        iconTheme: WidgetStateProperty.resolveWith(
          (s) => IconThemeData(color: on(s) ? c.accent : c.ink3),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (s) => InType.caption.copyWith(
            fontWeight: on(s) ? FontWeight.w600 : FontWeight.w400,
            color: on(s) ? c.accent : c.ink3,
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: buttonSize,
          shape: shape,
          textStyle: InType.button,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: buttonSize,
          shape: shape,
          textStyle: InType.button,
          foregroundColor: c.ink,
          side: BorderSide(color: c.line),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: buttonSize,
          textStyle: InType.button,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: c.surface2,
        border: fieldBorder,
        enabledBorder: fieldBorder,
        focusedBorder: fieldBorder.copyWith(
          borderSide: BorderSide(color: c.accent, width: 1.5),
        ),
        labelStyle: TextStyle(color: c.ink2),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: InSpace.s6,
          vertical: 14,
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: c.accent,
        foregroundColor: c.onAccent,
        extendedTextStyle: InType.button.copyWith(fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(InRadius.fab),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: c.ink,
        contentTextStyle: InType.meta.copyWith(color: c.surface, fontSize: 14),
        actionTextColor: c.accentTint,
        behavior: SnackBarBehavior.floating,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: c.surface,
        showDragHandle: true,
      ),
      listTileTheme: ListTileThemeData(
        minVerticalPadding: 10,
        subtitleTextStyle: InType.caption.copyWith(color: c.ink3),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: c.accent,
        linearTrackColor: c.surface2,
      ),
    );
  }
}
