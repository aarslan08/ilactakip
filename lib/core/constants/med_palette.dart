import 'package:flutter/material.dart';

abstract class MedPalette {
  static const List<Color> colors = [
    Color(0xFF2E7D6B), // yeşil (varsayılan)
    Color(0xFF1976D2), // mavi
    Color(0xFF7B1FA2), // mor
    Color(0xFFF57C00), // turuncu
    Color(0xFFC62828), // kırmızı
    Color(0xFF00838F), // teal
    Color(0xFF558B2F), // açık yeşil
    Color(0xFF4527A0), // koyu mor
  ];

  static const List<IconData> icons = [
    Icons.medication_rounded,
    Icons.water_drop_rounded,
    Icons.grain_rounded,
    Icons.healing_rounded,
    Icons.medication_liquid_rounded,
    Icons.vaccines_rounded,
    Icons.spa_rounded,
    Icons.health_and_safety_rounded,
  ];

  static const int defaultColorIndex = 0;
  static const int defaultIconIndex = 0;
}
