import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:obx/obx.dart';
import 'package:get/get.dart' as getx;

void main() => runApp(const App());

class AppConfig {}

class App extends StatelessWidget {
  const App({super.key});

  static final state = AppState();
  static final locale = Rx<Locale>(const Locale('en'));
  static final theme =
      Rx<ThemeData>(ThemeData(scaffoldBackgroundColor: Colors.red));
  static final router = RouterState();

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Localizations(
        delegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        locale: locale(),
        child: Theme(
          data: theme(),
          child: Scaffold(
            appBar: AppBar(
              title: Obx(() => Text(router.currentConfig.data.uri.toString())),
            ),
            body: const TestView(),
          ),
        ),
      ),
    );
  }
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

  V match<V>({required V Function(T) onData, required V Function(E) onError}) =>
      _data == null ? onError(_error!) : onData(_data!);
}

typedef Response<T, E extends Error> = FutureOr<Result<T, E>>;

abstract interface class Command<T, E extends Error> {
  Response<T, E> excecute();
}

class Bloc<S extends State, E extends Event> {}

typedef EventHandler<E extends Event, S extends State> = S Function(
  E event,
);

typedef ActionEmitter<S extends Store> = void Function(Action<S>);

typedef EventEmitter<E extends Event> = void Function(E);

class DuplicateEventHandlerException implements Exception {
  final String message;
  DuplicateEventHandlerException(this.message);
}

// abstract class Compositor<S extends Store, E extends Event> {
//   S createStore();
//   Rx<E> createEvent() => Rx<E>.indistinct();

//   late final _store = createStore();
//   late final _eventChannel = createEvent();
//   final _childEventChannels = <Rx<E>>[];

//   @mustCallSuper
//   void dispose() {
//     _eventChannel.close();
//     for (final childEventChannel in _childEventChannels) {
//       childEventChannel.close();
//     }
//     _store.dispose();
//   }

//   void _consume(E e) => _eventChannel(e);

//   @protected
//   @nonVirtual
//   void on<T extends E>(EventHandler<T, S> handler,
//       {RxTransformer<T>? transformer}) {
//     if (_childEventChannels.any((e) => e is Rx<T>)) {
//       throw DuplicateEventHandlerException(
//           "Duplicate registration for event handler of type ${T.toString()}");
//     }
//     _childEventChannels.add(_eventChannel.pipe<T>((e) =>
//         transformer == null ? e.whereType<T>() : transformer(e.whereType<T>()))
//       ..listen((v) => handler(v, _emit)));
//   }
// }

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

class TestView extends StatelessWidget {
  const TestView({super.key});

  @override
  Widget build(BuildContext context) {
    final compositor = SettingsCompositor();
    return Column(
      children: [
        Obx(() => Text(compositor._store.locale.toString())),
        ElevatedButton(
            onPressed: () =>
                compositor._consume(ChangeLocaleEvent(Locale('en'))),
            child: Text("Click me"))
      ],
    );
  }
}

sealed class SettingsEvent extends Event {}

class ChangeLocaleEvent extends SettingsEvent {
  final Locale locale;

  ChangeLocaleEvent(this.locale);
}

sealed class SettingsAction extends Action<SettingsStore> {}

class ChangeLocaleAction extends SettingsAction {
  final Locale locale;

  ChangeLocaleAction(this.locale);

  @override
  FutureOr<void> execute(SettingsStore store) {
    store.locale(locale);
  }
}

class SettingsStore extends Store {
  final locale = Rx<Locale>(Locale('fr'));
}

class SettingsCompositor extends Compositor<SettingsStore, SettingsEvent> {
  @override
  SettingsStore createStore() => SettingsStore();

  SettingsCompositor() {
    on<ChangeLocaleEvent>(
        (event, emit) => emit(ChangeLocaleAction(event.locale)));
  }
}

class Store {
  @mustCallSuper
  void dispose() {}
}

class View<T extends Compositor> {}

class ChangeLocaleIntent extends Intent {
  final Locale locale;
  const ChangeLocaleIntent(this.locale);

  @override
  bool execute() {
    App.locale(locale);
    return true;
  }
}

class AppState {}

Uri _startingUri() => Uri.parse(kIsWeb
    ? Uri.base
        .toString()
        .replaceFirst('${Uri.base.scheme}://${Uri.base.authority}', '')
    : WidgetsFlutterBinding.ensureInitialized()
        .platformDispatcher
        .defaultRouteName);

String _compareRoute(RouteConfig conf) => conf.uri.toString();
const routeConfigEquality = PropEquality(_compareRoute);

class RouterState {
  final RxList<RouteConfig> routes = Rx([RouteConfig(_startingUri())]);
  final RxInt index = Rx(0);

  late final Rx<RouteConfig> displayed =
      Rx.fuse(() => routes.data[index.data], eq: routeConfigEquality);

  late final Rx<RouteConfig> currentConfig =
      Rx.fuse(() => routes.data.last, eq: routeConfigEquality);
}

class RouteConfig {
  final Uri uri;
  RouteConfig(this.uri);
}

final rxInt = RxnInt();
final notifier = ValueNotifier<int?>(null);
final rxInts = getx.RxnInt();

int trolol = 0;
int trolil = 0;

const loops = 1000;
bool val = false;

class Test extends StatelessWidget {
  Test({Key? key}) : super(key: key);

  final rxString = Rx("Some String");
  final rxString2 = "Some String".obs;

  @override
  Widget build(context) {
    return Scaffold(
      appBar: AppBar(
          title: Text(MaterialLocalizations.of(context).backButtonTooltip)),
      body: Column(
        children: [
          Obx(() {
            rxString.data;
            trolol++;
            print("Build");
            return Text(
              rxString.data +
                  rxInt.data.toString() +
                  rxInts.value.toString() +
                  notifier.value.toString(),
              style: const TextStyle(fontSize: 22, color: Colors.red),
            );
          }),
          ElevatedButton(
              onPressed: () => Intent.push(ChangeLocaleIntent(App.locale.data)),
              child: const Text("Click")),
          // getx.Obx(() {
          //   trolil++;
          //   if (trolil < loops) {
          //     rxString2.value == "" ? rxString2("trolol") : rxString2("");
          //   } else {
          //     print(DateTime.now().difference(time).inMilliseconds);
          //   }
          //   return Text(rxString2.value);
          // }),
        ],
      ),
    );
  }
}
