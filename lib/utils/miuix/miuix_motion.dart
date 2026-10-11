import 'dart:math' as math;

import 'package:flutter/gestures.dart'
    show DragStartBehavior, HorizontalDragGestureRecognizer, kTouchSlop;
import 'package:flutter/physics.dart' show SpringSimulation, Tolerance;
import 'package:flutter/scheduler.dart' show Ticker;
import 'package:flutter/services.dart' show PredictiveBackEvent;
import 'package:PiliPlus/utils/miuix/miuix_navigation.dart';
import 'package:material_ui/material_ui.dart';

/// miuix 的动效参数。
///
/// 曲线与时长都取自 miuix 自己的实现，而不是 Flutter/Material 的默认值：
///
/// * [programmatic] 是 miuix 导航的进场曲线（`NavProgrammaticEasing`）：把一条欠阻尼弹簧的
///   阶跃响应烘焙成一条曲线（response = 0.8、damping = 0.95），配 [programmaticDuration]
///   （`NavDriverSpec.PROGRAMMATIC_DURATION_MILLIS` = 500ms）播放。中段很快、尾巴很长，不会回弹。
/// * [decelerate] / [accelerate] / [sinOut] 对应 miuix `anim` 模块里的 `DecelerateEasing`、
///   `AccelerateEasing` 与 `SinOutEasing`。
/// * [spring] 对应 `folmeSpring(damping, response)`：刚度 k = (2π/response)²、阻尼比可调。
/// * [fast] / [enter] / [exit] 是 miuix 组件自己用的时长：拖拽手柄按下 100ms、抬起 150ms，
///   按压反馈进入 200ms、退出 350ms。
abstract final class MiuixMotion {
  /// miuix 按压反馈进入的时长（`MiuixIndication` 的 PressEnterSpring，响应 0.2s）。
  static const Duration enter = Duration(milliseconds: 200);

  /// miuix 按压反馈退出的时长（`MiuixIndication` 的 PressExitSpring，响应 0.35s）。
  static const Duration exit = Duration(milliseconds: 350);

  /// 快速反馈（手柄按下、抬起），对应 miuix 手柄的 100ms / 150ms。
  static const Duration fast = Duration(milliseconds: 100);

  /// 快速反馈的回落时长。
  static const Duration fastExit = Duration(milliseconds: 150);

  /// miuix 导航的程序化过场时长（`PROGRAMMATIC_DURATION_MILLIS`）。
  static const Duration programmaticDuration = Duration(milliseconds: 500);

  /// miuix 落位弹簧的刚度（`NavDriverSpec.STIFFNESS`，深度轴单位 = 条目数）。
  static const double settleStiffness = 146;

  /// miuix 弹簧的可见阈值（`NavDriverSpec.VISIBILITY_THRESHOLD`）：离目标不到 0.25% 就算收敛。
  static const double settleVisibilityThreshold = 0.0025;

  /// 手指能驱动到的最大进度（`NavDriverSpec.MAX_FINGER_PROGRESS`）。
  ///
  /// 留 0.1% 给 commit 收尾：手指拖到底时不该把离场页连遮罩一起清空（那一步留给落位）。
  static const double maxFingerProgress = 0.999;

  /// 边缘跟手返回的起手区宽度（dp）。
  ///
  /// miuix-nav 的 `navSwipeDismiss` 本身挂在 display 容器上、可以在屏幕任意位置抓住一次进行中的
  /// 过场，不划边缘区；这里按 Android 返回手势的热区取 20dp，避免抢走页面里的横向列表与播放器
  /// 手势。（miuix 的 `swipeDismiss` 默认是 `None`，所有内置预设都不开，本项目按需求默认打开。）
  static const double swipeBackEdgeWidth = 20;

  /// miuix 导航的过场曲线（烘焙好的弹簧阶跃响应，response = 0.8、damping = 0.95）。
  static const Curve programmatic = _MiuixProgrammaticCurve();

  /// miuix 的 `DecelerateEasing`：1 − (1 − t)²。
  static const Curve decelerate = _MiuixDecelerateCurve();

