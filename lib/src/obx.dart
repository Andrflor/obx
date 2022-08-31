import 'dart:async';
import 'package:flutter/widgets.dart';
import 'notifier.dart';

T observe<T>(T Function() builder) => Notifier.instance.observe(builder);

class ObxElement = StatelessElement with StatelessObserverComponent;

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
    disposers!.clear();
    disposers = null;
  }
}

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
  final Widget Function() builder;

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

class Obc extends ObxWidget {
  final WidgetBuilder builder;

  const Obc(this.builder, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) => builder(context);
}

class ObcValue<T extends Object> extends ObxWidget {
  final Widget Function(BuildContext, T) builder;
  final T data;

  const ObcValue(this.builder, this.data, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) => builder(context, data);
}
