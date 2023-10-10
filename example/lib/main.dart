import 'dart:async';
import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:obx/obx.dart';
import 'package:get/get.dart' as getx;

void main() => runApp(const App());

class AppConfig {}

class App extends StatelessWidget {
  const App({super.key});

  static final productBloc = ProductBloc();

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
            body: Obx(() => Test()),
          ),
        ),
      ),
    );
  }
}

abstract class Event {}

abstract class Action<T extends Store> {
  FutureOr<void> execute(T store);
}

typedef EventHandler<E extends Event, S extends Store> = FutureOr<void>
    Function(
  E event,
  Emitter<S> emit,
);

typedef Emitter<S extends Store> = void Function(Action<S>);

abstract class Orchestrator<S extends Store, E extends Event> {
  S createStore();
  Rx<E> createEvent() => Rx<E>.indistinct();

  late final _store = createStore();
  late final _eventChannel = createEvent();
  final _childEventChannels = <Rx<E>>[];

  @mustCallSuper
  void dispose() {
    _eventChannel.close();
    _store.dispose();
    // Dispose logic for _childEventChannels
  }

  void _consume(E e) => _eventChannel(e);

  FutureOr<void> _emit(Action<S> e) => e.execute(_store);

  @protected
  @nonVirtual
  void on<T extends E>(EventHandler<T, S> handler) {
    if (_childEventChannels.any((e) => e is Rx<T>)) {
      throw "Duplicate registration for event handler of type ${T.toString()}";
    }
    _childEventChannels.add(_eventChannel.pipe<T>((e) => e.whereType<T>())
      ..listen((v) => handler(v, _emit)));
  }
}

extension WhereType<T> on Stream<T> {
  Stream<S> whereType<S>() => throw "unimplemented";
}

sealed class ProductEvents extends Event {}

class ProductStore extends Store {
  final product = Rx<int>();
}

class ProductOrchestrator extends Orchestrator<ProductStore, ProductEvents> {
  @override
  ProductStore createStore() => ProductStore();
}

class Store {
  @mustCallSuper
  void dispose() {}
}

void markDispose(Rx rx) =>
    throw "autoDispose should only be used inside a store";

class View<T extends Orchestrator> {}

@immutable
abstract class Intent {
  const Intent();

  FutureOr<bool> execute();

  static final _executor = _Executor();
  static push(Intent e) => _executor.enqueue(e);
}

class IntentExecutor {
  final _intentQueue = Queue<Intent>();
  bool locked = false;

  void process() async {
    while (_intentQueue.isNotEmpty) {
      if (!locked) {
        final intent = _intentQueue.removeFirst();
        locked = true;

        try {
          // Execute the intent
          final success = await intent.execute();

          // Check the result of the execution
          if (success) {
            // If successful, unlock after execution
            locked = false;
          } else {
            // Handle failure if necessary
          }
        } catch (e) {
          // Handle exceptions thrown during execution
          // Unlock after handling the exception if needed
          locked = false;
        }
      }
    }
  }

  addIntent(Intent i) => _intentQueue.add(i);
}

class _Executor {
  final Queue<Intent> _queue = Queue<Intent>();
  bool _isExecuting = false;

  void enqueue(Intent intent) {
    _queue.add(intent);
    if (!_isExecuting) {
      _executeNext();
    }
  }

  Future<void> _executeNext() async {
    if (_queue.isEmpty) {
      _isExecuting = false;
      return;
    }

    _isExecuting = true;
    final intent = _queue.removeFirst();
    await intent.execute();
    _isExecuting = false;

    _executeNext();
  }
}

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
