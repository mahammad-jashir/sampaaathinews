import 'package:flutter/material.dart';
import 'package:responsive_framework/responsive_framework.dart';

class ResponsiveLayout extends StatelessWidget {
  final Widget child;

  const ResponsiveLayout({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return ResponsiveBreakpoints.builder(
      child: Builder(
        builder: (context) {
          // Customize text scales or layouts depending on size
          return MaxWidthBox(
            maxWidth: 1400,
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            child: ResponsiveScaledBox(
              width: ResponsiveValue<double?>(
                context,
                conditionalValues: [
                  const Condition.equals(name: MOBILE, value: null),
                  const Condition.between(start: 451, end: 800, value: 800),
                  const Condition.between(start: 801, end: 1200, value: 1200),
                ],
              ).value,
              child: child,
            ),
          );
        },
      ),
      breakpoints: [
        const Breakpoint(start: 0, end: 450, name: MOBILE),
        const Breakpoint(start: 451, end: 800, name: TABLET),
        const Breakpoint(start: 801, end: 1200, name: DESKTOP),
        const Breakpoint(start: 1201, end: double.infinity, name: 'ULTRADEVICE'),
      ],
    );
  }
}
