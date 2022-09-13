part of '../../orchestrator.dart';

class RxSubscription<T> implements StreamSubscription<T> {
  Rx<T>? _parent;
  Function(T data)? _onData;
  Function(Object error, [StackTrace? trace])? _onError;
  void Function()? _onDone;
  bool _paused = false;

  RxSubscription(Rx<T> parent,
      {Function(T data)? onData,
      void Function()? onDone,
      Function(Object error, [StackTrace? trace])? onError})
      : _parent = parent,
        _onData = onData,
        _onDone = onDone,
        _onError = onError {
    resume();
  }

  @override
  Future<E> asFuture<E>([E? futureValue]) {
    final completer = Completer<E>();
    onDone(() => completer.complete(futureValue as E));
    onError((Object error, [StackTrace? trace]) {
      completer.completeError(error, trace);
      cancel();
    });
    return completer.future;
  }

  @override
  Future<void> cancel() async {
    if (!_paused && _parent != null) {
      if (_onData != null) {
        _parent!._removeListener(_onData!);
      }
      if (_onDone != null) {
        _parent!._addDisposeListener(_onDone!);
      }
      if (_onError != null) {
        _parent!._addErrorListener(_onError!);
      }
      _parent = null;
    }
  }

  @override
  bool get isPaused => _paused;

  @override
  void onData(Function(T data)? handleData) {
    if (_onData != null && !_paused) {
      _parent?._removeListener(_onData!);
    }
    _onData = handleData;
    if (_onData != null) {
      _parent?._addListener(_onData!);
    }
  }

  @override
  void onDone(void Function()? handleDone) {
    if (_onDone != null && !_paused) {
      _parent?._removeDisposeListener(_onDone!);
    }
    _onDone = handleDone;
    if (_onDone != null) {
      _parent?._addDisposeListener(_onDone!);
    }
  }

  @override
  void onError(Function? handleError) {
    if (_onError != null && !_paused) {
      _parent?._removeErrorListener(_onError!);
    }
    _onError = handleError as Function(Object, [StackTrace?]);
    if (_onError != null) {
      _parent?._addErrorListener(_onError!);
    }
  }

  /// Like stream pause but elements won't be buffered
  @override
  void pause([Future<void>? resumeSignal]) {
    _paused = true;
    if (_parent != null) {
      if (_onData != null) {
        _parent!._removeListener(_onData!);
      }
      if (_onDone != null) {
        _parent!._removeDisposeListener(_onDone!);
      }
      if (_onError != null) {
        _parent!._removeErrorListener(_onError!);
      }
    }
    resumeSignal?.then((_) => resume());
  }

  @override
  void resume() {
    _paused = false;
    if (_parent != null) {
      if (_onData != null) {
        _parent!._addListener(_onData!);
      }
      if (_onDone != null) {
        _parent!._addDisposeListener(_onDone!);
      }
      if (_onError != null) {
        _parent!._addErrorListener(_onError!);
      }
    }
  }
}

class DebounceSubscription<T> implements StreamSubscription<T> {
  final StreamSubscription<T> _parent;
  DebounceSubscription(this._parent);

  @override
  Future<E> asFuture<E>([E? futureValue]) => _parent.asFuture(futureValue);

  @override
  Future<void> cancel() => _parent.cancel();

  @override
  bool get isPaused => _parent.isPaused;
  @override
  void onData(void Function(T data)? handleData) {
    // TODO: implement onData
  }

  @override
  void onDone(void Function()? handleDone) => _parent.onDone(handleDone);

  @override
  void onError(Function? handleError) {
    // TODO: implement onError
  }

  @override
  void pause([Future<void>? resumeSignal]) => _parent.pause(resumeSignal);

  @override
  void resume() => _parent.resume();
}

class OnceSubscription<T> extends StreamSubscription<T> {
  final StreamSubscription<T> _parent;
  OnceSubscription(this._parent);

  @override
  Future<E> asFuture<E>([E? futureValue]) => _parent.asFuture(futureValue);

  @override
  Future<void> cancel() => _parent.cancel();

  @override
  bool get isPaused => _parent.isPaused;
  @override
  void onData(void Function(T data)? handleData) {
    // TODO: implement onData
  }

  @override
  void onDone(void Function()? handleDone) => _parent.onDone(handleDone);

  @override
  void onError(Function? handleError) {
    // TODO: implement onError
  }

  @override
  void pause([Future<void>? resumeSignal]) => _parent.pause(resumeSignal);

  @override
  void resume() => _parent.resume();
}

class IntervalSubscription<T> implements StreamSubscription<T> {
  final StreamSubscription<T> _parent;
  IntervalSubscription(this._parent);

  @override
  Future<E> asFuture<E>([E? futureValue]) => _parent.asFuture(futureValue);

  @override
  Future<void> cancel() => _parent.cancel();

  @override
  bool get isPaused => _parent.isPaused;
  @override
  void onData(void Function(T data)? handleData) {
    // TODO: implement onData
  }

  @override
  void onDone(void Function()? handleDone) => _parent.onDone(handleDone);

  @override
  void onError(Function? handleError) {
    // TODO: implement onError
  }

  @override
  void pause([Future<void>? resumeSignal]) => _parent.pause(resumeSignal);

  @override
  void resume() => _parent.resume();
}
