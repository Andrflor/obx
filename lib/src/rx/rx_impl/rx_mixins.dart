import 'dart:async';
import 'package:flutter/foundation.dart';

import '../../orchestrator.dart';
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
  Disposer listen(
    void Function(T e) onData, {
    StreamFilter<T>? filter,
  }) {
    if (filter == null) {
      listener() => onData(staticOrNull as T);
      addListener(listener);
      return () => removeListener(listener);
    }
    return filter(stream)
        .listen(
          onData,
          cancelOnError: false,
        )
        .cancel;
  }

  /// Same as listen but is also called now
  Disposer listenNow(
    void Function(T e) onData, {
    StreamFilter<T>? filter,
  }) {
    onData(staticOrNull as T);
    return listen(
      onData,
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
    clean() {
      disposers?.remove(sub.cancel);
      sub.cancel();
    }

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
      filter: filter,
    );
    disposers?.add(sub);
    clean() {
      disposers?.remove(sub);
      sub();
    }

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
    closure() {
      value = listenable.value;
    }

    listenable.addListener(closure);
    cancel() => listenable.removeListener(closure);
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
    closure() => value = onEvent();
    listenable.addListener(closure);
    cancel() => listenable.removeListener(closure);
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
