import 'package:flutter/material.dart';

/// Responsive wrapper widget to handle overflow and screen size adaptations
class ResponsiveWrapper extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final bool avoidBottomInset;
  final ScrollPhysics? scrollPhysics;

  const ResponsiveWrapper({
    super.key,
    required this.child,
    this.padding,
    this.avoidBottomInset = true,
    this.scrollPhysics,
  });

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final screenSize = mediaQuery.size;
    final isSmallScreen = screenSize.width < 400;
    final isTablet = screenSize.width > 600;
    final isLandscape = screenSize.width > screenSize.height;

    // Calculate responsive padding
    final responsivePadding = EdgeInsets.symmetric(
      horizontal: isSmallScreen ? 12 : (isTablet ? 24 : 16),
      vertical: isLandscape ? 8 : 16,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: scrollPhysics ?? const ClampingScrollPhysics(),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: constraints.maxHeight,
              maxWidth: constraints.maxWidth,
            ),
            child: IntrinsicHeight(
              child: Padding(
                padding: padding ?? responsivePadding,
                child: child,
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Responsive text widget that scales based on screen size
class ResponsiveText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  final double scaleFactor;

  const ResponsiveText(
    this.text, {
    super.key,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.scaleFactor = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;

    // Calculate responsive scale
    double scale = scaleFactor;
    if (screenWidth < 350) {
      scale *= 0.9; // Smaller screens
    } else if (screenWidth > 600) {
      scale *= 1.1; // Larger screens/tablets
    }

    return Text(
      text,
      style: style?.copyWith(fontSize: (style?.fontSize ?? 14) * scale),
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow ?? TextOverflow.ellipsis,
      textScaleFactor: 1.0, // Prevent system text scaling from breaking layout
    );
  }
}

/// Responsive spacing widget
class ResponsiveSpacing extends StatelessWidget {
  final double baseHeight;
  final double? baseWidth;
  final double scaleFactor;

  const ResponsiveSpacing({
    super.key,
    required this.baseHeight,
    this.baseWidth,
    this.scaleFactor = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final screenHeight = mediaQuery.size.height;
    final isLandscape = mediaQuery.size.width > mediaQuery.size.height;

    // Reduce spacing in landscape mode
    double heightScale = isLandscape ? 0.7 : 1.0;
    if (screenHeight < 600) heightScale *= 0.8; // Smaller screens

    final height = baseHeight * heightScale * scaleFactor;
    final width = baseWidth != null
        ? baseWidth! * heightScale * scaleFactor
        : null;

    return SizedBox(height: height, width: width);
  }
}

/// Responsive container with automatic padding and constraints
class ResponsiveContainer extends StatelessWidget {
  final Widget child;
  final double? maxWidth;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Decoration? decoration;

  const ResponsiveContainer({
    super.key,
    required this.child,
    this.maxWidth,
    this.padding,
    this.margin,
    this.decoration,
  });

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final isTablet = screenWidth > 600;

    // Calculate responsive constraints
    final containerMaxWidth = maxWidth ?? (isTablet ? 800 : double.infinity);

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: containerMaxWidth),
        child: Container(
          width: double.infinity,
          padding: padding,
          margin: margin,
          decoration: decoration,
          child: child,
        ),
      ),
    );
  }
}

/// Helper class for responsive breakpoints
class Breakpoints {
  static const double mobile = 480;
  static const double tablet = 768;
  static const double desktop = 1024;

  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < mobile;
  }

  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= mobile && width < desktop;
  }

  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= desktop;
  }

  static bool isLandscape(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return size.width > size.height;
  }
}

/// Extension for responsive sizing
extension ResponsiveSize on num {
  double get w => ResponsiveSizeHelper._instance.setWidth(toDouble());
  double get h => ResponsiveSizeHelper._instance.setHeight(toDouble());
  double get sp => ResponsiveSizeHelper._instance.setSp(toDouble());
}

class ResponsiveSizeHelper {
  static late ResponsiveSizeHelper _instance;
  static late double _screenWidth;
  static late double _screenHeight;

  static void init(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    _screenWidth = mediaQuery.size.width;
    _screenHeight = mediaQuery.size.height;
    _instance = ResponsiveSizeHelper._();
  }

  ResponsiveSizeHelper._();

  double setWidth(double width) {
    return width * _screenWidth / 375; // Base width 375 (iPhone design)
  }

  double setHeight(double height) {
    return height * _screenHeight / 812; // Base height 812 (iPhone design)
  }

  double setSp(double fontSize) {
    return fontSize * _screenWidth / 375;
  }
}
