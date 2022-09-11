import 'dart:async';
import 'package:flutter/widgets.dart';
import 'orchestrator.dart';

class ObxElement = StatelessElement with StatelessObserverComponent;

/// A StatelessWidget than can listen reactive changes.
///
/// The [RxWidget] is the base for all reactive widgets
/// See also:
/// - [Obx]
/// - [Obc]
/// - [ObxVal]
/// - [ObcVal]
abstract class RxWidget extends StatelessWidget {
  const RxWidget({Key? key}) : super(key: key);
  @override
  StatelessElement createElement() => ObxElement(this);
}

/// Component that can track changes in a reactive variable
mixin StatelessObserverComponent on StatelessElement {
  // TODO: check if the call the the updater is already on the remove callback
  List<Disposer>? disposers = <Disposer>[];

  void getUpdate() {
    if (disposers != null) {
      scheduleMicrotask(markNeedsBuild);
    }
  }

  @override
  Widget build() {
    // TODO: avoid adding again after first build
    return Orchestrator.append(
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

/// A StatelessWidget that can rebuild and dispose it's data
///
/// The [RxValWidget] is the base for `Val` widgets
/// See also:
/// - [ObxVal]
/// - [ObcVal]
abstract class RxValWidget<T extends Object> extends RxWidget {
  const RxValWidget({Key? key, this.disposer}) : super(key: key);
  final Disposer? disposer;
  @override
  StatelessElement createElement() =>
      disposer == null ? ObxElement(this) : ObxElement(this)
        ..disposers!.add(disposer!);
}

/// The simplest reactive widget
///
/// Just pass your [Rx] variable in the root scope of the callback to have it
/// automatically registered for changes.
///
/// See also:
/// - [Obx]
/// - [Obc]
/// - [ObxVal]
/// - [ObcVal]
///
/// ```dart
/// final name = Rx("Say my name");
/// Obx(() => Text( name() )),... ;
/// ```
class Obx extends RxWidget {
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
///    ObxVal((data) => Switch(
///      value: data.value,
///      onChanged: (flag) => data.value = flag,
///    ),
///    false.obs,
///   ),
/// ```
class ObxVal<T extends Object> extends RxValWidget {
  final Widget Function(T) builder;
  final T data;

  const ObxVal(this.builder, this.data, {super.disposer, Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) => builder(data);
}

/// The simplest reactive widget that provides context
///
/// Similar to [Obx] but provides the context.
/// See also:
/// - [Obx]
/// - [Obc]
/// - [ObxVal]
/// - [ObcVal]
///
/// Just pass your [Rx] variable in the root scope of the callback to have it
/// automatically registered for changes.
///
/// ```dart
/// final name = Rx("Say my name");
/// Obc((BuildContext context) => Text( name() )),... ;
/// ```
class Obc extends RxWidget {
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
///    ObcVal((context, data) => Switch(
///      value: data.value,
///      onChanged: (flag) => data.value = flag,
///    ),
///    false.obs,
///   ),
/// ```
class ObcVal<T extends Object> extends RxValWidget {
  final Widget Function(BuildContext, T) builder;
  final T data;

  const ObcVal(this.builder, this.data, {super.disposer, Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) => builder(context, data);
}
