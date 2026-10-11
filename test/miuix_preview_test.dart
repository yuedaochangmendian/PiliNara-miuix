// 仅供本地预览：用 --update-goldens 生成 miuix 主题下的界面截图（不提交到仓库）。
import 'dart:io';
import 'dart:typed_data';

import 'package:PiliPlus/utils/miuix/miuix_colors.dart';
import 'package:PiliPlus/utils/miuix/miuix_drag_handle.dart';
import 'package:PiliPlus/utils/miuix/miuix_blur.dart';
import 'package:PiliPlus/utils/miuix/miuix_cascading_popup.dart';
import 'package:PiliPlus/utils/miuix/miuix_icon.dart';
import 'package:PiliPlus/utils/miuix/miuix_shapes.dart';
import 'package:PiliPlus/utils/miuix/miuix_squircle.dart';
import 'package:PiliPlus/utils/miuix/miuix_theme.dart';
import 'package:PiliPlus/utils/theme_utils.dart';
import 'package:PiliPlus/common/widgets/floating_navigation_bar.dart';
import 'package:flutter/services.dart' show FontLoader;
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

const _fontFamily = 'PreviewFont';

void main() {
  testWidgets('miuix 主题预览', (tester) async {
    // 真实文件 IO 必须放在 runAsync 里，否则会被测试的假时钟卡住。
    await tester.runAsync(() async {
      final bytes = await File(r'C:\Windows\Fonts\simhei.ttf').readAsBytes();
      final loader = FontLoader(_fontFamily)
        ..addFont(Future.value(ByteData.sublistView(Uint8List.fromList(bytes))));
      await loader.load();
    });
    tester.view.physicalSize = const Size(760, 1900);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);

    for (final entry in [
      ('light', MiuixColors.light),
      ('dark', MiuixColors.dark),
    ]) {
      // ignore: avoid_print
      print('rendering ${entry.$1}');
      await tester.pumpWidget(_Preview(colors: entry.$2));
      // MaterialApp 的主题切换是带动画的，等它结束再截图，否则会拍到中间态。
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();
      // ignore: avoid_print
      print('capturing ${entry.$1}');
      await expectLater(
        find.byType(_Preview),
        matchesGoldenFile('goldens/miuix_${entry.$1}.png'),
      );
      // ignore: avoid_print
      print('captured ${entry.$1}');
    }
    // 纯黑模式：页面钉成纯黑，容器层次保持 miuix 调色板给的 #242424 / #2D2D2D。
    await tester.pumpWidget(
      const _Preview(colors: MiuixColors.dark, pureBlack: true),
    );
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 400));
    await expectLater(
      find.byType(_Preview),
      matchesGoldenFile('goldens/miuix_pureblack.png'),
    );
    // ignore: avoid_print
    print('captured pureblack');
  });

  // 单独出一张底栏的图：这里渲染的是应用自己的 FloatingNavigationBar，
  // 用来确认选中指示块不是硬色块、图标与标签也能看清。
  testWidgets('miuix 底栏预览', (tester) async {
    await tester.runAsync(() async {
      final bytes = await File(r'C:\Windows\Fonts\simhei.ttf').readAsBytes();
      final loader = FontLoader(_fontFamily)
        ..addFont(Future.value(ByteData.sublistView(Uint8List.fromList(bytes))));
      await loader.load();
    });
    tester.view.physicalSize = const Size(760, 340);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);

    for (final entry in [
      ('light', MiuixColors.light),
      ('dark', MiuixColors.dark),
    ]) {
      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: MiuixTheme.getThemeData(
            colors: entry.$2,
            fontFamily: _fontFamily,
          ),
          home: Builder(
            builder: (context) {
              return Scaffold(
                body: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    FloatingNavigationBar(
                      selectedIndex: 0,
                      destinations: const [
                        FloatingNavigationDestination(
                          icon: Icon(Icons.home_outlined),
                          selectedIcon: Icon(Icons.home),
                          label: '首页',
                        ),
                        FloatingNavigationDestination(
                          icon: Icon(Icons.video_library_outlined),
                          selectedIcon: Icon(Icons.video_library),
                          label: '动态',
                        ),
                        FloatingNavigationDestination(
                          icon: Icon(Icons.person_outline),
                          selectedIcon: Icon(Icons.person),
                          label: '我的',
                        ),
                      ],
                      onDestinationSelected: (_) {},
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 400));
      await expectLater(
        find.byType(Scaffold),
        matchesGoldenFile('goldens/miuix_navbar_${entry.$1}.png'),
      );
      // ignore: avoid_print
      print('captured navbar ${entry.$1}');
    }
  });

  // miuix 图标集（矢量转过来的路径）：核对方向、粗细与缩放是否正常。
  testWidgets('miuix 图标预览', (tester) async {
    await tester.runAsync(() async {
      final bytes = await File(r'C:\Windows\Fonts\simhei.ttf').readAsBytes();
      final loader = FontLoader(_fontFamily)
        ..addFont(Future.value(ByteData.sublistView(Uint8List.fromList(bytes))));
      await loader.load();
    });
    tester.view.physicalSize = const Size(760, 640);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);

    const icons = [
      ('back', MiuixIcons.back),
      ('close', MiuixIcons.close),
      ('search', MiuixIcons.search),
      ('settings', MiuixIcons.settings),
      ('home', MiuixIcons.home),
      ('add', MiuixIcons.add),
      ('delete', MiuixIcons.delete),
      ('share', MiuixIcons.share),
      ('download', MiuixIcons.download),
      ('refresh', MiuixIcons.refresh),
      ('play', MiuixIcons.play),
      ('pause', MiuixIcons.pause),
    ];

    for (final entry in [
      ('light', MiuixColors.light),
      ('dark', MiuixColors.dark),
    ]) {
      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: MiuixTheme.getThemeData(
            colors: entry.$2,
            fontFamily: _fontFamily,
          ),
          home: Scaffold(
            body: Center(
              child: Wrap(
                spacing: 24,
                runSpacing: 16,
                alignment: WrapAlignment.center,
                children: [
                  for (final icon in icons)
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        MiuixIcon(icon.$2, size: 32),
                        const SizedBox(height: 4),
                        Text(icon.$1, style: const TextStyle(fontSize: 10)),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 400));
      await expectLater(
        find.byType(Scaffold),
        matchesGoldenFile('goldens/miuix_icons_${entry.$1}.png'),
      );
      // ignore: avoid_print
      print('captured icons ${entry.$1}');
    }
  });

  // 背景模糊与渐变模糊：底图放大到能看出糊掉的细节，左边普通模糊、右边上强下弱。
  testWidgets('miuix 背景模糊预览', (tester) async {
    await tester.runAsync(() async {
      final bytes = await File(r'C:\Windows\Fonts\simhei.ttf').readAsBytes();
      final loader = FontLoader(_fontFamily)
        ..addFont(Future.value(ByteData.sublistView(Uint8List.fromList(bytes))));
      await loader.load();
    });
    tester.view.physicalSize = const Size(760, 420);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);

    const stripes = <Color>[
      Color(0xFF3482FF),
      Color(0xFFFF6699),
      Color(0xFF5CB67B),
      Color(0xFFFF9800),
      Color(0xFF9C27B0),
      Color(0xFF00BCD4),
    ];

    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: MiuixTheme.getThemeData(
          colors: MiuixColors.light,
          fontFamily: _fontFamily,
        ),
        home: Scaffold(
          body: Stack(
            children: [
              // 被模糊的底图
              Positioned.fill(
                child: Row(
                  children: [
                    for (final color in stripes)
                      Expanded(child: ColoredBox(color: color)),
                  ],
                ),
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.only(left: 16),
                  child: SizedBox(
                    width: 150,
                    height: 120,
                    child: MiuixBackdrop(
                      borderRadius: BorderRadius.circular(16),
                      tint: Colors.white.withValues(alpha: 0.35),
                      child: const Center(child: Text('背景模糊 20dp')),
                    ),
                  ),
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: SizedBox(
                    width: 150,
                    height: 120,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: MiuixProgressiveBlur(
                        maxRadius: MiuixBlur.radius,
                        tint: Colors.white.withValues(alpha: 0.25),
                        child: const Align(
                          alignment: Alignment.bottomCenter,
                          child: Padding(
                            padding: EdgeInsets.only(bottom: 8),
                            child: Text('渐变模糊'),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 400));
    await expectLater(
      find.byType(Scaffold),
      matchesGoldenFile('goldens/miuix_blur.png'),
    );
    // ignore: avoid_print
    print('captured blur');
  });

  // 级联弹层：点列表项后菜单从该项原地"长"出来；展开中途与完全展开各截一帧。
  testWidgets('miuix 级联弹层预览', (tester) async {
    await tester.runAsync(() async {
      final bytes = await File(r'C:\Windows\Fonts\simhei.ttf').readAsBytes();
      final loader = FontLoader(_fontFamily)
        ..addFont(Future.value(ByteData.sublistView(Uint8List.fromList(bytes))));
      await loader.load();
    });
    tester.view.physicalSize = const Size(760, 500);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);

    final rowKey = GlobalKey();
    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: MiuixTheme.getThemeData(
          colors: MiuixColors.light,
          fontFamily: _fontFamily,
        ),
        home: Scaffold(
          body: ListView(
            padding: const EdgeInsets.all(12),
            children: [
              Card(
                child: ListTile(
                  key: rowKey,
                  title: const Text('长按/点这里弹出菜单'),
                  trailing: const MiuixIcon(MiuixIcons.more),
                  onTap: () async {
                    final box =
                        rowKey.currentContext!.findRenderObject()! as RenderBox;
                    final anchor = box.localToGlobal(Offset.zero) & box.size;
                    await MiuixCascadingPopup.show<int>(
                      context: rowKey.currentContext!,
                      anchor: anchor,
                      items: const [
                        MiuixCascadingItem(value: 1, child: Text('稍后再看')),
                        MiuixCascadingItem(value: 2, child: Text('下载')),
                        MiuixCascadingItem(value: 3, child: Text('分享')),
                        MiuixCascadingItem(
                          value: 4,
                          child: Text('不感兴趣'),
                          destructive: true,
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.text('长按/点这里弹出菜单'));
    // 先走一帧让点击回调把路由推起来，再推进动画，否则截到的是动画起点（裁剪区还贴在行上）。
    await tester.pump();
    // 展开中途。
    await tester.pump(const Duration(milliseconds: 100));
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/miuix_cascading_mid.png'),
    );
    // 完全展开。
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/miuix_cascading_open.png'),
    );
    // ignore: avoid_print
    print('captured cascading');
  });

  // 按压反馈：点一下之后必须淡出（否则会在被点过的标签上留一块色），按住时才显示叠加色。
  testWidgets('miuix 按压反馈预览', (tester) async {
    await tester.runAsync(() async {
      final bytes = await File(r'C:\Windows\Fonts\simhei.ttf').readAsBytes();
      final loader = FontLoader(_fontFamily)
        ..addFont(Future.value(ByteData.sublistView(Uint8List.fromList(bytes))));
      await loader.load();
    });
    tester.view.physicalSize = const Size(760, 420);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);

    Future<void> pumpPreview(MiuixColors colors) async {
      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: MiuixTheme.getThemeData(
            colors: colors,
            fontFamily: _fontFamily,
          ),
          home: Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      FilledButton(
                        onPressed: () {},
                        child: const Text('点一下'),
                      ),
                      FilledButton(
                        onPressed: () {},
                        child: const Text('按住'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 400));
    }

    for (final entry in [
      ('light', MiuixColors.light),
      ('dark', MiuixColors.dark),
    ]) {
      await pumpPreview(entry.$2);
      // 左边的按钮点一下（松手后叠加色必须完全消失），右边的按钮按住不放
      // （按住期间叠加色只出现在右边这一个按钮上——落点错了就会跑到最左边那个，
      // 也就是用户反馈的「点其他标签时第一个标签也出现点击效果」）。
      await tester.tap(find.text('点一下'));
      await tester.pump(const Duration(seconds: 1));
      final gesture = await tester.startGesture(
        tester.getCenter(find.text('按住')),
      );
      await tester.pump(const Duration(milliseconds: 300));
      await expectLater(
        find.byType(Scaffold),
        matchesGoldenFile('goldens/miuix_ink_${entry.$1}.png'),
      );
      await gesture.up();
      await tester.pump(const Duration(milliseconds: 500));
      // ignore: avoid_print
      print('captured ink ${entry.$1}');
    }
  });

  // 返回手势：从边缘慢慢拖出来时，页面 1:1 跟手、被覆盖的页向左视差 1/4 屏宽并压暗 50%。
  testWidgets('miuix 返回手势预览', (tester) async {
    await tester.runAsync(() async {
      final bytes = await File(r'C:\Windows\Fonts\simhei.ttf').readAsBytes();
      final loader = FontLoader(_fontFamily)
        ..addFont(Future.value(ByteData.sublistView(Uint8List.fromList(bytes))));
      await loader.load();
    });
    tester.view.physicalSize = const Size(760, 1340);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);

    Widget body(Color color, String title, String note) => Material(
      color: color,
      child: Builder(
        builder: (context) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                title,
                style: const TextStyle(fontFamily: _fontFamily, fontSize: 30),
              ),
              const SizedBox(height: 10),
              Text(
                note,
                style: TextStyle(
                  fontFamily: _fontFamily,
                  fontSize: 15,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: MiuixTheme.getThemeData(
          colors: MiuixColors.light,
          fontFamily: _fontFamily,
        ),
        home: Builder(
          builder: (context) => Scaffold(
            body: Stack(
              children: [
                body(
                  MiuixColors.light.surface,
                  '首页',
                  '被覆盖时视差 1/4 屏宽，并压一层 50% 的暗色',
                ),
                Center(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => Scaffold(
                          body: body(
                            MiuixColors.light.surfaceContainer,
                            '视频详情',
                            '从边缘往右拖：页面 1:1 跟手',
                          ),
                        ),
                      ),
                    ),
                    child: const Text('打开详情页'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('打开详情页'));
    await tester.pumpAndSettle();

    // 手指从左边缘拖出来 140dp（逻辑宽度 380dp 的 37%），停在跟手状态。
    final gesture = await tester.startGesture(const Offset(4, 300));
    for (var i = 0; i < 7; i++) {
      await gesture.moveBy(const Offset(20, 0));
      await tester.pump(const Duration(milliseconds: 60));
    }
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/miuix_back_gesture.png'),
    );
    // ignore: avoid_print
    print('captured back gesture');

    // 松手（远不到一半屏）：弹簧落回原位，页面还在。
    await gesture.up();
    await tester.pumpAndSettle();
  });
}

class _Preview extends StatelessWidget {
  const _Preview({required this.colors, this.pureBlack = false});

  final MiuixColors colors;

  /// 纯黑模式：miuix 的层次不再额外压暗，页面表面钉成纯黑（见 ThemeUtils.darkenTheme）。
  final bool pureBlack;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: pureBlack
          ? ThemeUtils.darkenTheme(
              MiuixTheme.getThemeData(
                colors: colors,
                fontFamily: _fontFamily,
              ),
            )
          : MiuixTheme.getThemeData(
              colors: colors,
              fontFamily: _fontFamily,
            ),
      home: Builder(
        builder: (context) {
          final theme = Theme.of(context);
          final scheme = theme.colorScheme;
          return Scaffold(
            appBar: AppBar(
              title: const Text('MIUI 主题预览'),
              actions: [
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.search),
                ),
              ],
            ),
            body: ListView(
              padding: const EdgeInsets.all(12),
              children: [
                Text('色板', style: theme.textTheme.titleSmall),
                Builder(
                  builder: (context) {
                    final tile = ListTileTheme.of(context);
                    // ignore: avoid_print
                    print(
                      'diagnostic: defaultText=${DefaultTextStyle.of(context).style.color} '
                      'bodyLarge=${theme.textTheme.bodyLarge?.color} '
                      'onSurface=${scheme.onSurface} '
                      'tileText=${tile.textColor} '
                      'tileTitle=${tile.titleTextStyle?.color}',
                    );
                    return const SizedBox.shrink();
                  },
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final swatch in [
                      ('primary', colors.primary),
                      ('onPrimary', colors.onPrimary),
                      ('primaryVariant', colors.primaryVariant),
                      ('secondary', colors.secondary),
                      ('secondaryVariant', colors.secondaryVariant),
                      ('selected', colors.onSecondaryVariant),
                      ('surface', colors.surface),
                      ('container', colors.surfaceContainer),
                      ('containerHigh', colors.surfaceContainerHigh),
                      ('containerHighest', colors.surfaceContainerHighest),
                      ('background', colors.background),
                      ('outline', colors.outline),
                      ('divider', colors.dividerLine),
                      ('error', colors.error),
                      ('tertiary', colors.tertiaryContainer),
                      ('summary', colors.onSurfaceVariantSummary),
                    ])
                      _Swatch(label: swatch.$1, color: swatch.$2),
                  ],
                ),
                const SizedBox(height: 12),
                Card(
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.tune),
                        title: const Text('卡片标题（17）'),
                        subtitle: const Text('次级文字 60% 黑'),
                        trailing: Switch(value: true, onChanged: (_) {}),
                      ),
                      Divider(height: 1, thickness: 1, color: colors.dividerLine),
                      ListTile(
                        leading: const Icon(Icons.dark_mode_outlined),
                        title: const Text('未开启的开关'),
                        trailing: Switch(value: false, onChanged: (_) {}),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('按钮与滑块', style: theme.textTheme.titleMedium),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            FilledButton(
                              onPressed: () {},
                              child: const Text('确定'),
                            ),
                            const SizedBox(width: 12),
                            IconButton.filledTonal(
                              onPressed: () {},
                              icon: const Icon(Icons.favorite_border),
                            ),
                            const SizedBox(width: 12),
                            // MIUI 的复选框是圆的（miuix 用 CircleShape）。
                            Checkbox(value: true, onChanged: (_) {}),
                            Checkbox(value: false, onChanged: (_) {}),
                          ],
                        ),
                        Slider(value: 0.55, onChanged: (_) {}),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('连续圆角（左）vs 普通圆角（右）',
                            style: theme.textTheme.titleSmall),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                height: 72,
                                decoration: ShapeDecoration(
                                  color: colors.primary,
                                  shape: const MiuixSquircleBorder(
                                    cornerRadius: 20,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Container(
                                height: 72,
                                decoration: BoxDecoration(
                                  color: colors.primary,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          decoration: const InputDecoration(
                            hintText: 'MIUI 输入框',
                            prefixIcon: Icon(Icons.search),
                          ),
                          style: theme.textTheme.bodyLarge,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // 弹层：连续圆角 + 拖拽手柄。
                DecoratedBox(
                  decoration: ShapeDecoration(
                    color: colors.background,
                    shape: MiuixSquircleBorder(
                      cornerRadius: MiuixShapes.bottomSheetCornerRadius,
                      topOnly: true,
                      side: BorderSide(color: colors.dividerLine),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const MiuixDragHandle(),
                      Padding(
                        padding: const EdgeInsets.only(
                          left: 24,
                          right: 24,
                          bottom: 20,
                        ),
                        child: Row(
                          children: [
                            Text('弹层内容', style: theme.textTheme.titleMedium),
                            const Spacer(),
                            Text(
                              '手柄 45×4dp',
                              style: theme.textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: colors.background,
                          borderRadius: BorderRadius.circular(32),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x1F000000),
                              blurRadius: 12,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('对话框', style: theme.textTheme.titleMedium),
                            const SizedBox(height: 4),
                            Text(
                              '圆角 32，底色 background',
                              style: theme.textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: colors.background,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(28),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('底部弹层', style: theme.textTheme.titleMedium),
                            const SizedBox(height: 4),
                            Text(
                              '上两角 28',
                              style: theme.textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: colors.onSecondaryVariant,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Snackbar：底色 onSecondaryVariant',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colors.secondaryVariant,
                          ),
                        ),
                      ),
                      Text(
                        '撤销',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: scheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: colors.surfaceContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '提示气泡 12',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceContainer,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: colors.secondaryContainer,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        '次级容器',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.onSecondaryVariant,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: colors.primary,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        '主色填充',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.onPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final onColor = color.computeLuminance() > 0.5
        ? const Color(0xFF000000)
        : const Color(0xFFFFFFFF);
    return Container(
      width: 112,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0x33000000)),
      ),
      child: Text(
        label,
        style: TextStyle(color: onColor, fontSize: 10),
        textAlign: TextAlign.center,
      ),
    );
  }
}
