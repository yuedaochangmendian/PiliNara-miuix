import 'dart:math' as math;

import 'package:PiliPlus/models/common/theme/theme_color_type.dart';
import 'package:PiliPlus/pages/common/publish/publish_route.dart';
import 'package:PiliPlus/utils/extension/theme_ext.dart';
import 'package:PiliPlus/utils/miuix/miuix_colors.dart';
import 'package:PiliPlus/utils/miuix/miuix_drag_handle.dart';
import 'package:PiliPlus/utils/miuix/miuix_indication.dart';
import 'package:PiliPlus/utils/miuix/miuix_motion.dart';
import 'package:PiliPlus/utils/miuix/miuix_navigation.dart';
import 'package:PiliPlus/utils/miuix/miuix_scroll_haptic.dart';
import 'package:PiliPlus/utils/miuix/miuix_shapes.dart';
import 'package:PiliPlus/utils/miuix/miuix_squircle.dart';
import 'package:PiliPlus/utils/miuix/miuix_text_styles.dart';
import 'package:PiliPlus/utils/miuix/miuix_theme.dart';
import 'package:flex_seed_scheme/flex_seed_scheme.dart';
import 'package:flutter/services.dart'
    show MethodCall, StandardMethodCodec, SystemChannels;
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get_navigation/src/routes/default_route.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  group('miuix 固定配色', () {
    test('取自 miuix lightColorScheme()', () {
      const light = MiuixColors.light;
      expect(light.brightness, Brightness.light);
      expect(light.primary, const Color(0xFF3482FF));
      expect(light.onPrimary, const Color(0xFFFFFFFF));
      expect(light.surface, const Color(0xFFF7F7F7));
      expect(light.background, const Color(0xFFFFFFFF));
      expect(light.surfaceContainer, const Color(0xFFFFFFFF));
      expect(light.surfaceContainerHighest, const Color(0xFFE8E8E8));
      expect(light.dividerLine, const Color(0xFFE0E0E0));
      expect(light.onSurfaceVariantSummary, const Color(0x99000000));
      expect(light.windowDimming, const Color(0x4D000000));
      expect(light.disabledPrimary, const Color(0xFFC2D9FF));
    });

    test('取自 miuix darkColorScheme()', () {
      const dark = MiuixColors.dark;
      expect(dark.brightness, Brightness.dark);
      expect(dark.primary, const Color(0xFF277AF7));
      expect(dark.surface, const Color(0xFF000000));
      expect(dark.background, const Color(0xFF242424));
      expect(dark.surfaceContainer, const Color(0xFF242424));
      expect(dark.surfaceContainerHighest, const Color(0xFF2D2D2D));
      expect(dark.dividerLine, const Color(0xFF393939));
      expect(dark.onSurfaceVariantSummary, const Color(0x80FFFFFF));
      expect(dark.windowDimming, const Color(0x99000000));
    });

    test('of() 按明暗模式取配色', () {
      expect(MiuixColors.of(Brightness.light), MiuixColors.light);
      expect(MiuixColors.of(Brightness.dark), MiuixColors.dark);
      expect(MiuixColors.light.reverse, MiuixColors.dark);
    });
  });

  group('主题色列表', () {
    test('MIUI 蓝是 miuix 的主色', () {
      expect(colorThemeTypes, hasLength(20));
      expect(colorThemeTypes[miuixColorIndex].color, miuixKeyColor);
      expect(colorThemeTypes[miuixColorIndex].label, 'MIUI 蓝');
      expect(miuixKeyColor, MiuixColors.classicKeyColor);
    });
  });

  group('miuix 令牌到 Material 角色的映射', () {
    const light = MiuixColors.light;
    final scheme = light.toColorScheme();

    test('明暗与主色', () {
      expect(scheme.brightness, Brightness.light);
      expect(scheme.primary, light.primary);
      expect(scheme.onPrimary, light.onPrimary);
      expect(scheme.primaryContainer, light.primaryContainer);
      expect(scheme.primaryFixed, light.primaryVariant);
    });

    test('表面层次', () {
      expect(scheme.surface, light.surface);
      expect(scheme.surfaceContainer, light.surfaceContainer);
      expect(scheme.surfaceContainerHigh, light.surfaceContainerHigh);
      expect(scheme.surfaceContainerHighest, light.surfaceContainerHighest);
      expect(scheme.surfaceBright, light.surfaceContainer);
      expect(scheme.surfaceDim, light.surfaceContainerHigh);
    });

    test('次级文字、分隔线与遮罩', () {
      // PiliNara 一直把 outline 当次级文字色用。
      expect(scheme.outline, light.onSurfaceVariantSummary);
      expect(scheme.onSurfaceVariant, light.onSurfaceVariantSummary);
      // PiliNara 的 secondary 也是次级文字/图标色（以及底栏指示块的兜底色），
      // 所以用 miuix 压在背景上的变体色，而不是它那块中性填充。
      expect(scheme.secondary, light.onBackgroundVariant);
      expect(scheme.secondary, isNot(light.secondary));
      expect(scheme.outlineVariant, light.dividerLine);
      expect(scheme.scrim, light.windowDimming);
      // MIUI 的表面是平的，不做高程着色。
      expect(scheme.surfaceTint, Colors.transparent);
      expect(scheme.inverseSurface, light.onSecondaryVariant);
      expect(scheme.onInverseSurface, light.secondaryVariant);
    });

    test('secondaryContainer 上的前景色用 onSecondaryVariant', () {
      // miuix 的 onSecondaryContainer 是占位符灰（#A9A9A9），压在 #F0F0F0 上几乎看不清，
      // 而 PiliNara 在这个容器上画图标与文字。
      expect(scheme.secondaryContainer, light.secondaryContainer);
      expect(scheme.onSecondaryContainer, light.onSecondaryVariant);
    });
  });

  group('任意 Material 配色会被翻译成 miuix 角色', () {
    final seed = const Color(0xFF5CB67B).asColorSchemeSeed(
      FlexSchemeVariant.material,
      Brightness.light,
    );
    final miuix = MiuixColors.fromColorScheme(seed);

    test('主色与错误色保持原样', () {
      expect(miuix.primary, seed.primary);
      expect(miuix.onPrimary, seed.onPrimary);
      expect(miuix.error, seed.error);
      expect(miuix.errorContainer, seed.errorContainer);
    });

    test('次级色取自 outline，与 miuix 的取色方式一致', () {
      expect(miuix.secondary, seed.outline);
      expect(miuix.onSecondary, seed.surface);
      expect(miuix.secondaryVariant, seed.surfaceContainerHigh);
    });

    test('禁用态与滑轨是不透明的合成色', () {
      expect(
        miuix.sliderBackground,
        Color.alphaBlend(seed.primary.withValues(alpha: 0.2), seed.surface),
      );
      expect(
        miuix.disabledPrimary,
        Color.alphaBlend(seed.primary.withValues(alpha: 0.38), seed.surface),
      );
      expect(
        miuix.onSurfaceSecondary,
        Color.alphaBlend(seed.onSurface.withValues(alpha: 0.8), seed.surface),
      );
    });

    test('深色模式使用更重的遮罩', () {
      final darkSeed = const Color(0xFF5CB67B).asColorSchemeSeed(
        FlexSchemeVariant.material,
        Brightness.dark,
      );
      expect(
        MiuixColors.fromColorScheme(darkSeed).windowDimming,
        const Color(0x99000000),
      );
      expect(miuix.windowDimming, const Color(0x4D000000));
    });
  });

  group('miuix 字阶', () {
    final textTheme = miuixTextTheme();

    test('字号取自 miuix 的十四个槽位', () {
      expect(textTheme.displayLarge?.fontSize, 32);
      expect(textTheme.headlineSmall?.fontSize, 24);
      expect(textTheme.titleLarge?.fontSize, 20);
      expect(textTheme.titleMedium?.fontSize, 17);
      expect(textTheme.titleSmall?.fontSize, 16);
      expect(textTheme.bodyLarge?.fontSize, 17);
      expect(textTheme.bodyMedium?.fontSize, 14);
      expect(textTheme.bodySmall?.fontSize, 13);
      expect(textTheme.labelLarge?.fontSize, 17);
      expect(textTheme.labelSmall?.fontSize, 11);
    });

    test('subtitle 那一档是加粗的', () {
      expect(textTheme.labelMedium?.fontWeight, FontWeight.bold);
      expect(textTheme.bodyLarge?.fontWeight, isNull);
    });

    test('字体族回落里带上 MiSans（miuix 的字体），应用自选字体仍然优先', () {
      final theme = MiuixTheme.getThemeData(colors: MiuixColors.light);
      for (final style in [
        theme.textTheme.bodyLarge,
        theme.textTheme.titleMedium,
        theme.textTheme.labelSmall,
      ]) {
        expect(style?.fontFamilyFallback, contains('MiSans'));
      }
    });

    test('字体族与字重偏好覆盖到全部角色', () {
      final styled = miuixTextTheme(
        fontFamily: 'PiliFont',
        fontWeight: FontWeight.w600,
        color: const Color(0xFFF2F2F2),
      );
      for (final style in [
        styled.displayLarge,
        styled.headlineLarge,
        styled.titleMedium,
        styled.bodyLarge,
        styled.bodySmall,
        styled.labelMedium,
        styled.labelSmall,
      ]) {
        expect(style?.fontFamily, 'PiliFont');
        expect(style?.fontWeight, FontWeight.w600);
        expect(style?.color, const Color(0xFFF2F2F2));
      }
    });
  });

  group('miuix 几何', () {
    test('圆角取自 miuix 各组件的默认值', () {
      expect(MiuixShapes.cardCornerRadius, 16);
      expect(MiuixShapes.buttonCornerRadius, 16);
      expect(MiuixShapes.dialogCornerRadius, 32);
      expect(MiuixShapes.menuCornerRadius, 16);
      expect(MiuixShapes.bottomSheetCornerRadius, 28);
      expect(MiuixShapes.tooltipCornerRadius, 12);
      expect(MiuixShapes.floatingBarCornerRadius, 50);
      expect(MiuixShapes.topBarHeight, 52);
    });

    test('底部弹层只圆上面两个角', () {
      expect(MiuixShapes.bottomSheetRadius.topLeft.x, 28);
      expect(MiuixShapes.bottomSheetRadius.bottomLeft, Radius.zero);
    });
  });

  group('miuix 连续圆角（squircle）', () {
    test('角块是半径的 1.1 倍，并夹在短边一半以内', () {
      expect(miuixSquircleExtension, 1.1);
      expect(miuixSquircleTile(16, const Size(200, 100)), closeTo(17.6, 0.001));
      // 短边 40，一半是 20，超出的部分被夹住。
      expect(miuixSquircleTile(32, const Size(200, 40)), closeTo(20, 0.001));
      expect(miuixSquircleTile(0, const Size(200, 100)), 0);
    });

    test('路径从角块末端起笔，普通圆角矩形则从边上起笔', () {
      const rect = Rect.fromLTWH(0, 0, 100, 60);
      final squircle = miuixSquirclePath(rect, 16);
      final rounded = miuixSquirclePath(rect, 16, enabled: false);
      final start = squircle.computeMetrics().first.getTangentForOffset(0)!;
      final roundedStart = rounded.computeMetrics().first.getTangentForOffset(0)!;
      expect(start.position.dx, closeTo(17.6, 0.01));
      expect(start.position.dy, 0);
      // 普通圆角矩形的路径从左边（或上边）的直线段开始。
      expect(
        roundedStart.position.dx == 0 || roundedStart.position.dy == 0,
        isTrue,
      );
      expect(squircle.getBounds(), rect);
      expect(rounded.getBounds(), rect);
    });

    test('顶部弹层只圆上面两角', () {
      const rect = Rect.fromLTWH(0, 0, 100, 80);
      final topOnly = miuixSquirclePath(rect, 28, topOnly: true);
      final allRound = miuixSquirclePath(rect, 28);
      expect(topOnly.contains(const Offset(0.5, 79.5)), isTrue);
      expect(allRound.contains(const Offset(0.5, 79.5)), isFalse);
    });

    test('形状可以当 ThemeData 的 shape 用，且带描边时相等性稳定', () {
      const border = MiuixSquircleBorder(cornerRadius: 16);
      expect(border.getOuterPath(const Rect.fromLTWH(0, 0, 100, 60)), isNotNull);
      expect(border.copyWith(), border);
      expect(border.scale(2).cornerRadius, 32);
      const inputBorder = MiuixSquircleInputBorder(cornerRadius: 16);
      expect(inputBorder.isOutline, isFalse);
    });
  });

  group('miuix 按压反馈', () {
    test('是替换水波纹的 ink feature 工厂，按下叠加 10%', () {
      const indication = MiuixIndication(Color(0xFF000000));
      expect(indication, isA<InteractiveInkFeatureFactory>());
      expect(indication.pressAlpha, 0.1);
      expect(indication.enterDuration, const Duration(milliseconds: 200));
      expect(indication.exitDuration, const Duration(milliseconds: 350));
    });
  });

  group('miuix 弹层手柄', () {
    test('尺寸取自 miuix', () {
      expect(MiuixDragHandle.restWidth, 45);
      expect(MiuixDragHandle.pressedWidth, 55);
      expect(MiuixDragHandle.handleHeight, 4);
      expect(MiuixDragHandle.handleRadius, 2);
      expect(MiuixDragHandle.areaHeight, 24);
    });
  });

  group('miuix 动效', () {
    testWidgets('边缘跟手返回：慢慢拖过一半屏才返回，拖一点点会弹回', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: MiuixTheme.getThemeData(colors: MiuixColors.light),
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: TextButton(
                  // 走主题的 pageTransitionsTheme，也就是 MiuixPageTransitionsBuilder。
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const Scaffold(
                        body: Center(child: Text('第二页')),
                      ),
                    ),
                  ),
                  child: const Text('打开'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('打开'));
      await tester.pumpAndSettle();
      expect(find.text('第二页'), findsOneWidget);

      // 慢慢拖一点点（远不到半屏）：应该弹回，页面还在。
      var gesture = await tester.startGesture(const Offset(2, 300));
      for (var i = 0; i < 4; i++) {
        await gesture.moveBy(const Offset(10, 0));
        await tester.pump(const Duration(milliseconds: 120));
      }
      await gesture.up();
      await tester.pumpAndSettle();
      expect(find.text('第二页'), findsOneWidget);

      // 慢慢拖过一半屏宽：按 miuix 的判据（死区内看位置）应当返回。
      gesture = await tester.startGesture(const Offset(2, 300));
      for (var i = 0; i < 30; i++) {
        await gesture.moveBy(const Offset(15, 0));
        await tester.pump(const Duration(milliseconds: 40));
      }
      await gesture.up();
      await tester.pumpAndSettle();
      expect(find.text('第二页'), findsNothing);
    });

    /// 被覆盖页的压暗（miuix 的 dimAmount 50%）只由这一处产生，可以用来判断覆盖效果有没有生效。
    Iterable<double> dimAlphas(WidgetTester tester) => tester
        .widgetList<ColoredBox>(find.byType(ColoredBox))
        .map((box) => box.color.a)
        .where((a) => a > 0 && a <= 0.5);

    /// 整屏滑入与「被覆盖页视差」都是横向平移，这里只看横向位移。
    Iterable<double> pageSlideOffsets(WidgetTester tester) => tester
        .widgetList<Transform>(find.byType(Transform))
        .map((t) => t.transform.getTranslation().x)
        .where((dx) => dx.abs() > 0.5);

    testWidgets('GetX → GetX：被覆盖页也会视差与压暗（框架自己不会驱动 GetPageRoute）', (
      tester,
    ) async {
      final controller = MiuixCoverController();
      final route = GetPageRoute<void>(
        page: () => const Scaffold(body: Center(child: Text('第二页'))),
      );
      await tester.pumpWidget(
        MaterialApp(
          theme: MiuixTheme.getThemeData(colors: MiuixColors.light),
          navigatorObservers: [MiuixNavigatorObserver(controller)],
          builder: (context, child) =>
              MiuixNavigationScope(controller: controller, child: child!),
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: TextButton(
                  onPressed: () => Navigator.of(context).push(route),
                  child: const Text('打开'),
                ),
              ),
            ),
          ),
        ),
      );
      expect(dimAlphas(tester), isEmpty);
      await tester.tap(find.text('打开'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 150));
      // 框架不会接 GetX → GetX 的 secondaryAnimation，这份压暗来自我们补的驱动。
      expect(dimAlphas(tester), isNotEmpty);
      expect(controller.debugDriverCount, 1);
      await tester.pumpAndSettle();
      expect(find.text('第二页'), findsOneWidget);
      // 弹出后登记要回收，不能一直挂在 controller 上。
      tester.state<NavigatorState>(find.byType(Navigator)).pop();
      await tester.pumpAndSettle();
      expect(controller.debugDriverCount, 0);
      expect(controller.driverOf(route), isNull);
    });

    testWidgets('框架自己驱动的（Material → Material）只压暗一次', (tester) async {
      final controller = MiuixCoverController();
      await tester.pumpWidget(
        MaterialApp(
          theme: MiuixTheme.getThemeData(colors: MiuixColors.light),
          navigatorObservers: [MiuixNavigatorObserver(controller)],
          builder: (context, child) =>
              MiuixNavigationScope(controller: controller, child: child!),
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: TextButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const Scaffold(
                        body: Center(child: Text('第二页')),
                      ),
                    ),
                  ),
                  child: const Text('打开'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('打开'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 150));
      expect(dimAlphas(tester), hasLength(1));
      await tester.pumpAndSettle();
    });

    testWidgets('弹层类路由不参与页面级视差（弹出卡片不会把底下的页面顶偏）', (tester) async {
      final controller = MiuixCoverController();
      final cases = <String, void Function(BuildContext)>{
        'dialog': (context) => showDialog<void>(
          context: context,
          builder: (_) => const AlertDialog(title: Text('弹层')),
        ),
        'sheet': (context) => showModalBottomSheet<void>(
          context: context,
          builder: (_) => const SizedBox(height: 200),
        ),
        // 首页卡片长按走的就是这条：Get.key.currentState!.push(PublishRoute(...))。
        'publish': (context) => Navigator.of(context).push(
          PublishRoute<void>(
            pageBuilder: (context, animation, secondaryAnimation) =>
                const Center(child: SizedBox(width: 200, height: 200)),
          ),
        ),
      };
      for (final entry in cases.entries) {
        await tester.pumpWidget(
          MaterialApp(
            theme: MiuixTheme.getThemeData(colors: MiuixColors.light),
            navigatorObservers: [MiuixNavigatorObserver(controller)],
            builder: (context, child) =>
                MiuixNavigationScope(controller: controller, child: child!),
            home: Builder(
              builder: (context) => Scaffold(
                body: Center(
                  child: TextButton(
                    onPressed: () => entry.value(context),
                    child: const Text('打开'),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.tap(find.text('打开'));
        await tester.pumpAndSettle();
        // 页面既不能被压暗，也不能被推偏；驱动登记也不该出现。
        expect(dimAlphas(tester), isEmpty, reason: entry.key);
        expect(pageSlideOffsets(tester), isEmpty, reason: entry.key);
        expect(controller.debugDriverCount, 0, reason: entry.key);
        // 点遮罩关掉弹层，进入下一轮。
        await tester.tapAt(const Offset(10, 10));
        await tester.pumpAndSettle();
      }
    });

    testWidgets('返回手势抬手后立刻解除输入屏蔽（落位动画还在跑）', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: MiuixTheme.getThemeData(colors: MiuixColors.light),
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: TextButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const Scaffold(
                        body: Center(child: Text('第二页')),
                      ),
                    ),
                  ),
                  child: const Text('打开'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('打开'));
      await tester.pumpAndSettle();
      final navigator = tester.state<NavigatorState>(
        find.byType(Navigator).first,
      );
      expect(navigator.userGestureInProgress, isFalse);

      // 手势进行中：miuix 要求屏蔽页面内的点击与滚动。
      final gesture = await tester.startGesture(const Offset(2, 300));
      for (var i = 0; i < 5; i++) {
        await gesture.moveBy(const Offset(20, 0));
        await tester.pump(const Duration(milliseconds: 60));
      }
      expect(navigator.userGestureInProgress, isTrue);

      // 抬手之后手势就不再拥有指针：落位弹簧还在跑，但不能再屏蔽点击。
      await gesture.up();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      expect(navigator.userGestureInProgress, isFalse);
      await tester.pumpAndSettle();
      expect(find.text('第二页'), findsOneWidget);
    });

    testWidgets('预测返回：平台的终局信号一到就解除输入屏蔽', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: MiuixTheme.getThemeData(colors: MiuixColors.light),
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: TextButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const Scaffold(
                        body: Center(child: Text('第二页')),
                      ),
                    ),
                  ),
                  child: const Text('打开'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('打开'));
      await tester.pumpAndSettle();
      final navigator = tester.state<NavigatorState>(
        find.byType(Navigator).first,
      );

      // 用平台通道模拟系统级预测返回（Android U+ 的边滑）。
      Future<void> send(String method, {double progress = 0.35}) =>
          tester.binding.defaultBinaryMessenger.handlePlatformMessage(
            SystemChannels.backGesture.name,
            const StandardMethodCodec().encodeMethodCall(
              MethodCall(method, <String, dynamic>{
                'touchOffset': const <double>[100, 300],
                'progress': progress,
                'swipeEdge': 0,
              }),
            ),
            (_) {},
          );

      await send('startBackGesture');
      await tester.pump();
      expect(navigator.userGestureInProgress, isTrue);
      await send('updateBackGestureProgress', progress: 0.4);
      await tester.pump();

      // 用户反悔：平台给 cancel，屏蔽要立刻解除，弹簧自己落回。
      await send('cancelBackGesture');
      await tester.pump();
      expect(navigator.userGestureInProgress, isFalse);
      await tester.pumpAndSettle();
      expect(find.text('第二页'), findsOneWidget);
    });

    test('起手死区与抓取锚点与 miuix 一致', () {
      // 静止起手：进度就是手指位移，拖到底停在 MAX_FINGER_PROGRESS 之前。
      expect(MiuixMotion.anchoredProgress(anchor: 0, fingerProgress: 0), 0);
      expect(
        MiuixMotion.anchoredProgress(anchor: 0, fingerProgress: 0.25),
        0.25,
      );
      expect(
        MiuixMotion.anchoredProgress(anchor: 0, fingerProgress: 9),
        MiuixMotion.maxFingerProgress,
      );
      // 抓住一次进行中的过场（锚点 0.3）：第一帧不跳变，往回拖最多回到静止位。
      expect(
        MiuixMotion.anchoredProgress(anchor: 0.3, fingerProgress: 0),
        0.3,
      );
      expect(
        MiuixMotion.anchoredProgress(anchor: 0.3, fingerProgress: -0.5),
        0,
      );
    });

    test('落位弹簧的种子速度夹在不过冲的界限内', () {
      // 距离 0.5：临界阻尼弹簧只要 v₀ 不小于 -√146·0.5 ≈ -6.04 就不会越过目标。
      final floor = -math.sqrt(MiuixMotion.settleStiffness) * 0.5;
      expect(floor, closeTo(-6.042, 0.01));
      expect(
        MiuixMotion.settleSeedVelocity(
          towardTargetVelocity: -20,
          distance: 0.5,
        ),
        closeTo(floor, 1e-9),
      );
      // 慢速松手原样保留速度（跟手 → 弹簧速度连续）。
      expect(
        MiuixMotion.settleSeedVelocity(
          towardTargetVelocity: -2,
          distance: 0.5,
        ),
        -2,
      );
      // 允许过冲时不夹。
      expect(
        MiuixMotion.settleSeedVelocity(
          towardTargetVelocity: -20,
          distance: 0.5,
          clampOvershoot: false,
        ),
        -20,
      );
    });

    test('预测返回的完成信号默认接受，只有明显回弹才否决', () {
      expect(MiuixMotion.shouldAcceptPredictiveBackCompletion(), isTrue);
      expect(
        MiuixMotion.shouldAcceptPredictiveBackCompletion(velocity: -0.5),
        isTrue,
      );
      expect(
        MiuixMotion.shouldAcceptPredictiveBackCompletion(velocity: -1),
        isFalse,
      );
    });

    test('滚动边界触感的判据与 miuix 一致', () {
      expect(MiuixScrollHaptic.availableVelocityThreshold, 1);
      expect(MiuixScrollHaptic.resetThreshold, 1);
      // 速度够大且这个边界还没震过 → 震。
      expect(
        MiuixScrollHaptic.shouldHaptic(
          overscroll: 12,
          velocity: 1200,
          alreadyHit: false,
        ),
        isTrue,
      );
      // 同一个边界只震一次。
      expect(
        MiuixScrollHaptic.shouldHaptic(
          overscroll: 12,
          velocity: 1200,
          alreadyHit: true,
        ),
        isFalse,
      );
      // 速度太小（慢慢拖到边界）不震。
      expect(
        MiuixScrollHaptic.shouldHaptic(
          overscroll: 12,
          velocity: 0.4,
          alreadyHit: false,
        ),
        isFalse,
      );
    });

    test('过场曲线是 miuix 烘焙的那条弹簧（response 0.8 / damping 0.95）', () {
      const curve = MiuixMotion.programmatic;
      expect(curve.transform(0), closeTo(0, 0.0001));
      // 末帧略小于 1，由动画最后一帧吸附（miuix 的注释里就是这个数）。
      expect(curve.transform(1), closeTo(0.99933, 0.001));
      // 中段很快：五分之一处约 48%。
      expect(curve.transform(0.2), closeTo(0.48, 0.03));
      // 全程单调，不回弹。
      var previous = -1.0;
      for (var i = 0; i <= 20; i++) {
        final value = curve.transform(i / 20);
        expect(value, greaterThanOrEqualTo(previous));
        previous = value;
      }
    });

    test('三条缓动与 miuix 的 anim 模块一致', () {
      expect(MiuixMotion.decelerate.transform(0.5), closeTo(0.75, 0.001));
      expect(MiuixMotion.accelerate.transform(0.5), closeTo(0.25, 0.001));
      expect(
        MiuixMotion.sinOut.transform(0.5),
        closeTo(math.sin(math.pi / 4), 0.0001),
      );
    });

    test('时长取自 miuix 组件自己的值', () {
      expect(MiuixMotion.fast, const Duration(milliseconds: 100));
      expect(MiuixMotion.fastExit, const Duration(milliseconds: 150));
      expect(MiuixMotion.enter, const Duration(milliseconds: 200));
      expect(MiuixMotion.exit, const Duration(milliseconds: 350));
      expect(
        MiuixMotion.programmaticDuration,
        const Duration(milliseconds: 500),
      );
    });

    test('folmeSpring 的刚度与阻尼换算正确', () {
      final spring = MiuixMotion.spring(damping: 1, response: 0.2);
      final stiffness = math.pow(2 * math.pi / 0.2, 2).toDouble();
      expect(spring.mass, 1);
      expect(spring.stiffness, closeTo(stiffness, 0.001));
      expect(spring.damping, closeTo(2 * math.sqrt(stiffness), 0.001));
    });

    test('页面过渡换成 miuix 的 builder', () {
      final theme = MiuixTheme.getThemeData(colors: MiuixColors.light);
      for (final platform in [
        TargetPlatform.android,
        TargetPlatform.iOS,
        TargetPlatform.macOS,
        TargetPlatform.windows,
        TargetPlatform.linux,
      ]) {
        expect(
          theme.pageTransitionsTheme.builders[platform],
          isA<MiuixPageTransitionsBuilder>(),
        );
      }
    });

    test('手势落位按 miuix 的判据：速度阈值 1 屏/秒，死区内看位置', () {
      expect(MiuixMotion.commitVelocityThreshold, 1);
      expect(MiuixMotion.positionFallback, 0.5);
      // 速度够快就由速度决定，与位置无关。
      expect(
        MiuixMotion.shouldCommitGesture(velocity: 1.2, progress: 0.1),
        isTrue,
      );
      expect(
        MiuixMotion.shouldCommitGesture(velocity: -1.2, progress: 0.9),
        isFalse,
      );
      // 死区内看位置。
      expect(
        MiuixMotion.shouldCommitGesture(velocity: 0.3, progress: 0.6),
        isTrue,
      );
      expect(
        MiuixMotion.shouldCommitGesture(velocity: 0.3, progress: 0.4),
        isFalse,
      );
      // 正好等于阈值时也算速度决定。
      expect(
        MiuixMotion.shouldCommitGesture(velocity: 1, progress: 0),
        isTrue,
      );
      expect(
        MiuixMotion.shouldCommitGesture(velocity: -1, progress: 1),
        isFalse,
      );
    });
  });

  group('主题里的 miuix 特性', () {
    final theme = MiuixTheme.getThemeData(colors: MiuixColors.light);

    test('卡片、对话框、弹层、菜单与按钮都是连续圆角', () {
      expect(
        theme.cardTheme.shape,
        const MiuixSquircleBorder(cornerRadius: MiuixShapes.cardCornerRadius),
      );
      expect(
        theme.dialogTheme.shape,
        const MiuixSquircleBorder(cornerRadius: MiuixShapes.dialogCornerRadius),
      );
      expect(
        theme.bottomSheetTheme.shape,
        const MiuixSquircleBorder(
          cornerRadius: MiuixShapes.bottomSheetCornerRadius,
          topOnly: true,
        ),
      );
      expect(
        theme.popupMenuTheme.shape,
        const MiuixSquircleBorder(cornerRadius: MiuixShapes.menuCornerRadius),
      );
      expect(
        theme.filledButtonTheme.style?.shape?.resolve({}),
        const MiuixSquircleBorder(cornerRadius: MiuixShapes.buttonCornerRadius),
      );
    });

    test('按压反馈换成 miuix 的整块淡入', () {
      expect(theme.splashFactory, isA<MiuixIndication>());
      expect(
        (theme.splashFactory as MiuixIndication).color,
        MiuixColors.light.onSurface,
      );
    });

    test('输入框是 MIUI 的填充样式', () {
      final decoration = theme.inputDecorationTheme;
      expect(decoration.filled, isTrue);
      expect(decoration.fillColor, MiuixColors.light.secondaryContainer);
      expect(decoration.border, isA<MiuixSquircleInputBorder>());
      expect(decoration.hintStyle?.color, MiuixColors.light.onSurfaceVariantSummary);
    });

    test('底栏不与应用自己的取色打架', () {
      // MIUI 的浮动底栏底色是 surfaceContainer（页面底色才是 surface），设成 surface 会让整条栏
      // 和页面糊在一起。
      expect(
        theme.navigationBarTheme.backgroundColor,
        MiuixColors.light.surfaceContainer,
      );
      // 指示块必须留空：PiliNara 的底栏把它画成 6%/8% 的叠加色，主题给定不透明的值就会变成硬色块。
      expect(theme.navigationBarTheme.indicatorColor, isNull);
      // 内容色按 miuix 的 FloatingNavigationBar：选中与未选中同色（onSurfaceContainer）。
      expect(
        theme.navigationBarTheme.iconTheme?.resolve({
          WidgetState.selected,
        })?.color,
        MiuixColors.light.onSurfaceContainer,
      );
      expect(
        theme.navigationBarTheme.iconTheme?.resolve({})?.color,
        MiuixColors.light.onSurfaceContainer,
      );
      expect(
        theme.navigationBarTheme.labelTextStyle?.resolve({
          WidgetState.selected,
        })?.color,
        MiuixColors.light.onSurfaceContainer,
      );
      expect(
        theme.navigationBarTheme.labelTextStyle?.resolve({})?.color,
        MiuixColors.light.onSurfaceContainer,
      );
    });

    test('复选框/单选框是圆的，取色按 miuix', () {
      final checkbox = theme.checkboxTheme;
      expect(checkbox.shape, isA<CircleBorder>());
      expect(
        checkbox.fillColor?.resolve({WidgetState.selected}),
        MiuixColors.light.primary,
      );
      expect(checkbox.fillColor?.resolve({}), MiuixColors.light.secondary);
      expect(
        checkbox.fillColor?.resolve({
          WidgetState.selected,
          WidgetState.disabled,
        }),
        MiuixColors.light.disabledPrimary,
      );
      expect(checkbox.checkColor?.resolve({}), MiuixColors.light.onPrimary);
      expect(
        theme.radioTheme.fillColor?.resolve({WidgetState.selected}),
        MiuixColors.light.primary,
      );
      expect(
        theme.radioTheme.fillColor?.resolve({}),
        MiuixColors.light.secondary,
      );
      expect(theme.tabBarTheme.indicatorColor, MiuixColors.light.primary);
      expect(theme.tabBarTheme.dividerColor, MiuixColors.light.dividerLine);
      expect(theme.tabBarTheme.labelColor, MiuixColors.light.onSurface);
    });
  });
}
