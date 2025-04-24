import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/gestures.dart';

class PerformanceUtils {
  static Future<void> optimizeForPerformance() async {
    if (kDebugMode) {
      // Optimize image cache
      PaintingBinding.instance.imageCache.maximumSize = 100;
      PaintingBinding.instance.imageCache.maximumSizeBytes = 50 << 20; // 50 MB
      
      // Enable performance debugging in debug mode
      debugPrintRebuildDirtyWidgets = true;
      
      // Disable Impeller for emulator to avoid OpenGL ES issues
      if (defaultTargetPlatform == TargetPlatform.android) {
        const MethodChannel('flutter/platform')
            .invokeMethod('SystemChrome.setSystemUIOverlayStyle', {
          'systemNavigationBarColor': '#000000',
          'systemNavigationBarDividerColor': '#000000',
          'statusBarColor': '#000000',
          'systemNavigationBarIconBrightness': 1, // dark
          'statusBarIconBrightness': 1, // dark
          'statusBarBrightness': 0, // light
        });
      }
    }

    // Lock orientation to portrait
    await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

    // Optimize UI overlay
    await SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.edgeToEdge,
      overlays: [SystemUiOverlay.top, SystemUiOverlay.bottom],
    );
  }

  static Widget wrapWithRepaintBoundary(Widget child) {
    return RepaintBoundary(
      child: _wrapWithScrollConfiguration(child),
    );
  }

  static Widget wrapWithPerformanceOverlay(Widget child) {
    if (!kDebugMode) return child;
    
    return Stack(
      children: [
        child,
        const Positioned(
          left: 0,
          top: 0,
          right: 0,
          height: 100,
          child: PerformanceOverlay(
            optionsMask: 0x01 | 0x02, // Show both UI and Raster threads
          ),
        ),
      ],
    );
  }

  static void setupErrorBoundary() {
    ErrorWidget.builder = (FlutterErrorDetails details) {
      return Material(
        child: Container(
          color: Colors.white,
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 48),
              const SizedBox(height: 16),
              Text(
                'Error: ${details.exception}',
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
              if (kDebugMode) ...[
                const SizedBox(height: 16),
                Text(
                  details.stack.toString(),
                  style: const TextStyle(fontSize: 12),
                  textAlign: TextAlign.left,
                ),
              ],
            ],
          ),
        ),
      );
    };
  }

  static Widget _wrapWithScrollConfiguration(Widget child) {
    return ScrollConfiguration(
      behavior: const ScrollBehavior().copyWith(
        physics: const BouncingScrollPhysics(),
        dragDevices: {
          PointerDeviceKind.touch,
          PointerDeviceKind.mouse,
        },
      ),
      child: child,
    );
  }
} 