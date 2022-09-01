import 'dart:async';

import './rx/rx_impl/rx_mixins.dart';
import '../obx.dart';
import 'notifier.dart';

/// Observes the results of any combinaison of Rx variables
///
/// This function is the refined state(less) control by excellence
/// You can call it with any closure containing any combinaison of Rx
/// The UI will rebuild only if the value of the result changes
///  Sample with RxDouble data1 and RxDouble data2:
///     Obx(
///       () => Text(observe(() =>
///           data2.toStringAsFixed(0) == data2.toStringAsFixed(0)
///               ? "Equals"
///               : "Different")),
///     ),
/// Will only rebuild when the result String ("Equals" or "Different") changes
///
/// [observe] is smart, it knows where it's called
/// In fact, you can call it anywhere
/// Furthermore calling it outside of a reactive widget has zero cost
/// This especially pratical for getters
///
/// With complex structures you may endup with [observe] inside [observe]
/// Again, it has zero cost and you should feel free to do so
///
/// You may have a lot of observables updating at the same time
/// Or even observables updating way more often that once a frame
/// [observe] will make sure that your closure is evaluated only when needed
///
/// Since you give a closure, you may want to update Rx values inside it
/// This is generaly a bad practice but you can still do it
/// [obsreve] will prevent any infinite loop
/// Be aware that building requires to call [obsreve] again
/// So you may end up with those changes done twice
/// This is the reason why i wouldn't recommend it
T observe<T>(T Function() builder) {
  return Notifier.inBuild ? Notifier.instance.observe(builder) : builder();
}

StreamSubscription<T> ever<T>(
  Object builder,
  Function(T value) onData, {
  StreamFilter<T>? filter,
  Function? onError,
  void Function()? onDone,
  bool? cancelOnError,
}) {
  if (builder is Function) {
    if (builder is T Function()) {
      return Notifier.instance.listen(builder).listen(
            onData,
            onDone: onDone,
            cancelOnError: cancelOnError,
            onError: onError,
            filter: filter,
          );
    }
    builder = builder();
  }
  if (builder is Rx<T>) {
    return builder.listen(
      onData,
      onDone: onDone,
      cancelOnError: cancelOnError,
      onError: onError,
      filter: filter,
    );
  }
  if (builder is Stream<T>) {
    return (filter == null ? builder : filter(builder)).listen(
      onData,
      onDone: onDone,
      cancelOnError: cancelOnError ?? false,
      onError: onError,
    );
  }
  // TODO: add assert for devellopement
  return EmptyStreamSubscription<T>();
}

StreamSubscription<T> everNow<T>(
  Object builder,
  Function(T value) onData, {
  StreamFilter<T>? filter,
  Function? onError,
  void Function()? onDone,
  bool? cancelOnError,
}) {
  if (builder is Function) {
    if (builder is T Function()) {
      return Notifier.instance.listen(builder).listenNow(
            onData,
            onDone: onDone,
            cancelOnError: cancelOnError,
            onError: onError,
            filter: filter,
          );
    }
    builder = builder();
  }
  if (builder is Rx<T>) {
    return builder.listenNow(
      onData,
      onDone: onDone,
      cancelOnError: cancelOnError,
      onError: onError,
      filter: filter,
    );
  }
  if (builder is Stream<T>) {
    return (filter == null ? builder : filter(builder)).listen(
      onData,
      onDone: onDone,
      cancelOnError: cancelOnError ?? false,
      onError: onError,
    );
  }
  // TODO: add assert for devellopement
  return EmptyStreamSubscription<T>();
}
