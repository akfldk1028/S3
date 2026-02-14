import 'package:flutter/material.dart';

/// Placeholder PaletteScreen - will be implemented in phase-9
class PaletteScreen extends StatelessWidget {
  final String? presetId;

  const PaletteScreen({super.key, this.presetId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text('Palette Screen - To be implemented\nPreset ID: $presetId'),
      ),
    );
  }
}
