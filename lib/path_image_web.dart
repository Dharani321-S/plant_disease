import 'package:flutter/material.dart';

Widget buildPathImage(
  String path, {
  double? width,
  double? height,
  BoxFit fit = BoxFit.cover,
  Widget? fallback,
}) {
  if (path.isEmpty) {
    return fallback ?? _defaultFallback(width: width, height: height);
  }

  return Image.network(
    path,
    width: width,
    height: height,
    fit: fit,
    errorBuilder: (_, __, ___) => fallback ?? _defaultFallback(width: width, height: height),
  );
}

Widget _defaultFallback({double? width, double? height}) {
  return Container(
    width: width,
    height: height,
    color: Colors.white10,
    child: const Icon(Icons.image_not_supported, color: Colors.white38),
  );
}
