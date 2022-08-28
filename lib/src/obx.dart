import 'dart:async';
import 'package:flutter/widgets.dart';
import 'notifier.dart';

class ObxElement = StatelessElement with StatelessObserverComponent;

class Obc extends ObxWidget {
  final WidgetBuilder builder;

  const Obc(this.builder, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) => builder(context);
}

/// A StatelessWidget than can listen reactive changes.
abstract class ObxWidget extends StatelessWidget {
  /// Initializes [key] for subclasses.
  const ObxWidget({Key? key}) : super(key: key);
  @override
  StatelessElement createElement() => ObxElement(this);
}

/// a Component that can track changes in a reactive variable
mixin StatelessObserverComponent on StatelessElement {
  List<Disposer>? disposers = <Disposer>[];

  void getUpdate() {
    if (disposers != null) {
      scheduleMicrotask(markNeedsBuild);
    }
  }

  @override
  Widget build() {
    return Notifier.instance.append(
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

typedef WidgetCallback = Widget Function();

/// The [ObxWidget] is the base for all GetX reactive widgets
///
/// See also:
/// - [Obx]
/// - [ObxValue]

/// The simplest reactive widget in GetX.
///
/// Just pass your Rx variable in the root scope of the callback to have it
/// automatically registered for changes.
///
/// final _name = "GetX".obs;
/// Obx(() => Text( _name.value )),... ;
class Obx extends ObxWidget {
  final WidgetCallback builder;

  const Obx(this.builder);

  @override
  Widget build(BuildContext context) {
    return builder();
  }
}

/// Similar to Obx, but manages a local state.
/// Pass the initial data in constructor.
/// Useful for simple local states, like toggles, visibility, themes,
/// button states, etc.
///  Sample:
///    ObxValue((data) => Switch(
///      value: data.value,
///      onChanged: (flag) => data.value = flag,
///    ),
///    false.obs,
///   ),
// class ObxValue<T extends RxInteface> extends ObxWidget {

class ObxValue<T extends Object> extends ObxWidget {
  final Widget Function(T) builder;
  final T data;

  const ObxValue(this.builder, this.data, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) => builder(data);
}
