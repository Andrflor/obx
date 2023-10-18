import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:obx/obx.dart';

void main() => runApp(const App());

class AppConfig {}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Localizations(
        delegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        locale: Locale('fr'),
        child: Container(),
      ),
    );
  }
}

class User {
  final String name;
  final int age;

  User({required this.name, required this.age});
}

abstract class Store {}

class UserStore extends Store {
  final user = Rx<User>();
}

sealed class ProfileState extends State {}
class ProfileSuccess extends ProfileState{
  final User user;

  ProfileSuccess({required this.user});
}
class ProfileLoading extends ProfileState{}
class ProfileError extends ProfileState{
  final String error;

  ProfileError({required this.error});
}


sealed class ProfileEvent extends Event {}

class ProfileCompositor extends Compositor<ProfileState, ProfileEvent> {

}


abstract class Event {}

@immutable
abstract class State {}

abstract class Intent extends Event implements Command {}

class Result<T, E extends Error> {
  final T? _data;
  final E? _error;

  Result.error(E error)
      : _error = error,
        _data = null;
  Result.ok(T data)
      : _error = null,
        _data = data;

  T get data => _data!;
  E get err => _error!;

  V match<V>({required V Function(T) onData, required V Function(E) onError}) =>
      _data == null ? onError(_error!) : onData(data);
}

typedef Response<T, E extends Error> = FutureOr<Result<T, E>>;

abstract interface class Command<T, E extends Error> {
  Response<T, E> excecute();
}

class Bloc<S extends State, E extends Event> {}

typedef EventHandler<E extends Event, S extends State> = S Function(
  E event,
);

class DuplicateEventHandlerException implements Exception {
  final String message;
  DuplicateEventHandlerException(this.message);
}

abstract class Compositor<S extends State, E extends Event> {
  Rx<E> createEvent() => Rx<E>.indistinct();

  late final _eventChannel = createEvent();
  final _childEventChannels = <Rx<E>>[];

  @mustCallSuper
  void dispose() {
    _eventChannel.close();
    for (final childEventChannel in _childEventChannels) {
      childEventChannel.close();
    }
  }

  void _consume(E e) => _eventChannel(e);

  @protected
  @nonVirtual
  void on<T extends E>({EventHandler<T, S>? handler,
      RxTransformer<T>? transformer, IntentEmmiter<T, S, I>? emiter, StateNotifier<>}) {
    if (_childEventChannels.any((e) => e is Rx<T>)) {
      throw DuplicateEventHandlerException(
          "Duplicate registration for event handler of type ${T.toString()}");
    }
    _childEventChannels.add(_eventChannel.pipe<T>((e) =>
        transformer == null ? e.whereType<T>() : transformer(e.whereType<T>()))
      ..listen( handler != null ? (v) => handler(v)));
  }
}

