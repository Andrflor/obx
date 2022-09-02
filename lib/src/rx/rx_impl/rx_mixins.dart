import 'dart:async';
import 'package:flutter/foundation.dart';

import '../../functions.dart';
import '../../notifier.dart';

/// This mixin allow to observe object descriptions
mixin Descriptible<T> on ValueListenable<T> {
  @override
  String toString() => observe(() => value.toString());

  /// Returns the json representation of `value`.
  dynamic toJson() => observe(() {
        try {
          return (value as dynamic).toJson();
        } catch (e) {
          throw FlutterError('''${value.runtimeType} as no method [toJson]''');
        }
      });
}

/// This is used to maked RxImpl distinctive or Not on need
mixin Distinguishable<T> on Actionable<T>, StreamCapable<T> {
  bool get isDistinct => false;

  /// Trigger update with a new value
  /// Update the value, force notify listeners and update Widgets
  @override
  void trigger(T v) {
    _controller?.add(v);
    super.trigger(v);
  }

  /// Called without a value it will refesh the ui
  /// Called with a value it will refresh the ui and update value
  @override
  void refresh([T? v]) {
    if (v != null) {
      value = v;
    }
    super.refresh();
  }

  // This value will only be set if it matches
  @override
  set value(T newValue) {
    if (!isDistinct || static != newValue) {
      trigger(newValue);
    }
  }
}

// This mixin is used to provide Actions to call
mixin Actionable<T> on Reactive<T> {
  T? call([T? v]) {
    if (v != null) {
      value = v;
    }
    return value;
  }

  /// Trigger update with a new value
  /// Update the value, force notify listeners and update Widgets
  void trigger(T v) {
    static = v;
    notify();
  }

  /// Trigger update with current value
  /// Force notify listeners and update Widgets
  void emit() {
    if (hasValue) {
      trigger(static);
    }
  }

  /// Silent update
  /// Update value without updating widgets and listeners
  /// This means that piped object won't recieve the update
  void silent(T v) {
    static = v;
  }

  /// Called without a value it will refesh the ui
  /// Called with a value it will refresh the ui and update value
  void refresh([T? v]) {
    if (v != null) {
      static = v;
    }
    notify();
  }
}

typedef Worker<T> = StreamSubscription<T> Function(void Function(T)?,
    {bool? cancelOnError, void Function()? onDone, Function? onError});

typedef StreamTransformation<S, T> = Stream<S> Function(Stream<T> stream);
typedef StreamFilter<T> = StreamTransformation<T, T>;

mixin StreamCapable<T> on DisposersTrackable<T> {
  StreamController<T>? _controller;

  Stream<T>? _stream;

  Stream<T> get stream {
    if (_controller == null) {
      _controller = StreamController<T>();
      _controller!.onCancel = dispose;
      _stream = _controller!.stream;
    }
    return _stream!;
  }

  /// This method allow to remove all incoming subs
  /// This will detatched this obs from stream listenable other piped obs
  void detatch() {
    for (Disposer disposer in disposers ?? []) {
      disposer();
    }
    disposers?.clear();
  }

  /// Allow to listen to the observable
  StreamSubscription<T> listen(
    void Function(T e) onData, {
    Function? onError,
    void Function()? onDone,
    StreamFilter<T>? filter,
    bool? cancelOnError,
  }) {
    return (filter == null ? stream : filter(stream)).listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError ?? false,
    );
  }

  /// Same as listen but is also called now
  StreamSubscription<T> listenNow(
    void Function(T e) onData, {
    Function? onError,
    void Function()? onDone,
    StreamFilter<T>? filter,
    bool? cancelOnError,
  }) {
    if (hasValue) {
      onData.call(static);
    }
    return listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
      filter: filter,
    );
  }
}

/// This mixin holds stream
mixin BroadCastStreamCapable<T> on StreamCapable<T> {
  void _initController() {
    _controller = StreamController<T>.broadcast();
    _controller!.onCancel = () {
      if (!_controller!.hasListener) {
        _controller?.close();
      }
    };
    _stream = _controller!.stream;
  }

  @override
  Stream<T> get stream {
    if (_controller == null) {
      _initController();
      _stream = _controller!.stream;
    }
    return _stream!;
  }

  StreamController<T> get subject {
    if (_controller == null) {
      _initController();
    }
    return _controller!;
  }

  @override
  @mustCallSuper
  void dispose() {
    if (_controller != null) {
      detatch();
      _controller?.close();
    }
    super.dispose();
  }

  /// This can be used if you want to add an error to the stream
  void addError(Object error, [StackTrace? stackTrace]) {
    subject.addError(error, stackTrace);
  }
}

mixin StreamBindable<T> on StreamCapable<T> {
  /// Binds an existing `Stream<T>` to this Rx<T> to keep the values in sync.
  /// You can bind multiple sources to update the value.
  /// Once a stream closes the subscription will cancel itself
  /// You can also cancel the sub with the provided callback
  Disposer bindStream(Stream<T> stream) {
    final sub = stream.listen((e) {
      value = e;
    }, cancelOnError: false);
    disposers?.add(sub.cancel);
    // ignore: prefer_function_declarations_over_variables
    final clean = () {
      disposers?.remove(sub.cancel);
      sub.cancel();
    };
    sub.onDone(clean);
    return clean;
  }

  Disposer bindRx(StreamCapable<T> rx, [Stream<T>? stream]) {
    final sub = stream == null
        ? rx.listen((e) {
            value = e;
          })
        : stream.listen(
            (e) {
              value = e;
            },
            cancelOnError: false,
            // TODO: implement some cleanup
            // onDone: rx._checkClean,
          );
    disposers?.add(sub.cancel);
    // ignore: prefer_function_declarations_over_variables
    final clean = () {
      disposers?.remove(sub.cancel);
      sub.cancel();
    };
    sub.onDone(clean);
    return clean;
  }

  /// TODO: split bindListnable and bindValueListenable
  /// Binding to any listener with callback
  /// Binds an existing `ValueListenable<T>` this might be a `ValueNotifier<T>`
  /// Keeping this Rx<T> values in sync.
  /// You can bind multiple sources to update the value.
  /// It's impossible to know when a ValueListenable is Done
  /// You will have to clean it up yourself
  /// For that you can call the provided callback
  Disposer bindListenable(Listenable listenable, [T Function()? callback]) {
    Disposer? closure = callback == null
        ? null
        : () {
            value = callback();
          };

    if (listenable is ValueListenable<T> && closure == null) {
      // ignore: prefer_function_declarations_over_variables
      closure = () {
        value = listenable.value;
      };
    }
    if (closure == null) return () {};
    listenable.addListener(closure);
    // ignore: prefer_function_declarations_over_variables
    final cancel = () => listenable.removeListener(closure!);
    disposers?.add(cancel);

    return () {
      disposers?.remove(cancel);
      cancel();
    };
  }
}
