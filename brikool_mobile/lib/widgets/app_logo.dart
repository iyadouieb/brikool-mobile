import 'package:flutter/material.dart';

class AppLogo extends StatelessWidget {
  final double radius;
  const AppLogo({Key? key, this.radius = 20}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: 'app-logo',
      child: CircleAvatar(
        radius: radius,
        backgroundColor: Theme.of(context).colorScheme.primary,
        child: Icon(Icons.handyman, size: radius * 0.9, color: Theme.of(context).colorScheme.onPrimary),
      ),
    );
  }
}
