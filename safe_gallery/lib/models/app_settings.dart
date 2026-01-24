enum ThemeMode { system, light, dark }

class AppSettings {
  // Presentation settings
  final bool pinchToZoom;
  final bool showPhotoCounter;
  final bool autoAdvance;
  final int autoAdvanceInterval; // in seconds
  final bool autoLockEnabled;
  final int autoLockMinutes;

  // Display settings
  final ThemeMode themeMode;
  final bool transitionAnimations;

  AppSettings({
    this.pinchToZoom = false,
    this.showPhotoCounter = false,
    this.autoAdvance = false,
    this.autoAdvanceInterval = 5,
    this.autoLockEnabled = false,
    this.autoLockMinutes = 5,
    this.themeMode = ThemeMode.system,
    this.transitionAnimations = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'pinchToZoom': pinchToZoom,
      'showPhotoCounter': showPhotoCounter,
      'autoAdvance': autoAdvance,
      'autoAdvanceInterval': autoAdvanceInterval,
      'autoLockEnabled': autoLockEnabled,
      'autoLockMinutes': autoLockMinutes,
      'themeMode': themeMode.toString(),
      'transitionAnimations': transitionAnimations,
    };
  }

  factory AppSettings.fromMap(Map<String, dynamic> map) {
    return AppSettings(
      pinchToZoom: map['pinchToZoom'] as bool? ?? false,
      showPhotoCounter: map['showPhotoCounter'] as bool? ?? false,
      autoAdvance: map['autoAdvance'] as bool? ?? false,
      autoAdvanceInterval: map['autoAdvanceInterval'] as int? ?? 5,
      autoLockEnabled: map['autoLockEnabled'] as bool? ?? false,
      autoLockMinutes: map['autoLockMinutes'] as int? ?? 5,
      themeMode: _parseThemeMode(map['themeMode'] as String?),
      transitionAnimations: map['transitionAnimations'] as bool? ?? true,
    );
  }

  static ThemeMode _parseThemeMode(String? value) {
    switch (value) {
      case 'ThemeMode.light':
        return ThemeMode.light;
      case 'ThemeMode.dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  AppSettings copyWith({
    bool? pinchToZoom,
    bool? showPhotoCounter,
    bool? autoAdvance,
    int? autoAdvanceInterval,
    bool? autoLockEnabled,
    int? autoLockMinutes,
    ThemeMode? themeMode,
    bool? transitionAnimations,
  }) {
    return AppSettings(
      pinchToZoom: pinchToZoom ?? this.pinchToZoom,
      showPhotoCounter: showPhotoCounter ?? this.showPhotoCounter,
      autoAdvance: autoAdvance ?? this.autoAdvance,
      autoAdvanceInterval: autoAdvanceInterval ?? this.autoAdvanceInterval,
      autoLockEnabled: autoLockEnabled ?? this.autoLockEnabled,
      autoLockMinutes: autoLockMinutes ?? this.autoLockMinutes,
      themeMode: themeMode ?? this.themeMode,
      transitionAnimations: transitionAnimations ?? this.transitionAnimations,
    );
  }
}
