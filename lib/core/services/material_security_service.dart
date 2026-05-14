import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:screen_protector/screen_protector.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Material Security Service
// Handles screenshot blocking and screen recording prevention
// ─────────────────────────────────────────────────────────────────────────────

class MaterialSecurityService {
  static final MaterialSecurityService _instance = MaterialSecurityService._internal();
  factory MaterialSecurityService() => _instance;
  MaterialSecurityService._internal();

  bool _isSecured = false;

  /// Enable security (screenshot blocking + screen recording prevention)
  Future<void> enableSecurity() async {
    if (_isSecured) return;

    try {
      if (Platform.isAndroid) {
        // Android: Multiple layers of protection
        await ScreenProtector.protectDataLeakageWithBlur();
        await ScreenProtector.protectDataLeakageOn();
        
        // Additional Android-specific protection
        try {
          await ScreenProtector.preventScreenshotOn();
        } catch (e) {
          debugPrint('Additional screenshot protection failed: $e');
        }
      } else if (Platform.isIOS) {
        // iOS: Prevent screenshots and screen recording
        await ScreenProtector.protectDataLeakageOn();
        await ScreenProtector.preventScreenshotOn();
      }
      _isSecured = true;
      debugPrint('✅ Material security enabled');
    } catch (e) {
      debugPrint('❌ Failed to enable security: $e');
    }
  }

  /// Disable security (allow screenshots)
  Future<void> disableSecurity() async {
    if (!_isSecured) return;

    try {
      if (Platform.isAndroid || Platform.isIOS) {
        await ScreenProtector.protectDataLeakageOff();
        await ScreenProtector.preventScreenshotOff();
      }
      _isSecured = false;
      debugPrint('✅ Material security disabled');
    } catch (e) {
      debugPrint('❌ Failed to disable security: $e');
    }
  }

  /// Protect screen - call in initState
  Future<void> protectScreen() async {
    await enableSecurity();
    
    // Force hide system UI for extra security
    if (Platform.isAndroid) {
      SystemChrome.setEnabledSystemUIMode(
        SystemUiMode.immersiveSticky,
        overlays: [],
      );
    }
  }

  /// Unprotect screen - call in dispose
  Future<void> unprotectScreen() async {
    await disableSecurity();
    
    // Restore system UI
    if (Platform.isAndroid) {
      SystemChrome.setEnabledSystemUIMode(
        SystemUiMode.edgeToEdge,
        overlays: SystemUiOverlay.values,
      );
    }
  }

  /// Check if security is currently enabled
  bool get isSecured => _isSecured;
}
