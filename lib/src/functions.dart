library obx;

import 'dart:async';

import 'package:flutter/foundation.dart';

import './rx/rx_impl/rx_types.dart';
import './rx/rx_impl/rx_core.dart';
import 'debouncer.dart';
import 'orchestrator.dart';

/// Assert error for wrong type usage in [ever] functions
bool _debugAssertObservableType<S>(S value, Type inner, String name) {
  assert(() {
    throw FlutterError(
        '''The type ${value.runtimeType} is not respecting the type constraints in [$name]
it should [Rx<$inner>], [Stream<$inner>] or [ValueListenable<$inner>] or [$inner Function()]
or you may have wrongly typed $inner in the onData [Function($inner value)] function''');
  }());
  return true;
}

/// Observes the results of any combinaison of [Rx] variables
///
/// This function is the refined state(less) control by excellence
/// You can call it with any [T Function()] containing any combinaison of [Rx]
/// The UI will rebuild only if the value of the result changes
///  Example with [RxDouble] data1 and [RxDouble] data2:
/// ```dart
///     Obx(
///       () => Text(observe(() =>
///           data2.toStringAsFixed(0) == data2.toStringAsFixed(0)
///               ? "Equals"
///               : "Different")),
///     ),
/// ```
/// Will only rebuild when the result String ("Equals" or "Different") changes
///
/// [observe] is smart, it knows where it's called
/// In fact, you can call it anywhere
/// Furthermore calling it outside of a reactive widget has almost zero cost**
/// **The exact cost is a boolean check and an assignation
///
/// This is especially pratical to make getters
/// ```dart
/// String get equal => observe(() => data2.toStringAsFixed(0) == data2.toStringAsFixed(0)
///                                        ? "Equals"
///                                        : "Different"));
/// Obx(() => Text(equals));
/// ever(() => equals, print);
/// ```
/// With complex structures you may endup with [observe] inside [observe]
/// Again, it has almost zero cost and you should feel free to do so
///
/// More than one [Rx] from the combinaison may update at the same time
/// Or some or all [Rx] may update way more often that once a frame
/// [observe] will make sure that your function is evaluated only when needed
///
/// Since you give a combining fonction, you may want to update [Rx] values inside it
/// This is generaly a bad practice and you should not do it
/// [obsreve] will try to prevent most infinite loop sceniarios
/// Be aware that re-building an [Obx] requires to call [obsreve] again
/// So you may end up with those changes done twice
/// In some senarios you may even end up with uncatched inifite loops
/// That's why I would avoid it...
///
/// Under the hood is a simple [ValueListenable<T>] implementation
/// In fact all [Rx<T>] are [ValueListenable<T>]
T observe<T>(T Function() builder) {
  return Orchestrator.notObserving ? builder() : Orchestrator.observe(builder);
}

/// Run a calback each time the observable [Object] changes
///
/// Takes an observable parameter that can be either
/// [Rx<T>] or [Stream<T>] or [ValueListenable<T>] or [T Function()]
/// [ever] provides an harmonized interface for all of those types
/// onData is the [Function(T value)] callback to apply
/// You can also specify standard stream subscription parameters
/// onError, onDone, cancelOnError, if giving [Stream<T>] input
/// It will return a [Disposer]
///
/// By default [ever] will respect the distinct rule of the incoming observable
/// To enforce [ever] to be distinct you can use the enforceDistinct parameter
///
/// Passing a [T Function()] is practicaly usefull
/// Like [observe] the callback will fire only when the result changes
/// Examples with [RxDouble] data1 and [RxDouble] data2:
/// ```dart
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
/// ```
/// [ever] is a reactive callback handler
/// Like [observe] it will only evaluate your closure when really needed
/// Used with [Stream<T>]
/// It simply acts as a stream listener
///
/// When you use it with [Rx<T>] or [ValueListenable<T>]
/// It will not use stream but a lightweight listener implementation
/// It means that it's very fast and ressource efficient
///
/// The filter parameter is intended for advanced users
/// Used on [Rx] or [ValueListenable] it will lazy load a [StreamController]
/// It takes a [StreamFilter<T>] aka [Stream<T> Function(Stream<T>)]
/// It allows you to make any stream filtering operation
/// Example: (stream) => stream.skip(1).skipWhile(//someCondition).take(5)
Disposer ever<T>(
  Object observable,
  Function(T value) onData, {
  StreamFilter<T>? filter,
  void Function()? onDone,
  Function? onError,
  bool? cancelOnError,
  bool forceDistinct = false,
}) {
  if (observable is Rx<T>) {
    return (forceDistinct && !observable.isDistinct
            ? observable.distinct()
            : observable)
        .listen(
      onData,
      filter: filter,
    );
  }
  if (observable is T Function()) {
    return Orchestrator.fuse(observable).listen(
      onData,
      filter: filter,
    );
  }
  if (observable is Stream<T>) {
    observable = forceDistinct ? observable.distinct() : observable;
    return (filter == null ? observable : filter(observable))
        .listen(
          onData,
          onDone: onDone,
          cancelOnError: cancelOnError ?? false,
          onError: onError,
        )
        .cancel;
  }
  if (observable is ValueListenable<T>) {
    if (forceDistinct || filter != null) {
      return Rx.fromValueListenable(observable, distinct: forceDistinct).listen(
        onData,
        filter: filter,
      );
    }
    listener() {
      onData((observable as ValueListenable<T>).value);
    }

    observable.addListener(listener);
    return () => (observable as ValueListenable<T>).removeListener(listener);
  }

  assert(_debugAssertObservableType(observable, T, 'ever'));
  return () {};
}