  /// miuix 的 `AccelerateEasing`：t²。
  static const Curve accelerate = _MiuixAccelerateCurve();

  /// miuix 的 `SinOutEasing`：sin(t · π/2)。
  static const Curve sinOut = _MiuixSinOutCurve();

  /// miuix 的 `folmeSpring`：刚度 k = (2π / response)²，阻尼比 [damping]，质量取 1。
  ///
  /// damping = 1 时临界阻尼（不回弹），小于 1 会来回摆一下，大于 1 更慢。
  static SpringDescription spring({
    double damping = 1,
    double response = 0.3,
  }) {
    final stiffness = math.pow(2 * math.pi / response, 2).toDouble();
    // 阻尼系数 c = 2ζ√(k·m)，质量 m = 1。
    final critical = 2 * math.sqrt(stiffness);
    return SpringDescription(
      mass: 1,
      stiffness: stiffness,
      damping: damping * critical,
    );
  }

  /// 稳定后的默认弹簧（miuix 导航手势落位的 spring：damping 1、stiffness 146）。
  static SpringDescription get settleSpring => const SpringDescription(
    mass: 1,
    stiffness: 146,
    damping: 2 * 12.0830459736, // 2 * sqrt(146) ≈ 临界阻尼
  );

  /// miuix 导航的落位判定阈值（`NavDriverSpec.COMMIT_VELOCITY_THRESHOLD`，单位是「每秒多少屏」）。
  ///
  /// miuix 的规则是：速度的绝对值达到这个阈值就由速度决定；落在死区（|velocity| < 阈值）里才
  /// 看位置，位置过了一半（[positionFallback]）就算完成。返回手势的落位应当沿用同一套判据。
  static const double commitVelocityThreshold = 1;

  /// 死区内按位置判定的分界线（过了一半即提交）。
  static const double positionFallback = 0.5;

  /// 按 miuix 的判据决定一次手势释放是「完成」还是「回退」。
  ///
  /// [velocity] 的单位与 miuix 一致（每秒多少屏），向右/向前为正；[progress] 是已经走过的比例。
  static bool shouldCommitGesture({
    required double velocity,
    required double progress,
  }) {
    if (velocity >= commitVelocityThreshold) {
      return true;
    }
    if (velocity <= -commitVelocityThreshold) {
      return false;
    }
    return progress >= positionFallback;
  }

  /// miuix 的 `navBackCompletionDecision`：平台的预测返回完成信号本身就是一次 commit 判定，
  /// 只有速度明显朝回弹方向时才否决（防某些 ROM 在用户明明在反悔时报完成）。
  static bool shouldAcceptPredictiveBackCompletion({double velocity = 0}) =>
      velocity > -commitVelocityThreshold;

  /// miuix 的 `anchoredProgress`：总进度 = 抓取锚点 + 手指位移，夹在
  /// `min(anchor, 0)..`[maxFingerProgress] 之间。
  ///
  /// 锚点让「抓住一次进行中的过场」不跳变：静止时起手 anchor = 0，第一帧就落在起手的位置上。
  static double anchoredProgress({
    required double anchor,
    required double fingerProgress,
  }) => (anchor + fingerProgress).clamp(
    math.min(anchor, 0),
    maxFingerProgress,
  );

  /// miuix 的 `commitVelocityFloor`：对临界阻尼弹簧 x(t) = e^(-ωt)·(x₀ + (v₀ + ω·x₀)·t)，
  /// 轨迹只有在 v₀ < -ω·x₀ 时才会越过目标，所以把落位的种子速度夹在 `-√stiffness·距离` 之上。
  ///
  /// 慢速松手保留完整速度（跟手 → 弹簧的速度是连续的），只丢掉「只可能变成一次可见回弹」的那部分。
  /// miuix 里 `clampOvershoot = false` 的转场不夹（允许过冲），这里用 [clampOvershoot] 表达。
  static double settleSeedVelocity({
    required double towardTargetVelocity,
    required double distance,
    bool clampOvershoot = true,
  }) {
    if (!clampOvershoot) {
      return towardTargetVelocity;
    }
    final floor = distance <= 0
        ? 0.0
        : -math.sqrt(settleStiffness) * distance;
    return towardTargetVelocity.clamp(floor, double.infinity);
  }
}

