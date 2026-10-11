import 'dart:ui' as ui show ImageFilter;

import 'package:material_ui/material_ui.dart';

/// miuix 的背景模糊（`miuix-blur` 模块）。
///
/// `BlurDefaults`：默认半径 20dp、最大 150dp，模糊后还能叠配色与抗色带噪点。Flutter 的
/// [BackdropFilter] 只有固定 sigma，所以这里用 [MiuixBackdrop] 对应普通背景模糊、
/// [MiuixProgressiveBlur] 用「多段递增 sigma」近似渐变模糊；噪点没法做等价物（需要 shader 通道），
/// 对观感影响很小，省掉。
abstract final class MiuixBlur {
  /// BlurDefaults.BlurRadius
  static const double radius = 20;

  /// BlurDefaults.MaxBlurRadius
  static const double maxRadius = 150;

  /// 把 miuix 的半径换成 [ui.ImageFilter.blur] 的 sigma（1:1.7 经验比例，观感接近）。
  static double sigmaFor(double radiusInDp) =>
      radiusInDp.clamp(0, maxRadius) * 1.7;
}

/// 背景模糊 + 半透明底色（对应 miuix 的 `Backdrop`）。
///
/// 要放在 [Stack] 这类层叠结构里、盖在需要被模糊的内容之上。[tint] 传底色（通常取
/// `colorScheme.surfaceContainer` 再给一点透明度），[borderRadius] / [shape] 把模糊限制在形状内。
class MiuixBackdrop extends StatelessWidget {
  const MiuixBackdrop({
    super.key,
    required this.child,
    this.radius = MiuixBlur.radius,
    this.tint,
    this.clipBehavior = Clip.antiAlias,
    this.borderRadius,
  });

  final Widget child;

  /// 模糊半径（dp），默认 miuix 的 20。
  final double radius;

  /// 压在模糊之上的底色。
  final Color? tint;

  final Clip clipBehavior;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    final blurred = BackdropFilter(
      filter: ui.ImageFilter.blur(
        sigmaX: MiuixBlur.sigmaFor(radius),
        sigmaY: MiuixBlur.sigmaFor(radius),
      ),
      child: tint == null ? child : ColoredBox(color: tint!, child: child),
    );
    if (borderRadius == null) {
      return ClipRect(clipBehavior: clipBehavior, child: blurred);
    }
    return ClipRRect(
      borderRadius: borderRadius!,
      clipBehavior: clipBehavior,
      child: blurred,
    );
  }
}

/// 渐变模糊：从某一侧最强、向另一侧渐隐（近似 miuix 的 `ProgressiveBlur`）。
///
/// miuix 的模型是「两点线性渐变 + 曲线」；Flutter 只能整层同 sigma，所以这里把区域切成
/// [bands] 段，每段一个 `BackdropFilter`、sigma 按段位从 [maxRadius] 递减到 0，视觉上就是渐变
/// 模糊。段数越多过渡越顺，默认 6 段。
class MiuixProgressiveBlur extends StatelessWidget {
  const MiuixProgressiveBlur({
    super.key,
    required this.child,
    this.from = MiuixProgressiveBlurEdge.top,
    this.maxRadius = MiuixBlur.radius,
    this.bands = 6,
    this.tint,
  });

  final Widget child;

  /// 模糊最强的一侧。
  final MiuixProgressiveBlurEdge from;

  /// 最强那一侧的半径（dp）。
  final double maxRadius;

  /// 分段数。
  final int bands;

  /// 压在模糊之上的底色（可选）。
  final Color? tint;

  @override
  Widget build(BuildContext context) {
    final layers = <Widget>[];
    for (var i = 0; i < bands; i++) {
      final start = i / bands;
      final end = (i + 1) / bands;
      // 越靠近 from 那一侧 sigma 越大；最后一段不再模糊。
      final radius = maxRadius * (1 - start);
      if (radius <= 0) {
        continue;
      }
      final vertical = from == MiuixProgressiveBlurEdge.top ||
          from == MiuixProgressiveBlurEdge.bottom;
      final align = switch (from) {
        MiuixProgressiveBlurEdge.top || MiuixProgressiveBlurEdge.left =>
          start * 2 - 1,
        MiuixProgressiveBlurEdge.bottom || MiuixProgressiveBlurEdge.right =>
          1 - start * 2,
      };
      layers.add(
        Positioned.fill(
          child: Align(
            alignment: vertical
                ? Alignment(0, align)
                : Alignment(align, 0),
            heightFactor: vertical ? (end - start) : null,
            widthFactor: vertical ? null : (end - start),
            child: BackdropFilter(
              filter: ui.ImageFilter.blur(
                sigmaX: MiuixBlur.sigmaFor(radius),
                sigmaY: MiuixBlur.sigmaFor(radius),
              ),
              child: const SizedBox.expand(),
            ),
          ),
        ),
      );
    }
    return Stack(
      fit: StackFit.passthrough,
      children: [
        child,
        if (layers.isNotEmpty) ...layers,
        if (tint != null) Positioned.fill(child: ColoredBox(color: tint!)),
      ],
    );
  }
}

/// 渐变模糊从哪一侧开始（对应 miuix 的 `ProgressiveBlur.Top/Bottom/Left/Right`）。
enum MiuixProgressiveBlurEdge { top, bottom, left, right }