// /// Runs a calback each time the observable [Object] changes and now
// ///
// /// Like the [ever] function but the callback will also fire now
// /// For complete docuementation see [ever]
// ///
// /// See also:
// /// - [onceNow]
// /// - [debounceNow]
// /// - [ever]
// Disposer everNow<T>(
//   Object observable,
//   Function(T value) onData, {
//   StreamFilter<T>? filter,
//   Function? onError,
//   void Function()? onDone,
//   bool? cancelOnError,
//   bool forceDistinct = false,
// }) {
//   if (observable is T Function()) {
//     return Orchestrator.fuse(observable).subNow(
//       onData,
//       filter: filter,
//     );
//   }
//   if (observable is Rx<T>) {
//     return (forceDistinct && !observable.isDistinct
//             ? observable.distinct()
//             : observable)
//         .subNow(
//       onData,
//       filter: filter,
//     );
//   }
//   if (observable is Stream<T>) {
//     observable = forceDistinct ? observable.distinct() : observable;
//     return (filter == null ? observable : filter(observable))
//         .listen(
//           onData,
//           onDone: onDone,
//           cancelOnError: cancelOnError ?? false,
//           onError: onError,
//         )
//         .cancel;
//   }
//   if (observable is ValueListenable<T>) {
//     if (forceDistinct || filter != null) {
//       return Rx.fromValueListenable(observable, distinct: forceDistinct).subNow(
//         onData,
//         filter: filter,
//       );
//     }
//     onData(observable.value);
//     listener() {
//       onData((observable as ValueListenable<T>).value);
//     }
// 
//     observable.addListener(listener);
//     return () => (observable as ValueListenable<T>).removeListener(listener);
//   }
// 
//   _debugAssertObservableType(observable, T, 'everNow');
//   return () {};
// }
// 
// // TODO: implem [everDiff] [onceDiff] [debounceDiff]
// // TODO: MAYBE implem [interval] [intervalNow] [intervalDiff]
// 
// void _debugAssertObservableType<S>(S value, Type inner, String name) {
//   assert(() {
//     throw FlutterError(
//         '''The type ${value.runtimeType} is not respecting the type constraints in [$name]
// it should [Rx<$inner>], [Stream<$inner>] or [ValueListenable<$inner>] or [$inner Function()]
// or you may have wrongly typed $inner in the onData [Function($inner value)] function''');
//   }());
// }
// 
// /// Runs a calback once the observable [Object] changes
// ///
// /// Like the [ever] function but the callback is only run once
// /// For complete docuementation see [ever]
// ///
// /// See also:
// /// - [ever]
// /// - [debounce]
// /// - [onceNow]
// Disposer once<T>(
//   Object observable,
//   Function(T value) onData, {
//   StreamFilter<T>? filter,
//   Function? onError,
//   void Function()? onDone,
//   bool? cancelOnError,
// }) =>
//     ever(
//       observable,
//       onData,
//       filter: filter,
//       onError: onError,
//       onDone: onDone,
//       cancelOnError: cancelOnError,
//     );
// 
// /// Runs a calback once the observable [Object] changes and now
// ///
// /// Like the [ever] function but the callback runs only once and now
// /// Like the [once] function but the callback also fires now
// /// For complete docuementation see [ever]
// ///
// /// See also:
// /// - [once]
// /// - [everNow]
// /// - [debounceNow]
// Disposer onceNow<T>(
//   Object observable,
//   Function(T value) onData, {
//   StreamFilter<T>? filter,
//   Function? onError,
//   void Function()? onDone,
//   bool? cancelOnError,
//   bool forceDistinct = false,
// }) =>
//     everNow(
//       observable,
//       onData,
//       filter: filter,
//       onError: onError,
//       onDone: onDone,
//       cancelOnError: cancelOnError,
//       forceDistinct: forceDistinct,
//     );
// 
// /// Runs a calback with debounce dalay when the observable [Object] changes
// ///
// /// Like the [ever] function but the callback has a debouncer
// /// This is convenient to prevent the user from blasting an API
// /// For complete docuementation see [ever]
// ///
// /// See also:
// /// - [ever]
// /// - [once]
// /// - [debounceNow]
// Disposer debounce<T>(
//   Object observable,
//   Function(T value) onData, {
//   StreamFilter<T>? filter,
//   Duration delay = const Duration(milliseconds: 800),
//   Function? onError,
//   void Function()? onDone,
//   bool? cancelOnError,
//   bool forceDistinct = false,
// }) {
//   final debouncer = Debouncer(delay: delay);
//   return ever(
//     observable,
//     (T value) {
//       debouncer(() {
//         onData(value);
//       });
//     },
//     filter: filter,
//     onError: onError,
//     onDone: onDone,
//     cancelOnError: cancelOnError,
//     forceDistinct: forceDistinct,
//   );
// }
// 
// /// Runs a calback with debounce dalay when observable [Object] changes and now
// ///
// /// Like the [ever] function but the callback has a debouncer
// /// Like the [debounce] function but the callback also fires now
// /// This is convenient to prevent the user from blasting an API
// /// For complete docuementation see [ever]
// ///
// /// See also:
// /// - [everNow]
// /// - [onceNow]
// /// - [debounce]
// Disposer debounceNow<T>(
//   Object observable,
//   Function(T value) onData, {
//   StreamFilter<T>? filter,
//   Duration delay = const Duration(milliseconds: 800),
//   Function? onError,
//   void Function()? onDone,
//   bool? cancelOnError,
//   bool forceDistinct = false,
// }) {
//   final debouncer = Debouncer(delay: delay);
//   return everNow(
//     observable,
//     (T value) {
//       debouncer(() {
//         onData(value);
//       });
//     },
//     filter: filter,
//     onError: onError,
//     onDone: onDone,
//     cancelOnError: cancelOnError,
//     forceDistinct: forceDistinct,
//   );
// }
