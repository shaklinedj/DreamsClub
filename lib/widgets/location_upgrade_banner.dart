import 'package:flutter/material.dart';

/// Banner desactivado ya que no se utiliza GPS en esta versión
class LocationUpgradeBanner extends StatelessWidget {
  const LocationUpgradeBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}

