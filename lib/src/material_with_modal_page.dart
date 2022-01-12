import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';

/// A page that creates a material style [PageRoute].
///
/// {@macro flutter.material.materialRouteTransitionMixin}
///
/// By default, when the created route is replaced by another, the previous
/// route remains in memory. To free all the resources when this is not
/// necessary, set [maintainState] to false.
///
/// The `fullscreenDialog` property specifies whether the created route is a
/// fullscreen modal dialog. On iOS, those routes animate from the bottom to the
/// top rather than horizontally.
///
/// The type `T` specifies the return type of the route which can be supplied as
/// the route is popped from the stack via [Navigator.transitionDelegate] by
/// providing the optional `result` argument to the
/// [RouteTransitionRecord.markForPop] in the [TransitionDelegate.resolve].
///
/// See also:
///
///  * [MaterialWithModalPageRoute], which is the [PageRoute] version of this class
class MaterialWithModalPage<T> extends Page<T> {
  /// Creates a material page.
  const MaterialWithModalPage({
    required this.child,
    this.maintainState = true,
    this.fullscreenDialog = false,
    LocalKey? key,
    String? name,
    Object? arguments,
  }) : super(key: key, name: name, arguments: arguments);

  /// The content to be shown in the [Route] created by this page.
  final Widget child;

  /// {@macro flutter.widgets.modalRoute.maintainState}
  final bool maintainState;

  /// {@macro flutter.widgets.pageRoute.fullscreenDialog}
  final bool fullscreenDialog;

  @override
  Route<T> createRoute(BuildContext context) {
    return _PageBasedMaterialWithModalPageRoute<T>(page: this);
  }
}

// A page-based version of MaterialWithModalPageRoute.
//
// This route uses the builder from the page to build its content. This ensures
// the content is up to date after page updates.
class _PageBasedMaterialWithModalPageRoute<T> extends PageRoute<T> with MaterialRouteTransitionMixin<T> {
  _PageBasedMaterialWithModalPageRoute({
    required MaterialWithModalPage<T> page,
  }) : super(settings: page);

  ModalBottomSheetRoute? _nextModalRoute;

  @override
  bool canTransitionTo(TransitionRoute<dynamic> nextRoute) {
    // Don't perform outgoing animation if the next route is a fullscreen dialog.
    return (nextRoute is MaterialPageRoute && !nextRoute.fullscreenDialog) ||
        (nextRoute is CupertinoPageRoute && !nextRoute.fullscreenDialog) ||
        (nextRoute is MaterialWithModalsPageRoute && !nextRoute.fullscreenDialog) ||
        (nextRoute is ModalBottomSheetRoute);
  }

  @override
  void didChangeNext(Route? nextRoute) {
    if (nextRoute is ModalBottomSheetRoute) {
      _nextModalRoute = nextRoute;
    }

    super.didChangeNext(nextRoute);
  }

  @override
  void didPopNext(Route nextRoute) {
    super.didPopNext(nextRoute);
  }

  @override
  bool didPop(T? result) {
    _nextModalRoute = null;

    return super.didPop(result);
  }

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final PageTransitionsTheme theme = Theme.of(context).pageTransitionsTheme;

    if (_nextModalRoute != null) {
      if (!secondaryAnimation.isDismissed) {
        // Avoid default transition theme to animate when a new modal view is pushed
        final Animation<double> fakeSecondaryAnimation = Tween<double>(begin: 0, end: 0).animate(secondaryAnimation);

        final Widget defaultTransition = theme.buildTransitions<T>(
          this,
          context,
          animation,
          fakeSecondaryAnimation,
          child,
        );

        return _nextModalRoute!.getPreviousRouteTransition(
          context,
          secondaryAnimation,
          defaultTransition,
        );
      } else {
        _nextModalRoute = null;
      }
    }

    return theme.buildTransitions<T>(this, context, animation, secondaryAnimation, child);
  }

  MaterialWithModalPage<T> get _page => settings as MaterialWithModalPage<T>;

  @override
  Widget buildContent(BuildContext context) {
    return _page.child;
  }

  @override
  bool get maintainState => _page.maintainState;

  @override
  bool get fullscreenDialog => _page.fullscreenDialog;

  @override
  String get debugLabel => '${super.debugLabel}(${_page.name})';
}
