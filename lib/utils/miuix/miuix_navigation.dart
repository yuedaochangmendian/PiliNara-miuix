import 'package:material_ui/material_ui.dart';

/// miuix-nav 的「被覆盖页」需要一个驱动源。
///
/// Flutter 只在 `previousRoute.canTransitionTo(nextRoute)` 与
/// `nextRoute.canTransitionFrom(previousRoute)` 同时为真时
/// （`TransitionRoute._updateSecondaryAnimation`），才把上一页的 `secondaryAnimation` 接到新页的
/// 动画上。GetX 的 `GetPageRouteTransitionMixin.canTransitionTo` 只接受 Material 系路由，于是
/// **GetX → GetX 的被覆盖页是静止的**：miuix 的 1/4 屏宽视差与最深 50% 的压暗都看不到（进场页
/// 自己的滑入不受影响）。
///
/// 这里按框架的同一条件补一份驱动：只有当框架不会自己接的时候，才用上一层路由的 `animation`
/// 驱动这一页的覆盖程度 —— miuix 的 covered 视觉是深度的纯函数，同一份几何只有一个来源。
class MiuixCoverController extends ChangeNotifier {
  final Map<Route<dynamic>, _CoverBinding> _bindings =
      <Route<dynamic>, _CoverBinding>{};

  /// [route] 的覆盖驱动；null 表示按框架自己的 `secondaryAnimation` 走。
  Animation<double>? driverOf(Route<dynamic> route) => _bindings[route]?.driver;

  /// 当前登记着的驱动数量（测试用来确认登记与回收）。
  int get debugDriverCount => _bindings.length;

  void _drive(Route<dynamic> route, Animation<double> driver) {
    final existing = _bindings[route];
    if (existing != null && identical(existing.driver, driver)) {
      return;
    }
    // 被覆盖页的驱动就是上一层的动画：它回落到 0（上一层被弹出）时这份登记就该回收，
    // 不然会一直挂在 controller 上。
    _release(route);
    _bindings[route] = _CoverBinding(driver, () => _release(route));
    notifyListeners();
  }

  void _release(Route<dynamic> route) {
    final binding = _bindings.remove(route);
    if (binding != null) {
      binding.dispose();
      notifyListeners();
    }
  }
}

/// 一条登记：被覆盖页 + 驱动它的上一层动画，外加回落时的回收回调。
class _CoverBinding {
  _CoverBinding(this.driver, this._onDismissed) {
    driver.addStatusListener(_handleStatus);
  }

  final Animation<double> driver;
  final VoidCallback _onDismissed;

  void _handleStatus(AnimationStatus status) {
    if (status == AnimationStatus.dismissed) {
      _onDismissed();
    }
  }

  void dispose() => driver.removeStatusListener(_handleStatus);
}

/// 把 [MiuixCoverController] 递给路由子树。
///
/// 要放在 Navigator 之上（`MaterialApp.builder` 里那层），路由页面才拿得到；配合
/// [MiuixNavigatorObserver] 使用，两者共享同一个 controller。
class MiuixNavigationScope extends InheritedNotifier<MiuixCoverController> {
  const MiuixNavigationScope({
    super.key,
    required MiuixCoverController controller,
    required super.child,
  }) : super(notifier: controller);

  static MiuixCoverController? maybeOf(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<MiuixNavigationScope>()
      ?.notifier;
}

/// 登记「框架不会驱动」的被覆盖页，交给 [MiuixCoverController]。
///
/// 用法：`navigatorObservers: [..., MiuixNavigatorObserver(controller)]` +
/// `builder` 里套一层 `MiuixNavigationScope(controller: controller, child: ...)`。
class MiuixNavigatorObserver extends NavigatorObserver {
  MiuixNavigatorObserver(this.controller);

  final MiuixCoverController controller;

  /// 自己维护一份栈：`didReplace` 不给上一层路由，只能从栈里找。
  final List<Route<dynamic>> _stack = <Route<dynamic>>[];

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (!_stack.contains(route)) {
      final index = previousRoute == null ? _stack.length : _stack.indexOf(previousRoute) + 1;
      _stack.insert(index.clamp(0, _stack.length), route);
    }
    _resync();
  }

  // 弹出时不重新同步：被覆盖页的驱动就是弹出页的动画，它会自己回落到 0，
  // 这时候要是把驱动解掉，覆盖效果会直接跳回 0 而不是跟着回落。
  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _stack.remove(route);
    controller._release(route);
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _stack.remove(route);
    controller._release(route);
    _resync();
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    if (oldRoute != null) {
      final index = _stack.indexOf(oldRoute);
      if (index >= 0) {
        _stack[index] = newRoute ?? _stack[index];
      }
      controller._release(oldRoute);
    }
    _resync();
  }

  /// 按框架的判据重算每一对「相邻页」：框架自己会接的就不登记，不会接的才交给 controller。
  void _resync() {
    for (var i = 0; i < _stack.length; i++) {
      final below = _stack[i];
      final above = i + 1 < _stack.length ? _stack[i + 1] : null;
      final animation = above is TransitionRoute<dynamic>
          ? above.animation
          : null;
      if (animation == null || _frameworkDrives(below, above!)) {
        controller._release(below);
      } else {
        controller._drive(below, animation);
      }
    }
  }

  /// 与 `TransitionRoute._updateSecondaryAnimation` 的条件一致。
  static bool _frameworkDrives(Route<dynamic> below, Route<dynamic> above) {
    if (below is! TransitionRoute<dynamic> || above is! TransitionRoute<dynamic>) {
      return false;
    }
    return below.canTransitionTo(above) && above.canTransitionFrom(below);
  }
}
