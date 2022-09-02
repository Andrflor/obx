import 'dart:async';

import 'package:flutter/foundation.dart';

import './rx/rx_impl/rx_mixins.dart';
import '../obx.dart';
import 'notifier.dart';

/// Observes the results of any combinaison of [Rx] variables
///
/// This function is the refined state(less) control by excellence
/// You can call it with any closure containing any combinaison of [Rx]
/// The UI will rebuild only if the value of the result changes
///  Sample with [RxDouble] data1 and [RxDouble] data2:
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
/// This especially pratical to make getters
///
/// With complex structures you may endup with [observe] inside [observe]
/// Again, it has zero cost and you should feel free to do so
///
/// You may have a lot of [Rx] updating at the same time
/// Or even [Rx] updating way more often that once a frame
/// [observe] will make sure that your closure is evaluated only when needed
///
/// Since you give a closure, you may want to update [Rx] values inside it
/// This is generaly a bad practice but you can still try it
/// [obsreve] will prevent most infinite loop sceniarios
/// Be aware that re-building an [Obx] requires to call [obsreve] again
/// So you may end up with those changes done twice
/// This is the reason why i wouldn't recommend it
T observe<T>(T Function() builder) {
  return Notifier.inBuild ? Notifier.instance.observe(builder) : builder();
}

// TODO: make ever for properly
// TODO: fix obsrerve avoid infinite loop when closure update the values
// TODO: and the UI does not refresh

// TODO: make documentation for this function

/// Run a calback each time the observable [Object] changes
///
/// Takes an observable parameter that can be either
/// [Rx<T>] or [Stream<T>] or [ValueListenable<T>] or [T Function()]
/// [ever] provides an harmonized interface for all of those types
///
/// Passing a [T Function()] is practicaly usefull
/// Like [observe] the callback will fire only when the result changes
/// Samples with [RxDouble] data1 and [RxDouble] data2:
/// ever(data1, (bool value) => // Some work here);
/// ever(data2, someBooleanHandler);
/// ever(
///     () => data1.toStringAsFixed(0) == data2.toStringAsFixed(0)
///         ? "Equals"
///         : "Different",
///     someStringHandler);
///
/// Since [observe] is zero cost ouside a proper build context
/// We can also do other things like:
/// bool get equals => observe(() => data1 == data2);
/// void displayOnEquals(bool equality) {
///   if (equality) {
///      print("I've got an equality");
///   }
/// }
/// ever(() => equals, displayEqual);
///
/// [ever] is a reactive callback handler
/// Like [observe] it will only evaluate your closure when really needed
/// Used with [Rx<T>], [Stream<T>] or [ValueListenable<T>]
/// It simply acts a stream listener
StreamSubscription<T> ever<T>(
  Object observable,
  Function(T value) onData, {
  StreamFilter<T>? filter,
  void Function()? onDone,
  Function? onError,
  bool? cancelOnError,
  // TODO: implements distinct
  bool forceDistinct = false,
}) {
  if (observable is Function) {
    if (observable is T Function()) {
      return Notifier.instance.listen(observable).listen(
            onData,
            onDone: onDone,
            cancelOnError: cancelOnError,
            onError: onError,
            filter: filter,
          );
    }
    observable = observable();
  }
  if (observable is Rx<T>) {
    return observable.listen(
      onData,
      onDone: onDone,
      cancelOnError: cancelOnError,
      onError: onError,
      filter: filter,
    );
  }
  if (observable is Stream<T>) {
    return (filter == null ? observable : filter(observable)).listen(
      onData,
      onDone: onDone,
      cancelOnError: cancelOnError ?? false,
      onError: onError,
    );
  }
  if (observable is ValueListenable<T>) {
    // TODO: implements for value listnable
    // TODO: this should be using proper observable
  }
  // TODO: add assert for devellopement
  return EmptyStreamSubscription<T>();
}

// TODO: make documentation for this function
StreamSubscription<T> everNow<T>(
  Object observable,
  Function(T value) onData, {
  StreamFilter<T>? filter,
  Function? onError,
  void Function()? onDone,
  bool? cancelOnError,
  // TODO: implements distinct
  bool forceDistinct = false,
}) {
  if (observable is Function) {
    if (observable is T Function()) {
      return Notifier.instance.listen(observable).listenNow(
            onData,
            onDone: onDone,
            cancelOnError: cancelOnError,
            onError: onError,
            filter: filter,
          );
    }
    observable = observable();
  }
  if (observable is Rx<T>) {
    return observable.listenNow(
      onData,
      onDone: onDone,
      cancelOnError: cancelOnError,
      onError: onError,
      filter: filter,
    );
  }
  if (observable is Stream<T>) {
    return (filter == null ? observable : filter(observable)).listen(
      onData,
      onDone: onDone,
      cancelOnError: cancelOnError ?? false,
      onError: onError,
    );
  }
  if (observable is ValueListenable<T>) {
    // TODO: implements for value listnable
    // TODO: this should be using proper observable
  }
  // TODO: add assert for devellopement
  return EmptyStreamSubscription<T>();
}

// TODO: implement Debounce, Once, Iterval, Every, Skip, Take
// TODO: implement DebounceNow, OnceNow, ItervalNow, EveryNow, SkipNow, TakeNow