/// miuix 过场曲线：`NavSettleEasing(response = 0.8, damping = 0.95)` 的阶跃响应。
///
/// 解一组欠阻尼弹簧：
/// ω = 2π/response、k = ω²、c = damping · 4π/response，
/// w = √(4k − c²)/2、r = −c/2、c₂ = r/w，
/// f(t) = e^{r·t} · (−cos(w·t) + c₂·sin(w·t)) + 1。
class _MiuixProgrammaticCurve extends Curve {
  const _MiuixProgrammaticCurve();

  static const double _response = 0.8;
  static const double _damping = 0.95;

  @override
  double transformInternal(double t) {
    const omega = 2 * math.pi / _response;
    const k = omega * omega;
    const c = _damping * 4 * math.pi / _response;
    final w = math.sqrt(4 * k - c * c) / 2;
    const r = -c / 2;
    final c2 = r / w;
    final decay = math.exp(r * t);
    return decay * (-math.cos(w * t) + c2 * math.sin(w * t)) + 1;
  }
}

/// miuix 的 `DecelerateEasing`（factor = 1）。
class _MiuixDecelerateCurve extends Curve {
  const _MiuixDecelerateCurve();

  @override
  double transformInternal(double t) => 1 - (1 - t) * (1 - t);
}

/// miuix 的 `AccelerateEasing`（factor = 1）。
class _MiuixAccelerateCurve extends Curve {
  const _MiuixAccelerateCurve();

  @override
  double transformInternal(double t) => t * t;
}

/// miuix 的 `SinOutEasing`。
class _MiuixSinOutCurve extends Curve {
  const _MiuixSinOutCurve();

  @override
  double transformInternal(double t) => math.sin(t * math.pi / 2);
}

/// miuix 的页面过渡（对应 `NavTransitions.MiuixDefault`），外加 miuix-nav 的手势层。
///
/// 几何：进场页整屏滑入，被覆盖页向反方向视差 1/4 屏宽、透明度降到 90%、压一层最深 50% 的暗色
/// （`NavDisplayEffects.dimAmount`），时长与曲线用 miuix 导航那套
/// （[MiuixMotion.programmaticDuration] + [MiuixMotion.programmatic]）。
///
/// 手势层按 miuix-nav 的三段实现（`NavSwipeArbitrator` / `snapToFinger` / `navBackCommitDecision`）：
///
/// 1. **起手判据**：导航的激活死区就是系统 touch slop，且只认沿关闭方向的位移。手指在关闭方向上
///    累计走过 touch slop 之前页面纹丝不动；走过之后才算接管，并把死区那段位移一起算进去
///    （`initialDismissTravelPx = towardTravelPx - touchSlop`），页面不会从零重新起步。手指朝关闭
///    的反方向走过死区、或跨轴位移压过关闭方向时，手势让给页面自己的滚动。
/// 2. **跟手**：接管之后不做任何插值，页面进度严格等于手指走过的比例；跨轴的轻微晃动不再中途取消
///    —— 一次手势只在抬手时结束（miuix 的 follow 阶段两个轴向都被消费）。
/// 3. **落位**：松手按「速度优先、位置兜底」判定 commit（阈值 1 进度单位/秒、位置 0.5），把松手
///    瞬时速度作为初速度交给同一根临界阻尼弹簧继续播放（stiffness 146、dampingRatio 1），位置与
///    速度都连续；commit 时按 `commitVelocityFloor` 把种子速度夹在 `-sqrt(stiffness)*距离` 之上，
///    甩出去的松手不会真的弹过头。
///
/// 系统级的预测性返回（Android U+ 的边滑）走同一套：手指 1:1 驱动，平台给出终局的 commit/cancel
/// 信号后交给同一根弹簧落位 —— miuix 的预测返回与普通 pop 共用同一份几何与弹簧，这里也不为它单独
/// 维护第二套动画。
class MiuixPageTransitionsBuilder extends PageTransitionsBuilder {
  const MiuixPageTransitionsBuilder({this.swipeBack = true});

