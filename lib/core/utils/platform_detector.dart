import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

/// Detecta la plataforma actual
class PlatformDetector {
  /// ¿Está ejecutándose en web?
  static bool get isWeb => kIsWeb;

  /// ¿Está ejecutándose en Windows?
  static bool get isWindows => !kIsWeb && Platform.isWindows;

  /// ¿Está ejecutándose en macOS?
  static bool get isMacOS => !kIsWeb && Platform.isMacOS;

  /// ¿Está ejecutándose en Linux?
  static bool get isLinux => !kIsWeb && Platform.isLinux;

  /// ¿Está ejecutándose en Android?
  static bool get isAndroid => !kIsWeb && Platform.isAndroid;

  /// ¿Está ejecutándose en iOS?
  static bool get isIOS => !kIsWeb && Platform.isIOS;

  /// ¿Es una plataforma nativa? (no web)
  static bool get isNative => !kIsWeb;

  /// ¿Es una plataforma móvil? (Android o iOS)
  static bool get isMobile => !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  /// ¿Es una plataforma de escritorio? (Windows, macOS, Linux)
  static bool get isDesktop => !kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux);
}
