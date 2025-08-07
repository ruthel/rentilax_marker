import 'package:flutter/material.dart';

class ModernPageTransitions {
  // Transition de glissement depuis la droite
  static Route<T> slideFromRight<T extends Object?>(Widget page) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: const Duration(milliseconds: 300),
      reverseTransitionDuration: const Duration(milliseconds: 250),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        const curve = Curves.easeInOutCubic;

        var tween = Tween(begin: begin, end: end).chain(
          CurveTween(curve: curve),
        );

        return SlideTransition(
          position: animation.drive(tween),
          child: child,
        );
      },
    );
  }

  // Transition de glissement depuis le bas
  static Route<T> slideFromBottom<T extends Object?>(Widget page) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: const Duration(milliseconds: 400),
      reverseTransitionDuration: const Duration(milliseconds: 300),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(0.0, 1.0);
        const end = Offset.zero;
        const curve = Curves.easeOutCubic;

        var tween = Tween(begin: begin, end: end).chain(
          CurveTween(curve: curve),
        );

        return SlideTransition(
          position: animation.drive(tween),
          child: child,
        );
      },
    );
  }

  // Transition de fondu avec échelle
  static Route<T> fadeWithScale<T extends Object?>(Widget page) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: const Duration(milliseconds: 350),
      reverseTransitionDuration: const Duration(milliseconds: 250),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const curve = Curves.easeInOutCubic;

        var fadeAnimation = animation.drive(
          CurveTween(curve: curve),
        );

        var scaleAnimation = animation.drive(
          Tween(begin: 0.95, end: 1.0).chain(
            CurveTween(curve: curve),
          ),
        );

        return FadeTransition(
          opacity: fadeAnimation,
          child: ScaleTransition(
            scale: scaleAnimation,
            child: child,
          ),
        );
      },
    );
  }

  // Transition de rotation avec fondu
  static Route<T> rotateWithFade<T extends Object?>(Widget page) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: const Duration(milliseconds: 500),
      reverseTransitionDuration: const Duration(milliseconds: 350),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const curve = Curves.easeInOutBack;

        var rotationAnimation = animation.drive(
          Tween(begin: 0.0, end: 1.0).chain(
            CurveTween(curve: curve),
          ),
        );

        var fadeAnimation = animation.drive(
          CurveTween(curve: Curves.easeInOut),
        );

        return FadeTransition(
          opacity: fadeAnimation,
          child: RotationTransition(
            turns: rotationAnimation,
            child: child,
          ),
        );
      },
    );
  }

  // Transition personnalisée avec effet de profondeur
  static Route<T> depthTransition<T extends Object?>(Widget page) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: const Duration(milliseconds: 400),
      reverseTransitionDuration: const Duration(milliseconds: 300),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const curve = Curves.easeInOutCubic;

        var slideAnimation = animation.drive(
          Tween(begin: const Offset(0.3, 0.0), end: Offset.zero).chain(
            CurveTween(curve: curve),
          ),
        );

        var scaleAnimation = animation.drive(
          Tween(begin: 0.8, end: 1.0).chain(
            CurveTween(curve: curve),
          ),
        );

        var fadeAnimation = animation.drive(
          CurveTween(curve: curve),
        );

        return SlideTransition(
          position: slideAnimation,
          child: ScaleTransition(
            scale: scaleAnimation,
            child: FadeTransition(
              opacity: fadeAnimation,
              child: child,
            ),
          ),
        );
      },
    );
  }

  // Transition avec effet de rebond
  static Route<T> bounceTransition<T extends Object?>(Widget page) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: const Duration(milliseconds: 600),
      reverseTransitionDuration: const Duration(milliseconds: 400),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        var scaleAnimation = animation.drive(
          Tween(begin: 0.0, end: 1.0).chain(
            CurveTween(curve: Curves.elasticOut),
          ),
        );

        var fadeAnimation = animation.drive(
          CurveTween(curve: Curves.easeInOut),
        );

        return FadeTransition(
          opacity: fadeAnimation,
          child: ScaleTransition(
            scale: scaleAnimation,
            child: child,
          ),
        );
      },
    );
  }
}

// Extension pour faciliter l'utilisation
extension NavigatorExtensions on NavigatorState {
  Future<T?> pushWithSlideFromRight<T extends Object?>(Widget page) {
    return push<T>(ModernPageTransitions.slideFromRight<T>(page));
  }

  Future<T?> pushWithSlideFromBottom<T extends Object?>(Widget page) {
    return push<T>(ModernPageTransitions.slideFromBottom<T>(page));
  }

  Future<T?> pushWithFadeScale<T extends Object?>(Widget page) {
    return push<T>(ModernPageTransitions.fadeWithScale<T>(page));
  }

  Future<T?> pushWithDepth<T extends Object?>(Widget page) {
    return push<T>(ModernPageTransitions.depthTransition<T>(page));
  }

  Future<T?> pushWithBounce<T extends Object?>(Widget page) {
    return push<T>(ModernPageTransitions.bounceTransition<T>(page));
  }
}

// Widget pour les transitions de Hero personnalisées
class ModernHeroTransition extends StatelessWidget {
  final String tag;
  final Widget child;
  final Duration duration;

  const ModernHeroTransition({
    super.key,
    required this.tag,
    required this.child,
    this.duration = const Duration(milliseconds: 300),
  });

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: tag,
      flightShuttleBuilder: (
        BuildContext flightContext,
        Animation<double> animation,
        HeroFlightDirection flightDirection,
        BuildContext fromHeroContext,
        BuildContext toHeroContext,
      ) {
        return AnimatedBuilder(
          animation: animation,
          builder: (context, child) {
            return Transform.scale(
              scale: 1.0 + (animation.value * 0.1),
              child: Opacity(
                opacity: 1.0 - (animation.value * 0.2),
                child: child,
              ),
            );
          },
          child: toHeroContext.widget,
        );
      },
      child: child,
    );
  }
}
