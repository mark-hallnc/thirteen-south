import 'package:flutter/widgets.dart';

/// Shared device breakpoints, with independent sizes for each table element.
class GameLayoutSizes {
  GameLayoutSizes(BuildContext context)
    : shortestSide = MediaQuery.sizeOf(context).shortestSide,
      screenHeight = MediaQuery.sizeOf(context).height;

  final double shortestSide;
  final double screenHeight;
  bool get tablet => shortestSide >= 600;
  bool get largeTablet => shortestSide >= 900;
  double get humanCard => largeTablet
      ? 108
      : tablet
      ? 90
      : shortestSide < 360
      ? 66
      : 70;
  double get trickCard => largeTablet
      ? 132
      : tablet
      ? 112
      : 82;
  // Short landscape viewports need room for the readable human hand below.
  double get opponentScale => screenHeight < 700
      ? 1
      : largeTablet
      ? 1.4
      : tablet
      ? 1.25
      : 1;
  double get controlHeight => tablet ? 60 : 50;
}
