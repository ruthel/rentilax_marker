import 'package:flutter/material.dart';

class AppSpacing {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;

  static const EdgeInsets page = EdgeInsets.all(md);
  static const EdgeInsets section =
      EdgeInsets.symmetric(horizontal: md, vertical: xs);
  static const EdgeInsets card = EdgeInsets.all(md);
  static const EdgeInsets grid = EdgeInsets.all(sm);
}
