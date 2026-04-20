import 'package:flutter/widgets.dart';

import 'path_image_stub.dart'
    if (dart.library.io) 'path_image_io.dart'
    if (dart.library.html) 'path_image_web.dart' as impl;

Widget buildPathImage(
  String path, {
  double? width,
  double? height,
  BoxFit fit = BoxFit.cover,
  Widget? fallback,
}) {
  return impl.buildPathImage(
    path,
    width: width,
    height: height,
    fit: fit,
    fallback: fallback,
  );
}
