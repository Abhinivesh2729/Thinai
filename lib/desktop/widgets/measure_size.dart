import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// Reports its child's size after layout whenever it changes.
class MeasureSize extends SingleChildRenderObjectWidget {
  const MeasureSize({super.key, required this.onChange, super.child});
  final ValueChanged<Size> onChange;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      RenderMeasureSize(onChange);

  @override
  void updateRenderObject(
    BuildContext context,
    RenderMeasureSize renderObject,
  ) {
    renderObject.onChange = onChange;
  }
}

class RenderMeasureSize extends RenderProxyBox {
  RenderMeasureSize(this.onChange);
  ValueChanged<Size> onChange;
  Size? _last;

  @override
  void performLayout() {
    super.performLayout();
    final s = child?.size ?? Size.zero;
    if (s == _last) return;
    _last = s;
    WidgetsBinding.instance.addPostFrameCallback((_) => onChange(s));
  }
}
