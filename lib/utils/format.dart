import 'package:flutter/material.dart';

/// App primary green (AppBar, buttons, accents).
const kPrimaryGreen = Color(0xFF1B5E20);

String _two(int n) => n.toString().padLeft(2, '0');

/// "14:05"
String fmtTime(DateTime dt) => '${_two(dt.hour)}:${_two(dt.minute)}';

/// "3/10/2026 14:05"
String fmtDateTime(DateTime dt) =>
    '${dt.day}/${dt.month}/${dt.year} ${fmtTime(dt)}';

/// "1j 05min"
String fmtDuration(Duration d) =>
    '${d.inHours}j ${_two(d.inMinutes.remainder(60))}min';
