import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_windowmanager/flutter_windowmanager.dart';
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
        // Android: Use flutter_windowmanager
        await FlutterWindowManager.addFlags(FlutterWindowManager.FLAG_SECURE);
      } else if (Platform.isIOS) {
        // iOS: Use screen_protector
        await ScreenProtector.protectDataLeakageOn();
      }
      _isSecured = true;
    } catch (e) {
      debugPrint('Failed to enable security: $e');
    }
  }

  /// Disable security (allow screenshots)
  Future<void> disableSecurity() async {
    if (!_isSecured) return;

    try {
      if (Platform.isAndroid) {
        await FlutterWindowManager.clearFlags(FlutterWindowManager.FLAG_SECURE);
      } else if (Platform.isIOS) {
        await ScreenProtector.protectDataLeakageOff();
      }
      _isSecured = false;
    } catch (e) {
      debugPrint('Failed to disable security: $e');
    }
  }

  /// Prevent screenshots for a specific screen
  /// Call this in initState of secure screens
  Future<void> protectScreen() async {
    await enableSecurity();
  }

  /// Allow screenshots again
  /// Call this in dispose of secure screens
  Future<void> unprotectScreen() async {
    await disableSecurity();
  }

  /// Check if security is currently enabled
  bool get isSecured => _isSecured;
}
