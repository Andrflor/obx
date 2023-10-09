import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:obx/obx.dart';
import 'package:get/get.dart' as getx;

void main() => runApp(const App());

class AppConfig {}

abstract class Nav {}

class App extends StatelessWidget {
  const App({super.key});

  static final state = AppState();
  static final locale = Rx<Locale>(Locale('en'));
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

abstract class Intent {
  Future<bool> execute(AppState state);
}

class AppState {}

Uri _startingUri() => Uri.parse(kIsWeb
    ? Uri.base
        .toString()
        .replaceFirst('${Uri.base.scheme}://${Uri.base.authority}', '')
    : WidgetsFlutterBinding.ensureInitialized()
        .platformDispatcher
        .defaultRouteName);

final appState = AppState();

extension _LastFunc on RxList<RouteConfig> {
  RouteConfig _last() => data.last;
}

String _compareRoute(RouteConfig conf) => conf.uri.toString();
const routeConfigEquality = PropEquality(_compareRoute);

class RouterState {
  final RxList<RouteConfig> routes = Rx([RouteConfig(_startingUri())]);
  late final Rx<RouteConfig> currentConfig =
      Rx.fuse(routes._last, eq: routeConfigEquality);
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
              style: TextStyle(fontSize: 22, color: Colors.red),
            );
          }),
          ElevatedButton(
              onPressed: () => App.locale(Locale('fr')), child: Text("Click")),
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
