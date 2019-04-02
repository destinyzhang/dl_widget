library dl_widget;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:vector_math/vector_math_64.dart';

//帮助取得ui大小和位置
class WidgetTool {
  static Size sizeRender(RenderBox box) => Size.copy(box.size);

  static Size sizeCtx(BuildContext ctx) => sizeRender(ctx.findRenderObject());

  static Offset posRender(RenderObject obj, OverlayState os) {
    Vector3 v3 =
        obj.getTransformTo(os?.context?.findRenderObject()).getTranslation();
    return Offset(v3.x, v3.y);
  }

  static Offset posCtx(BuildContext ctx) =>
      posRender(ctx.findRenderObject(), Overlay.of(ctx));
}
