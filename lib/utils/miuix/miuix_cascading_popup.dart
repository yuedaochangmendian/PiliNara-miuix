import 'dart:math' as math;

import 'package:PiliPlus/utils/miuix/miuix_motion.dart';
import 'package:PiliPlus/utils/miuix/miuix_shapes.dart';
import 'package:PiliPlus/utils/miuix/miuix_squircle.dart';
import 'package:material_ui/material_ui.dart';

/// miuix 的级联弹层：菜单从被点的那个列表项原地"长"出来。
///
/// miuix 的做法（`CascadingMorphContent` + `CascadingListPopupLayout`）：
///
/// * 展开时用 `popupClipReveal` 让弹出内容的**裁剪区从被点项的矩形放大到弹层矩形**，同时把内容
///   从 `ENTER_SCALE_FROM = 0.15` 缩放到 1（`ENTER_SCALE_RANGE = 0.85`）；
/// * 弹层圆角 16、用连续圆角；遮罩是 `windowDimming`；
/// * 宽度限制在 200–288dp，最多 8 项（超出后列表内滚动）。
///
/// Flutter 侧等价实现：一条透明路由 + [ClipPath]（裁剪区在两点间插值）+ 缩放，曲线与时长取
/// [MiuixMotion]。
abstract final class MiuixCascadingPopup {
  /// 展开时内容的起始缩放（`ENTER_SCALE_FROM`）。
  static const double enterScaleFrom = 0.15;

  /// 展开时缩放的变化量（`ENTER_SCALE_RANGE`）。
  static const double enterScaleRange = 0.85;

  /// 弹层最小宽度（`ListPopup` 里取 200dp）。
  static const double minWidth = 200;

  /// 弹层最大宽度（288dp）。
  static const double maxWidth = 288;

  /// 最多直接铺开的项数，超出后需要滚动。
  static const int maxItems = 8;

  /// 在 [anchor]（被点项在屏幕上的矩形）旁弹出 [items]，返回被选中项的值。
  static Future<T?> show<T>({
    required BuildContext context,
    required Rect anchor,
    required List<MiuixCascadingItem<T>> items,
    double? minWidth,
    double? maxWidth,
  }) {
    return showGeneralDialog<T>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'dismiss',
      barrierColor: Theme.of(context).colorScheme.scrim,
      transitionDuration: MiuixMotion.enter,
      pageBuilder: (context, animation, secondaryAnimation) {
        return _MiuixCascadingPopupBody<T>(
          anchor: anchor,
          items: items,
          animation: animation,
          minWidth: minWidth ?? MiuixCascadingPopup.minWidth,
          maxWidth: maxWidth ?? MiuixCascadingPopup.maxWidth,
        );
      },
    );
  }
}

/// 级联弹层里的一项。
class MiuixCascadingItem<T> {
  const MiuixCascadingItem({
    required this.value,
    required this.child,
    this.icon,
    this.destructive = false,
  });

  final T value;
  final Widget child;
  final Widget? icon;

  /// 危险操作（用 error 色）。
  final bool destructive;
}

class _MiuixCascadingPopupBody<T> extends StatelessWidget {
  const _MiuixCascadingPopupBody({
    required this.anchor,
    required this.items,
    required this.animation,
    required this.minWidth,
    required this.maxWidth,
  });

  final Rect anchor;
  final List<MiuixCascadingItem<T>> items;
  final Animation<double> animation;
  final double minWidth;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final size = MediaQuery.sizeOf(context);
    const margin = MiuixShapes.bottomSheetInsideMargin / 2;
    final width = maxWidth.clamp(minWidth, size.width - margin * 2);
    final height = math.min(
      items.length * 48.0 + 8,
      MiuixCascadingPopup.maxItems * 48.0 + 8,
    );
    // 锚点矩形附近放置：优先在锚点下沿展开，空间不够就往上翻；左右贴边夹住。
    final left = (anchor.left + width > size.width - margin)
        ? size.width - margin - width
        : anchor.left.clamp(margin, size.width - margin - width);
    final belowTop = anchor.bottom + 4;
    final top = (belowTop + height > size.height - margin)
        ? (anchor.top - height - 4).clamp(margin, size.height - margin - height)
        : belowTop;
    final target = Rect.fromLTWH(left, top, width, height);

    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        final t = MiuixMotion.programmatic.transform(animation.value);
        final scale =
            MiuixCascadingPopup.enterScaleFrom +
            MiuixCascadingPopup.enterScaleRange * t;
        // 裁剪区从被点项的矩形插值到弹层矩形（miuix 的 popupClipReveal）。
        final revealed = Rect.lerp(anchor, target, t)!;
        return Stack(
          children: [
            Positioned(
              left: target.left,
              top: target.top,
              width: target.width,
              height: target.height,
              child: ClipPath(
                clipper: _MiuixRevealClipper(
                  revealed: revealed.shift(-target.topLeft),
                  radius: MiuixShapes.menuCornerRadius,
                ),
                child: Opacity(
                  opacity: 1,
                  child: Transform.scale(
                    scale: scale,
                    alignment: Alignment.topLeft,
                    child: Material(
                      color: scheme.surfaceContainer,
                      clipBehavior: Clip.antiAlias,
                      shape: const MiuixSquircleBorder(
                        cornerRadius: MiuixShapes.menuCornerRadius,
                      ),
                      child: ListView(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        children: [
                          for (final item in items)
                            ListTile(
                              dense: true,
                              leading: item.icon,
                              title: item.child,
                              textColor: item.destructive
                                  ? scheme.error
                                  : scheme.onSurface,
                              iconColor: item.destructive
                                  ? scheme.error
                                  : scheme.onSurface,
                              onTap: () => Navigator.of(context).pop(item.value),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// 把裁剪区限制在"已经展开的那块矩形"里。
class _MiuixRevealClipper extends CustomClipper<Path> {
  const _MiuixRevealClipper({required this.revealed, required this.radius});

  final Rect revealed;
  final double radius;

  @override
  Path getClip(Size size) => Path()
    ..addRRect(
      RRect.fromRectAndRadius(revealed, Radius.circular(radius)),
    );

  @override
  bool shouldReclip(_MiuixRevealClipper oldClipper) =>
      oldClipper.revealed != revealed;
}

