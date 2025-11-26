import 'package:flutter/material.dart';

class ResponsiveGrid {
  static int getCrossAxisCount(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < 600) {
      return 2; // Mobile
    } else if (width < 900) {
      return 3; // Tablet
    } else {
      return 4; // Desktop
    }
  }

  static double getChildAspectRatio(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < 600) {
      return 1.4; // Mobile - slightly taller
    } else {
      return 1.5; // Tablet/Desktop
    }
  }

  static EdgeInsets getPadding(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < 600) {
      return const EdgeInsets.all(8);
    } else {
      return const EdgeInsets.all(16);
    }
  }

  static double getSpacing(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < 600) {
      return 8;
    } else {
      return 12;
    }
  }
}