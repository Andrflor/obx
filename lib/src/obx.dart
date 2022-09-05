import 'dart:async';
import 'package:flutter/widgets.dart';
import 'notifier.dart';

class ObxElement = StatelessElement with StatelessObserverComponent;

/// A StatelessWidget than can listen reactive changes.
///
/// The [ObxWidget] is the base for all reactive widgets
/// See also:
/// - [Obx]
/// - [Obc]
/// - [ObxValue]
/// - [ObcValue]
abstract class ObxWidget extends StatelessWidget {
  /// Initializes [key] for subclasses.
  const ObxWidget({Key? key}) : super(key: key);
  @override
  StatelessElement createElement() => ObxElement(this);
}

/// Component that can track changes in a reactive variable
mixin StatelessObserverComponent on StatelessElement {
  List<Disposer>? disposers = <Disposer>[];

  void getUpdate() {
    if (disposers != null) {
      scheduleMicrotask(markNeedsBuild);
    }
  }

  @override
  Widget build() {
    return Notifier.append(
        NotifyData(disposers: disposers!, updater: getUpdate), super.build);
  }

  @override
  void unmount() {
    super.unmount();
    for (final disposer in disposers!) {
      disposer();
    }
    disposers!.clear();
    disposers = null;
  }
}

/// The simplest reactive widget
///
/// Just pass your [Rx] variable in the root scope of the callback to have it
/// automatically registered for changes.
///
/// See also:
/// - [Obx]
/// - [Obc]
/// - [ObxValue]
/// - [ObcValue]
///
/// ```dart
/// final name = Rx("Say my name");
/// Obx(() => Text( name() )),... ;
/// ```
class Obx extends ObxWidget {
  final Widget Function() builder;

  const Obx(this.builder, {super.key});

  @override
  Widget build(BuildContext context) {
    return builder();
  }
}

/// Reactive component that manages local state
///
/// Similar to [Obx], but manages a local state.
/// Pass the initial data in constructor.
/// This can be used to scrope a controller.
/// Also useful for simple local states, like toggles, visibility, themes,
/// button states, etc.
/// Example:
/// ```dart
///    ObxValue((data) => Switch(
///      value: data.value,
///      onChanged: (flag) => data.value = flag,
///    ),
///    false.obs,
///   ),
/// ```
class ObxValue<T extends Object> extends ObxWidget {
  final Widget Function(T) builder;
  final T data;

  const ObxValue(this.builder, this.data, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) => builder(data);
}

/// The simplest reactive widget that provides context
///
/// Similar to [Obx] but provides the context.
/// See also:
/// - [Obx]
/// - [Obc]
/// - [ObxValue]
/// - [ObcValue]
///
/// Just pass your [Rx] variable in the root scope of the callback to have it
/// automatically registered for changes.
///
/// ```dart
/// final name = Rx("Say my name");
/// Obc((BuildContext context) => Text( name() )),... ;
/// ```
class Obc extends ObxWidget {
  final WidgetBuilder builder;

  const Obc(this.builder, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) => builder(context);
}

/// Reactive component that manages local state and provide context
///
/// Similar to [Obc], but manages a local state.
/// Pass the initial data in constructor.
/// This can be used to scrope a controller.
/// Also useful for simple local states, like toggles, visibility, themes,
/// button states, etc.
/// Example:
/// ```dart
///    ObcValue((context, data) => Switch(
///      value: data.value,
///      onChanged: (flag) => data.value = flag,
///    ),
///    false.obs,
///   ),
/// ```
class ObcValue<T extends Object> extends ObxWidget {
  final Widget Function(BuildContext, T) builder;
  final T data;

  const ObcValue(this.builder, this.data, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) => builder(context, data);
}
