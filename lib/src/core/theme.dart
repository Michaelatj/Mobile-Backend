import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

ThemeData buildLightTheme() {
  const primary = Color(0xFF1E88E5);
  const neutralBg = Color(0xFFFFFFFF);
  const neutralFg = Color(0xFF0F172A);

  final scheme =
      ColorScheme.fromSeed(seedColor: primary, brightness: Brightness.light)
          .copyWith(
    primary: primary,
    onPrimary: Colors.white,
    primaryContainer: const Color(0xFFE6F4FF),
    onPrimaryContainer: const Color(0xFF00223A),
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    shadowColor: scheme.primary.withOpacity(0.25),
    scaffoldBackgroundColor: neutralBg,
    textTheme: GoogleFonts.interTextTheme().apply(
      bodyColor: neutralFg,
      displayColor: neutralFg,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: scheme.surface,
      foregroundColor: scheme.onSurface,
      elevation: 1,
      centerTitle: true,
      surfaceTintColor: scheme.surfaceTint,
      titleTextStyle: GoogleFonts.inter(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: scheme.onSurface,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      isDense: true,
      filled: true,
      fillColor: scheme.surfaceContainerHighest,
      hintStyle: TextStyle(color: scheme.onSurface.withOpacity(0.6)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      labelStyle: TextStyle(color: scheme.onSurfaceVariant),
      floatingLabelStyle:
          TextStyle(color: scheme.primary, fontWeight: FontWeight.w600),
      prefixIconColor: scheme.onSurfaceVariant,
      suffixIconColor: scheme.onSurfaceVariant,
      errorStyle:
          GoogleFonts.inter(color: scheme.error, fontWeight: FontWeight.w500),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: scheme.outlineVariant),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: scheme.outlineVariant),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: scheme.outlineVariant.withOpacity(0.6)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: scheme.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: scheme.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: scheme.error, width: 1.5),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) {
            return scheme.onSurface.withOpacity(0.12);
          }
          return scheme.primary;
        }),
        foregroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) {
            return scheme.onSurface.withOpacity(0.38);
          }
          return scheme.onPrimary;
        }),
        overlayColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.pressed)) {
            return scheme.onPrimary.withOpacity(0.16);
          }
          if (states.contains(WidgetState.hovered)) {
            return scheme.onPrimary.withOpacity(0.08);
          }
          return null;
        }),
        elevation: const WidgetStatePropertyAll(2),
        shadowColor: WidgetStatePropertyAll(scheme.primary.withOpacity(0.25)),
        padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(horizontal: 16, vertical: 12)),
        shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
        textStyle: WidgetStatePropertyAll(
            GoogleFonts.inter(fontWeight: FontWeight.w600)),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) {
            return scheme.onSurface.withOpacity(0.12);
          }
          return scheme.primary;
        }),
        foregroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) {
            return scheme.onSurface.withOpacity(0.38);
          }
          return scheme.onPrimary;
        }),
        overlayColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.pressed)) {
            return scheme.onPrimary.withOpacity(0.16);
          }
          if (states.contains(WidgetState.hovered)) {
            return scheme.onPrimary.withOpacity(0.08);
          }
          return null;
        }),
        elevation: const WidgetStatePropertyAll(2),
        shadowColor: WidgetStatePropertyAll(scheme.primary.withOpacity(0.25)),
        padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(horizontal: 16, vertical: 12)),
        shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
        textStyle: WidgetStatePropertyAll(
            GoogleFonts.inter(fontWeight: FontWeight.w600)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: ButtonStyle(
        foregroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) {
            return scheme.onSurface.withOpacity(0.38);
          }
          return scheme.primary;
        }),
        side: WidgetStateProperty.resolveWith((states) {
          final color = states.contains(WidgetState.disabled)
              ? scheme.outline.withOpacity(0.6)
              : scheme.outline;
          return BorderSide(color: color);
        }),
        overlayColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.pressed)) {
            return scheme.primary.withOpacity(0.10);
          }
          if (states.contains(WidgetState.hovered)) {
            return scheme.primary.withOpacity(0.06);
          }
          return null;
        }),
        padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(horizontal: 16, vertical: 12)),
        shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
        textStyle: WidgetStatePropertyAll(
            GoogleFonts.inter(fontWeight: FontWeight.w600)),
      ),
    ),
    cardTheme: CardThemeData(
      clipBehavior: Clip.antiAlias,
      elevation: 4,
      shadowColor: scheme.primary.withOpacity(0.15),
      surfaceTintColor: Colors.transparent,
      color: scheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.symmetric(vertical: 6),
    ),
    listTileTheme: ListTileThemeData(
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      iconColor: scheme.onSurfaceVariant,
      titleTextStyle: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: scheme.onSurface,
      ),
      subtitleTextStyle: GoogleFonts.inter(
        fontSize: 13,
        color: scheme.onSurfaceVariant,
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: scheme.surface,
      indicatorColor: scheme.primaryContainer,
      elevation: 4,
      labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
      iconTheme: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return IconThemeData(
            color:
                selected ? scheme.onPrimaryContainer : scheme.onSurfaceVariant);
      }),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return GoogleFonts.inter(
          fontSize: 12,
          fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
          color: selected ? scheme.onPrimaryContainer : scheme.onSurfaceVariant,
        );
      }),
    ),
    dividerTheme: DividerThemeData(
      color: scheme.outlineVariant,
      thickness: 1,
      space: 1,
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: scheme.inverseSurface,
      contentTextStyle: GoogleFonts.inter(color: scheme.onInverseSurface),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ),
    iconTheme: IconThemeData(color: scheme.onSurfaceVariant),
    iconButtonTheme: IconButtonThemeData(
      style: ButtonStyle(
        foregroundColor: WidgetStateProperty.resolveWith((s) {
          if (s.contains(WidgetState.disabled))
            return scheme.onSurface.withOpacity(0.38);
          return scheme.onSurface;
        }),
        overlayColor: WidgetStateProperty.resolveWith((s) {
          if (s.contains(WidgetState.pressed))
            return scheme.onSurface.withOpacity(0.12);
          if (s.contains(WidgetState.hovered))
            return scheme.onSurface.withOpacity(0.08);
          return null;
        }),
        shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: scheme.primary,
      foregroundColor: scheme.onPrimary,
      elevation: 3,
      focusElevation: 4,
      hoverElevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    chipTheme: ChipThemeData(
      side: BorderSide(color: scheme.outlineVariant),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      labelStyle: GoogleFonts.inter(color: scheme.onSurface),
      backgroundColor: scheme.surfaceContainerHighest,
      selectedColor: scheme.primaryContainer,
      disabledColor: scheme.surfaceContainerHighest.withOpacity(0.5),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((s) {
        if (s.contains(WidgetState.disabled))
          return scheme.onSurface.withOpacity(0.38);
        return s.contains(WidgetState.selected)
            ? scheme.onPrimary
            : scheme.onSurfaceVariant;
      }),
      trackColor: WidgetStateProperty.resolveWith((s) {
        if (s.contains(WidgetState.disabled))
          return scheme.onSurface.withOpacity(0.12);
        return s.contains(WidgetState.selected)
            ? scheme.primary
            : scheme.surfaceContainerHighest;
      }),
    ),
    checkboxTheme: CheckboxThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      fillColor: WidgetStateProperty.resolveWith((s) {
        if (s.contains(WidgetState.disabled))
          return scheme.onSurface.withOpacity(0.12);
        return s.contains(WidgetState.selected)
            ? scheme.primary
            : scheme.surfaceContainerHighest;
      }),
      checkColor: WidgetStateProperty.all(scheme.onPrimary),
      side: BorderSide(color: scheme.outlineVariant),
    ),
    radioTheme: RadioThemeData(
      fillColor: WidgetStateProperty.resolveWith((s) {
        if (s.contains(WidgetState.disabled))
          return scheme.onSurface.withOpacity(0.12);
        return s.contains(WidgetState.selected)
            ? scheme.primary
            : scheme.onSurfaceVariant;
      }),
    ),
    tabBarTheme: TabBarThemeData(
      labelStyle: GoogleFonts.inter(fontWeight: FontWeight.w600),
      unselectedLabelStyle: GoogleFonts.inter(),
      labelColor: scheme.onSurface,
      unselectedLabelColor: scheme.onSurfaceVariant,
      indicatorColor: scheme.primary,
      dividerColor: scheme.outlineVariant,
      indicatorSize: TabBarIndicatorSize.label,
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: scheme.primary,
      linearTrackColor: scheme.outlineVariant,
      circularTrackColor: scheme.outlineVariant,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: scheme.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      titleTextStyle: GoogleFonts.inter(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: scheme.onSurface,
      ),
      contentTextStyle: GoogleFonts.inter(color: scheme.onSurfaceVariant),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: scheme.surface,
      surfaceTintColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      elevation: 8,
      showDragHandle: true,
      dragHandleColor: scheme.onSurfaceVariant,
    ),
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(
        color: scheme.inverseSurface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: scheme.outlineVariant),
      ),
      textStyle: GoogleFonts.inter(color: scheme.onInverseSurface),
    ),
  );
}

