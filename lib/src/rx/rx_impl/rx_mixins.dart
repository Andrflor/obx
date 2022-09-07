import 'dart:async';
import 'package:flutter/foundation.dart';

import '../../functions.dart';
import '../../notifier.dart';
import 'rx_impl.dart';
import 'rx_types.dart';

/// This mixin allow to observe object descriptions
mixin Descriptible<T> on ValueListenable<T> {
  @override
  String toString() => value.toString();

  /// Returns the json representation of `value`.
  dynamic toJson() {
    try {
      return (value as dynamic).toJson();
    } catch (e) {
      throw FlutterError('''${value.runtimeType} as no method [toJson]''');
    }
  }
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

  // This value will only be set if it matches
  @override
  set value(T newValue) {
    if (!isDistinct || this != newValue) {
      trigger(newValue);
    }
  }
}

abstract class Emitting {
  void emit();
}

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

  @override
  @mustCallSuper
  void dispose() {
    detatch();
    if (_controller != null) {
      _controller?.close();
    }
    super.dispose();
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
    onData(value);
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
        _controller = null;
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

  StreamController<T> get _subject {
    if (_controller == null) {
      _initController();
    }
    return _controller!;
  }

  /// This can be used if you want to add an error to the stream
  void addError(Object error, [StackTrace? stackTrace]) {
    _subject.addError(error, stackTrace);
  }
}

mixin StreamBindable<T> on StreamCapable<T> {
  /// Binds an existing `Stream<T>` to this Rx<T> to keep the values in sync.
  ///
  /// You can bind multiple sources to update the value.
  /// Once a stream closes the subscription will cancel itself
  /// You can also cancel the sub with the provided callback
  Disposer bindStream(Stream<T> stream) {
    final sub = stream.listen((e) {
      value = e;
    }, cancelOnError: false);
    disposers?.add(sub.cancel);
    final clean = () {
      disposers?.remove(sub.cancel);
      sub.cancel();
    };
    sub.onDone(clean);
    return clean;
  }

  /// Binding to this [Rx<T>] to any other [Rx<T>]
  ///
  /// Binds an existing [ValueListenable<T>] this might be a [ValueNotifier<T>]
  /// Keeping this [Rx<T>] values in sync.
  /// You can bind multiple sources to update the value.
  /// It's impossible to know when a [ValueListenable] is done
  /// You will have to clean it up yourself
  /// For that you can call the provided [Disposer]
  Disposer bindRx(StreamCapable<T> rx, [StreamFilter<T>? filter]) {
    final sub = rx.listen(
      (e) {
        value = e;
      },
    );
    disposers?.add(sub.cancel);
    final clean = () {
      disposers?.remove(sub.cancel);
      sub.cancel();
    };
    sub.onDone(clean);
    return clean;
  }

  /// Binding to any listener with callback
  ///
  /// Binds an existing [ValueListenable<T>] this might be a [ValueNotifier<T>]
  /// Keeping this [Rx<T>] values in sync.
  /// You can bind multiple sources to update the value.
  /// It's impossible to know when a [ValueListenable] is done
  /// You will have to clean it up yourself
  /// For that you can call the provided [Disposer]
  Disposer bindValueListenable(
    ValueListenable<T> listenable,
  ) {
    final closure = () {
      value = listenable.value;
    };
    listenable.addListener(closure);
    final cancel = () => listenable.removeListener(closure);
    disposers?.add(cancel);

    return () {
      disposers?.remove(cancel);
      cancel();
    };
  }

  /// Binding to any listener with provided `onEvent` callback
  ///
  /// Binds an existing [Listenable]
  /// Keeping this [Rx<T>] values in sync.
  /// You can bind multiple sources to update the value.
  /// It's impossible to know when a [Listenable] is done
  /// You will have to clean it up yourself
  /// For that you can call the provided [Disposer]
  Disposer bindListenable(Listenable listenable,
      {required T Function() onEvent}) {
    final closure = () => value = onEvent();
    listenable.addListener(closure);
    final cancel = () => listenable.removeListener(closure);
    disposers?.add(cancel);

    return () {
      disposers?.remove(cancel);
      cancel();
    };
  }
}

/// This is used to pass private fields to other files
extension StreamCapableProtectedAccess<T> on StreamCapable<T> {
  StreamController<T>? get streamController => _controller;
}

/// This is used to pass private fields to other files
extension BroadCastStreamCapableProtectedAccess<T>
    on BroadCastStreamCapable<T> {
  StreamController<T> get subject => _subject;
  StreamController<T>? get streamController => _controller;
}

/// This allow [ever] to run properly even when the user input the wrong data
/// In debug mode assert check will advert the developper
class EmptyStreamSubscription<T> extends StreamSubscription<T> {
  @override
  Future<Never> asFuture<Never>([Never? futureValue]) => throw FlutterError(
      '''You tried to call asFuture on an EmptyStreamSubscription
This should never append, make sure you respect contract when calling [ever]''');

  @override
  Future<void> cancel() async {}
  @override
  bool get isPaused => true;
  @override
  void onData(void Function(T data)? handleData) {}
  @override
  void onDone(void Function()? handleDone) {}
  @override
  void onError(Function? handleError) {}
  @override
  void pause([Future<void>? resumeSignal]) {}
  @override
  void resume() {}
}