  /// 是否安装边缘跟手返回。
  ///
  /// miuix-nav 的 `swipeDismiss` 默认是 `NavSwipeDirection.None`（所有内置预设都不开，要按路由
  /// 显式声明）；本项目按需求默认打开。需要让某条路由的横向手势完全独占时可以关掉。
  final bool swipeBack;

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return MiuixPageTransition(
      route: route,
      animation: animation,
      secondaryAnimation: secondaryAnimation,
      width: MediaQuery.sizeOf(context).width,
      swipeBack: swipeBack,
      child: child,
    );
  }
}

/// miuix 的页面过渡 + miuix-nav 的手势层，装在每条 `PageRoute` 的过渡里。
class MiuixPageTransition extends StatefulWidget {
  const MiuixPageTransition({
    super.key,
    required this.route,
    required this.animation,
    required this.secondaryAnimation,
    required this.width,
    this.swipeBack = true,
    required this.child,
  });

  final PageRoute<dynamic> route;
  final Animation<double> animation;
  final Animation<double> secondaryAnimation;
  final double width;
  final bool swipeBack;
  final Widget child;

  @override
  State<MiuixPageTransition> createState() => _MiuixPageTransitionState();
}

class _MiuixPageTransitionState extends State<MiuixPageTransition>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final HorizontalDragGestureRecognizer _recognizer;
  Ticker? _ticker;
  SpringSimulation? _spring;
  double? _springTarget;
  bool _commitPending = false;

  /// 导航是否已经接管这一次手势（miuix 的 `NavigationOwned`）。
  bool _claimed = false;

  /// 一次手势是否已经开始（`handleStartBackGesture` 要与 `didStopUserGesture` 配对）。
  bool _gestureStarted = false;

  /// 手指或落位弹簧正在驱动动画：这段时间不做插值（miuix 的 snap 模式）。
  bool _userDriven = false;

  /// 起手瞬间的进度值（正常情况下是 1）。
  double _anchorValue = 1;

  /// miuix 的抓取锚点：起手时已经走过的 pop 进度（静止起手是 0）。
  double _anchor = 0;

  /// 沿关闭方向的累计位移，单位像素，含死区那段（miuix 的 `towardTravelPx`）。
  double _toward = 0;

  /// 跨轴累计位移，带符号（miuix 的 `crossTravelPx`）。
  double _cross = 0;

  /// 关掉落位弹簧在跑时不再起手。
  bool get _canSwipe =>
      widget.swipeBack &&
      widget.route.isCurrent &&
      widget.route.popGestureEnabled &&
      _spring == null;

  /// 由 `MiuixNavigationScope` 提供的覆盖效果控制器（没接就是 null）。
  MiuixCoverController? _coverController;

  /// 关闭方向在屏幕上的符号：LTR 是向右，RTL 是向左。
  ///
  /// miuix 的 `NavSwipeDirection` 取物理屏幕方向、不随布局镜像，这里只做方向投影。
  double get _sign => Directionality.of(context) == TextDirection.rtl ? -1 : 1;

  @override
  void initState() {
    super.initState();
    _recognizer = HorizontalDragGestureRecognizer(debugOwner: this)
      // miuix 的 arbitration 从 DOWN 起算：接管那一刻要把死区里已经走过的位移一起带走
      // （`initialDismissTravelPx`），所以这里取 down，让抬手前的位移也进 onUpdate。
      ..dragStartBehavior = DragStartBehavior.down
      ..onStart = _handleDragStart
      ..onUpdate = _handleDragUpdate
      ..onEnd = _handleDragEnd
      ..onCancel = _handleDragCancel;
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _coverController = MiuixNavigationScope.maybeOf(context);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _recognizer.dispose();
    _ticker?.dispose();
    // 手势（含落位）没走完就被销毁：把「手驱动」信号交还，别让被覆盖页一直按 1:1 渲染。
    _coverController?.gestureDriven = false;
    if (_gestureStarted) {
      _gestureStarted = false;
      // 手势没走完就被销毁（路由被别处 pop、页面被移除）：延迟一拍清掉 navigator 的手势标记。
      final navigator = widget.route.navigator;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (navigator?.mounted ?? false) {
          navigator!.didStopUserGesture();
        }
      });
    }
    super.dispose();
  }

  void _handlePointerDown(PointerDownEvent event) {
    if (!_canSwipe) {
      return;
    }
    _toward = 0;
    _cross = 0;
    _claimed = false;
    _recognizer.addPointer(event);
  }

  void _handleDragStart(DragStartDetails details) {
    _toward = 0;
    _cross = 0;
    _claimed = false;
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    _toward += _sign * details.delta.dx;
    _cross += details.delta.dy;
    if (_claimed) {
      // 接管之后两个轴向都被消费：跨轴轻晃既不抢走也不取消（miuix 的 follow 阶段）。
      _snapToFinger();
      return;
    }
    // 内容优先：朝关闭的反方向走过死区，或跨轴位移压过关闭方向，都让给页面。
    if (_toward < -kTouchSlop ||
        (_cross.abs() > kTouchSlop && _cross.abs() > _toward.abs())) {
      return;
    }
    if (_toward <= kTouchSlop || _toward < _cross.abs()) {
      return;
    }
    _claim();
  }

  /// miuix 的 `claimNavigationIfEligible`：停住可能在跑的过场并采样锚点，然后开始跟手。
  ///
  /// 采样与写入在同一个同步块里（中间不会插帧），所以「先停下再采样」的原子性成立：
  /// `handleStartBackGesture` 写控制器的同时就终止了正在跑的动画。
  void _claim() {
    _claimed = true;
    _anchorValue = widget.animation.value;
    _anchor = 1 - _anchorValue;
    widget.route.handleStartBackGesture(progress: _anchorValue);
    _gestureStarted = true;
    _userDriven = true;
    _coverController?.gestureDriven = true;
    _snapToFinger();
  }

  /// miuix 的 `snapToFinger`：进度 = 锚点 + 手指超出死区的位移，严格 1:1、不过插值器。
  void _snapToFinger() {
    final fingerProgress = (_toward - kTouchSlop) / widget.width;
    widget.route.handleUpdateBackGestureProgress(
      progress: _valueOfProgress(fingerProgress),
    );
  }

  /// 手指进度（朝 pop，且已超出死区）映射回路由的进度值。
  double _valueOfProgress(double fingerProgress) =>
      (1 -
              MiuixMotion.anchoredProgress(
                anchor: _anchor,
                fingerProgress: fingerProgress,
              ))
          .clamp(0.0, 1.0);

  void _handleDragEnd(DragEndDetails details) {
    if (!_claimed) {
      return;
    }
    _claimed = false;
    // miuix 的速度单位是「每秒多少屏」，方向朝 pop 为正。
    final velocity = _sign * details.velocity.pixelsPerSecond.dx / widget.width;
    _endUserGesture();
    _settle(
      commit: MiuixMotion.shouldCommitGesture(
        velocity: velocity,
        progress: 1 - widget.animation.value,
      ),
      progressVelocity: velocity,
    );
  }

  void _handleDragCancel() {
    if (!_claimed) {
      return;
    }
    _claimed = false;
    _endUserGesture();
    _settle(commit: false, progressVelocity: 0);
  }

  /// miuix 只在**手势进行中**屏蔽页面内的点击与滚动（「在释放前，页面内的点击/滚动都被屏蔽」），
  /// 抬手那一刻手势就不再拥有指针了。所以这里在释放时就清掉 navigator 的手势标记，
  /// 落位弹簧继续自己跑（渲染靠 [_userDriven] 保持 1:1 跟手）。
  ///
  /// 不清的话 `_ModalScopeState` 会把整条路由包进
  /// `IgnorePointer(ignoring: route.animation.status == reverse || navigator.userGestureInProgress)`，
  /// 于是一直到落位动画播完，**所有页面**都点不动（这正是「返回动画没播完点不动」的原因）。
  void _endUserGesture() {
    if (_gestureStarted) {
      _gestureStarted = false;
      widget.route.navigator?.didStopUserGesture();
    }
  }

  // --- 系统级的预测性返回（Android U+）：平台的手势事件落到这里 ---

  @override
  bool handleStartBackGesture(PredictiveBackEvent backEvent) {
    // 非手势来源（返回键、ESC）不接管，交给框架自己的 pop 走程序化过场。
    if (backEvent.isButtonEvent || !_canSwipe) {
      return false;
    }
    _toward = 0;
    _cross = 0;
    _claimed = true;
    _anchorValue = widget.animation.value;
    _anchor = 1 - _anchorValue;
    widget.route.handleStartBackGesture(progress: _anchorValue);
    _gestureStarted = true;
    _userDriven = true;
    _coverController?.gestureDriven = true;
    _handlePredictiveBackEvent(backEvent);
    return true;
  }

  @override
  void handleUpdateBackGestureProgress(PredictiveBackEvent backEvent) {
    if (!_gestureStarted) {
      return;
    }
    _handlePredictiveBackEvent(backEvent);
  }

  void _handlePredictiveBackEvent(PredictiveBackEvent backEvent) {
    // 平台的 progress 就是手指走过的比例，直接当 fingerProgress 用，1:1 跟手。
    widget.route.handleUpdateBackGestureProgress(
      progress: _valueOfProgress(backEvent.progress),
    );
  }

  @override
  void handleCancelBackGesture() {
    if (!_gestureStarted || _spring != null) {
      return;
    }
    _endUserGesture();
    // 平台已经判定不返回：交给同一根弹簧落回。
    _settle(commit: false, progressVelocity: 0);
  }

  @override
  void handleCommitBackGesture() {
    if (!_gestureStarted || _spring != null) {
      return;
    }
    _endUserGesture();
    // 平台的完成信号本身就是一次 commit 判定（miuix 的 `navBackCompletionDecision`，速度取 0 即接受）。
    _settle(
      commit: MiuixMotion.shouldAcceptPredictiveBackCompletion(),
      progressVelocity: 0,
    );
  }

  // --- 落位：同一根共享弹簧 ---

  /// miuix 的 `settleTo` / `settleCancel`：把松手速度当初速度交给同一根弹簧。
  void _settle({required bool commit, required double progressVelocity}) {
    final from = widget.animation.value;
    final to = commit ? 0.0 : 1.0;
    // value = 1 - progress，所以朝 pop 的进度速度在值轴上是负的（miuix 把进度速度取负交给深度轴）。
    // commit 时按 `commitVelocityFloor` 夹住过冲；cancel 的目标在上方，临界阻尼不会越过它。
    final seed = MiuixMotion.settleSeedVelocity(
      towardTargetVelocity: -progressVelocity,
      distance: (to - from).abs(),
      clampOvershoot: commit,
    );
    _springTarget = to;
    _commitPending = commit;
    _spring = SpringSimulation(
      MiuixMotion.settleSpring,
      from,
      to,
      seed,
      tolerance: const Tolerance(
        distance: MiuixMotion.settleVisibilityThreshold,
      ),
    );
    (_ticker ??= createTicker(_handleSpringTick)).start();
  }

  void _handleSpringTick(Duration elapsed) {
    final spring = _spring;
    if (spring == null) {
      return;
    }
    final t = elapsed.inMicroseconds / Duration.microsecondsPerSecond;
    if (spring.isDone(t)) {
      _finishSettle();
      return;
    }
    widget.route.handleUpdateBackGestureProgress(
      progress: spring.x(t).clamp(0.0, 1.0),
    );
  }

  void _finishSettle() {
    final commit = _commitPending;
    final target = _springTarget ?? widget.animation.value;
    _ticker?.stop();
    _spring = null;
    _springTarget = null;
    _commitPending = false;
    _userDriven = false;
    _coverController?.gestureDriven = false;
    widget.route.handleUpdateBackGestureProgress(progress: target);
    // 手势标记在抬手（或平台的终局信号）时就已经清掉了；这里只做框架自己的 pop：
    // 位置已经落到 0，这一步只是记账。
    if (commit) {
      widget.route.navigator?.pop();
    }
  }

  /// 程序化过场用 miuix 烘焙好的曲线；手势（含落位弹簧）期间不过插值。
  double _curved(Animation<double> animation, double t) {
    final curve = animation.status == AnimationStatus.reverse
        ? MiuixMotion.programmatic.flipped
        : MiuixMotion.programmatic;
    return curve.transform(t.clamp(0.0, 1.0));
  }

  @override
  Widget build(BuildContext context) {
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final direction = rtl ? -1.0 : 1.0;
    // 首屏不播进场滑入，但被覆盖时照样视差 + 压暗。
    final skipEnter = widget.route.isFirst;
    final padding = MediaQuery.paddingOf(context);
    final edgeWidth = math.max(
      rtl ? padding.right : padding.left,
      MiuixMotion.swipeBackEdgeWidth,
    );
    // 框架只在 canTransitionTo / canTransitionFrom 都为真时才驱动被覆盖页的
    // secondaryAnimation；GetX → GetX 拿不到，由 MiuixNavigationScope 补一份驱动。
    final coverDriver = _coverController?.driverOf(widget.route);
    return Stack(
      fit: StackFit.passthrough,
      children: [
        AnimatedBuilder(
          animation: Listenable.merge([
            widget.animation,
            widget.secondaryAnimation,
            coverDriver,
          ]),
          child: widget.child,
          builder: (context, child) {
            final raw = widget.animation.value;
            // 手势（含落位弹簧）期间 1:1 跟手，不过插值器（miuix 的 snap 模式）。
            final gestureDriven =
                _userDriven ||
                widget.route.popGestureInProgress ||
                (_coverController?.gestureDriven ?? false);
            final enter = skipEnter
                ? 1.0
                : (gestureDriven ? raw : _curved(widget.animation, raw));
            // miuix 的「视觉是深度的纯函数」：被覆盖的程度同样直接跟着深度走，
            // 所以手势期间仍然不过插值器（`popGestureInProgress` 是整个 navigator 的，
            // 被覆盖的那一页也能读到）。
            final coverAnimation = coverDriver ?? widget.secondaryAnimation;
            final rawCover = coverAnimation.value;
            final cover = gestureDriven
                ? rawCover
                : _curved(coverAnimation, rawCover);
            final page = child ?? const SizedBox.shrink();
            return Transform.translate(
              // 被覆盖时向反方向视差 1/4 屏宽（miuix 的 covered 处理）。
              offset: Offset(-direction * cover * widget.width * 0.25, 0),
              child: Opacity(
                opacity: 1 - 0.1 * cover,
                child: Transform.translate(
                  // 进场页整屏滑入。
                  offset: Offset(direction * (1 - enter) * widget.width, 0),
                  child: cover <= 0
                      ? page
                      : Stack(
                          fit: StackFit.passthrough,
                          children: [
                            page,
                            // miuix 的遮罩：正在被覆盖的页面上压一层最深 50% 的暗色
                            // （NavDisplayEffects.dimAmount = 0.5），随过场进度淡入。
                            Positioned.fill(
                              child: IgnorePointer(
                                child: ColoredBox(
                                  color: const Color(
                                    0xFF000000,
                                  ).withValues(alpha: 0.5 * cover),
                                ),
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            );
          },
        ),
        // 边缘起手区：只在关闭方向那一侧留一条窄带，避开页面里的横向列表与播放器手势。
        if (widget.swipeBack)
          PositionedDirectional(
            start: 0,
            top: 0,
            bottom: 0,
            width: edgeWidth,
            child: Listener(
              behavior: HitTestBehavior.translucent,
              onPointerDown: _handlePointerDown,
            ),
          ),
      ],
    );
  }
}