ThemeData buildDarkTheme() {
  const primary = Color(0xFF1E88E5); // bright blue-cyan
  const bg = Color(0xFF0B1220); // slate-950
  const fg = Color(0xFFF8FAFC); // slate-50

  final scheme =
      ColorScheme.fromSeed(seedColor: primary, brightness: Brightness.dark);

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    shadowColor: Colors.black.withOpacity(0.6),
    scaffoldBackgroundColor: bg,
    textTheme: GoogleFonts.interTextTheme().apply(
      bodyColor: fg,
      displayColor: fg,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: scheme.surface,
      foregroundColor: scheme.onSurface,
      elevation: 0,
      centerTitle: true,
      surfaceTintColor: scheme.surfaceTint,
      titleTextStyle: GoogleFonts.inter(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: scheme.onSurface,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      isDense: true,
      filled: true,
      fillColor: scheme.surfaceContainerHighest,
      hintStyle: TextStyle(color: scheme.onSurface.withOpacity(0.7)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      labelStyle: TextStyle(color: scheme.onSurfaceVariant),
      floatingLabelStyle:
          TextStyle(color: scheme.primary, fontWeight: FontWeight.w600),
      prefixIconColor: scheme.onSurfaceVariant,
      suffixIconColor: scheme.onSurfaceVariant,
      errorStyle:
          GoogleFonts.inter(color: scheme.error, fontWeight: FontWeight.w500),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: scheme.outlineVariant),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: scheme.outlineVariant),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: scheme.outlineVariant.withOpacity(0.6)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: scheme.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: scheme.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: scheme.error, width: 1.5),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) {
            return scheme.onSurface.withOpacity(0.12);
          }
          return scheme.primary;
        }),
        foregroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) {
            return scheme.onSurface.withOpacity(0.38);
          }
          return scheme.onPrimary;
        }),
        overlayColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.pressed)) {
            return Colors.white.withOpacity(0.10);
          }
          if (states.contains(WidgetState.hovered)) {
            return Colors.white.withOpacity(0.06);
          }
          return null;
        }),
        elevation: const WidgetStatePropertyAll(2),
        shadowColor: const WidgetStatePropertyAll(Colors.black54),
        padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(horizontal: 16, vertical: 12)),
        shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
        textStyle: WidgetStatePropertyAll(
            GoogleFonts.inter(fontWeight: FontWeight.w600)),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) {
            return scheme.onSurface.withOpacity(0.12);
          }
          return scheme.primary;
        }),
        foregroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) {
            return scheme.onSurface.withOpacity(0.38);
          }
          return scheme.onPrimary;
        }),
        overlayColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.pressed)) {
            return Colors.white.withOpacity(0.10);
          }
          if (states.contains(WidgetState.hovered)) {
            return Colors.white.withOpacity(0.06);
          }
          return null;
        }),
        elevation: const WidgetStatePropertyAll(2),
        shadowColor: const WidgetStatePropertyAll(Colors.black54),
        padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(horizontal: 16, vertical: 12)),
        shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
        textStyle: WidgetStatePropertyAll(
            GoogleFonts.inter(fontWeight: FontWeight.w600)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: ButtonStyle(
        foregroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) {
            return scheme.onSurface.withOpacity(0.38);
          }
          return scheme.primary;
        }),
        side: WidgetStateProperty.resolveWith((states) {
          final color = states.contains(WidgetState.disabled)
              ? scheme.outline.withOpacity(0.6)
              : scheme.outline;
          return BorderSide(color: color);
        }),
        overlayColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.pressed)) {
            return scheme.primary.withOpacity(0.10);
          }
          if (states.contains(WidgetState.hovered)) {
            return scheme.primary.withOpacity(0.06);
          }
          return null;
        }),
        padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(horizontal: 16, vertical: 12)),
        shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
        textStyle: WidgetStatePropertyAll(
            GoogleFonts.inter(fontWeight: FontWeight.w600)),
      ),
    ),
    cardTheme: CardThemeData(
      clipBehavior: Clip.antiAlias,
      elevation: 3,
      shadowColor: scheme.primary.withOpacity(0.15),
      surfaceTintColor: Colors.transparent,
      color: scheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.symmetric(vertical: 6),
    ),
    listTileTheme: ListTileThemeData(
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      iconColor: scheme.onSurfaceVariant,
      titleTextStyle: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: scheme.onSurface,
      ),
      subtitleTextStyle: GoogleFonts.inter(
        fontSize: 13,
        color: scheme.onSurfaceVariant,
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: scheme.surface,
      indicatorColor: scheme.primaryContainer,
      elevation: 4,
      labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
      iconTheme: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return IconThemeData(
            color:
                selected ? scheme.onPrimaryContainer : scheme.onSurfaceVariant);
      }),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return GoogleFonts.inter(
          fontSize: 12,
          fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
          color: selected ? scheme.onPrimaryContainer : scheme.onSurfaceVariant,
        );
      }),
    ),
    dividerTheme: DividerThemeData(
      color: scheme.outlineVariant,
      thickness: 1,
      space: 1,
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: scheme.inverseSurface,
      contentTextStyle: GoogleFonts.inter(color: scheme.onInverseSurface),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ),
    iconTheme: IconThemeData(color: scheme.onSurfaceVariant),
    iconButtonTheme: IconButtonThemeData(
      style: ButtonStyle(
        foregroundColor: WidgetStateProperty.resolveWith((s) {
          if (s.contains(WidgetState.disabled))
            return scheme.onSurface.withOpacity(0.38);
          return scheme.onSurface;
        }),
        overlayColor: WidgetStateProperty.resolveWith((s) {
          if (s.contains(WidgetState.pressed))
            return Colors.white.withOpacity(0.08);
          if (s.contains(WidgetState.hovered))
            return Colors.white.withOpacity(0.06);
          return null;
        }),
        shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: scheme.primary,
      foregroundColor: scheme.onPrimary,
      elevation: 3,
      focusElevation: 4,
      hoverElevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    chipTheme: ChipThemeData(
      side: BorderSide(color: scheme.outlineVariant),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      labelStyle: GoogleFonts.inter(color: scheme.onSurface),
      backgroundColor: scheme.surfaceContainerHighest,
      selectedColor: scheme.primaryContainer,
      disabledColor: scheme.surfaceContainerHighest.withOpacity(0.5),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((s) {
        if (s.contains(WidgetState.disabled))
          return scheme.onSurface.withOpacity(0.38);
        return s.contains(WidgetState.selected)
            ? scheme.onPrimary
            : scheme.onSurfaceVariant;
      }),
      trackColor: WidgetStateProperty.resolveWith((s) {
        if (s.contains(WidgetState.disabled))
          return scheme.onSurface.withOpacity(0.12);
        return s.contains(WidgetState.selected)
            ? scheme.primary
            : scheme.surfaceContainerHighest;
      }),
    ),
    checkboxTheme: CheckboxThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      fillColor: WidgetStateProperty.resolveWith((s) {
        if (s.contains(WidgetState.disabled))
          return scheme.onSurface.withOpacity(0.12);
        return s.contains(WidgetState.selected)
            ? scheme.primary
            : scheme.surfaceContainerHighest;
      }),
      checkColor: WidgetStateProperty.all(scheme.onPrimary),
      side: BorderSide(color: scheme.outlineVariant),
    ),
    radioTheme: RadioThemeData(
      fillColor: WidgetStateProperty.resolveWith((s) {
        if (s.contains(WidgetState.disabled))
          return scheme.onSurface.withOpacity(0.12);
        return s.contains(WidgetState.selected)
            ? scheme.primary
            : scheme.onSurfaceVariant;
      }),
    ),
    tabBarTheme: TabBarThemeData(
      labelStyle: GoogleFonts.inter(fontWeight: FontWeight.w600),
      unselectedLabelStyle: GoogleFonts.inter(),
      labelColor: scheme.onSurface,
      unselectedLabelColor: scheme.onSurfaceVariant,
      indicatorColor: scheme.primary,
      dividerColor: scheme.outlineVariant,
      indicatorSize: TabBarIndicatorSize.label,
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: scheme.primary,
      linearTrackColor: scheme.outlineVariant,
      circularTrackColor: scheme.outlineVariant,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: scheme.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      titleTextStyle: GoogleFonts.inter(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: scheme.onSurface,
      ),
      contentTextStyle: GoogleFonts.inter(color: scheme.onSurfaceVariant),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: scheme.surface,
      surfaceTintColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      elevation: 8,
      showDragHandle: true,
      dragHandleColor: scheme.onSurfaceVariant,
    ),
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(
        color: scheme.inverseSurface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: scheme.outlineVariant),
      ),
      textStyle: GoogleFonts.inter(color: scheme.onInverseSurface),
    ),
  );
}
