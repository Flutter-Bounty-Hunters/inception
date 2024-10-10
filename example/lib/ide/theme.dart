import 'package:flutter/material.dart';
import 'package:super_editor/super_editor.dart';

const panelHighColor = Color(0xFF292D30);
const panelLowColor = Color(0xFF1C2022);
const dividerColor = Color(0xFF1C2022);

const popoverBackgroundColor = Color(0xFF202224);
const popoverBorderColor = Color(0xFF34353A);

// Makes text light, for use during dark mode styling.
final darkModeStyles = [
  StyleRule(
    BlockSelector.all,
    (doc, docNode) {
      return {
        Styles.textStyle: const TextStyle(
          fontSize: 18,
          fontFamily: 'Courier New',
          color: Colors.white,
        ),
      };
    },
  ),
];
