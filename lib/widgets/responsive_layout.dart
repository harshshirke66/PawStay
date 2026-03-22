import 'package:flutter/material.dart';

class ResponsiveLayout extends StatelessWidget {
  final Widget child;

  const ResponsiveLayout({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    // We get the width of the screen

    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Container(
          // On ultra-wide screens, we still want a bit of a margin so lines of text
          // aren't 2000px long, but for a laptop/tablet it will be full screen.
          constraints: const BoxConstraints(maxWidth: 1200),
          child: child,
        ),
      ),
    );
  }
}
