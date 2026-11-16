import 'package:flutter/material.dart';

/// Convenience animated route used across the app (WhatsApp-like slide).
class AppRoute {
  static Route<T> page<T>(Widget page) =>
      RouteAnimations.slideRightToLeft<T>(page);

  static Route<T> fade<T>(Widget page) => RouteAnimations.fadeThrough<T>(page);
}

/// WhatsApp-like smooth page route animations
class RouteAnimations {
  /// Slide from right to left (forward navigation)
  static Route<T> slideRightToLeft<T>(Widget page) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        const curve = Curves.easeInOutCubic;
        var tween = Tween(begin: begin, end: end)
            .chain(CurveTween(curve: curve));
        var offsetAnimation = animation.drive(tween);
        return SlideTransition(position: offsetAnimation, child: child);
      },
      transitionDuration: const Duration(milliseconds: 300),
    );
  }

  /// Slide from left to right (back navigation feel)
  static Route<T> slideLeftToRight<T>(Widget page) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(-1.0, 0.0);
        const end = Offset.zero;
        const curve = Curves.easeInOutCubic;
        var tween = Tween(begin: begin, end: end)
            .chain(CurveTween(curve: curve));
        var offsetAnimation = animation.drive(tween);
        return SlideTransition(position: offsetAnimation, child: child);
      },
      transitionDuration: const Duration(milliseconds: 300),
    );
  }

  /// Fade through (WhatsApp-like)
  static Route<T> fadeThrough<T>(Widget page) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(opacity: animation, child: child);
      },
      transitionDuration: const Duration(milliseconds: 250),
    );
  }

  /// Scale up from center
  static Route<T> scaleUp<T>(Widget page) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        var tween = Tween(begin: 0.0, end: 1.0).chain(
          CurveTween(curve: Curves.easeOutBack),
        );
        return ScaleTransition(scale: animation.drive(tween), child: child);
      },
      transitionDuration: const Duration(milliseconds: 300),
    );
  }
}

/// Extension for easy navigation with animations
extension NavExtension on BuildContext {
  Future<T?> push<T>(Widget page, {String animation = 'slide'}) {
    switch (animation) {
      case 'slide':
        return Navigator.of(this).push(RouteAnimations.slideRightToLeft(page));
      case 'fade':
        return Navigator.of(this).push(RouteAnimations.fadeThrough(page));
      case 'scale':
        return Navigator.of(this).push(RouteAnimations.scaleUp(page));
      default:
        return Navigator.of(this).push(MaterialPageRoute(builder: (_) => page));
    }
  }

  Future<T?> pushReplacement<T>(Widget page) {
    return Navigator.of(this).pushReplacement(
      RouteAnimations.slideRightToLeft(page),
    );
  }

  void pop<T>([T? result]) {
    Navigator.of(this).pop(result);
  }
}
