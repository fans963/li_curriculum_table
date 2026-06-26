import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

// ─── M3 Expressive Motion Tokens ───────────────────────────────────────────
// Spring-based physics for bouncier, more expressive micro-interactions.
// Reference: m3.material.io/styles/motion/easing-and-duration/tokens-specs

/// Default animation duration — M3 Expressive medium2 (300ms).
const kDefaultAnimationDuration = Duration(milliseconds: 300);

/// Default animation curve — M3 Expressive Emphasized Decelerate.
/// cubic-bezier(0.05, 0.7, 0.1, 1.0) — for entering/changing elements.
const kDefaultAnimationCurve = Cubic(0.05, 0.7, 0.1, 1.0);

/// Quick interaction duration — M3 Expressive short2 (150ms).
const kInteractionDuration = Duration(milliseconds: 150);

/// Spring curve for selection/toggle animations — M3 Expressive spring feel.
/// Approximation of spring(duration: 500ms, bounce: 0.15) via cubic-bezier.
const kSpringCurve = Cubic(0.175, 0.885, 0.32, 1.175);

/// Emphasized easing for spatial transitions — M3 Expressive Emphasized.
/// cubic-bezier(0.2, 0, 0, 1.0) — for moving elements.
const kEmphasizedCurve = Cubic(0.2, 0, 0, 1.0);

// ─── Platform check ────────────────────────────────────────────────────────

bool get isDesktop {
  if (kIsWeb) return false;
  return defaultTargetPlatform == TargetPlatform.linux ||
      defaultTargetPlatform == TargetPlatform.macOS ||
      defaultTargetPlatform == TargetPlatform.windows;
}
