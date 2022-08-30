import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:obx/obx.dart';

void main() => runApp(MaterialApp(home: Test()));

class Valuer<T> extends ValueListenable<T> {
  Valuer(T value) : _value = value;

  T _value;

  @override
  void addListener(VoidCallback listener) {
    // TODO: implement addListener
  }

  @override
  void removeListener(VoidCallback listener) {
    // TODO: implement removeListener
  }

  @override
  // TODO: implement value
  T get value => _value;

  set value(T val) => _value = val;
}

callback<T>(Rx<T> data) {}

extension Plopi<T> on List<Rx<T>> {
  S observe<S>(S Function(List<Rx<T>> e) toElement) {
    return toElement(this);
  }
}

extension Bend<T> on Rx<T> {
  void bend(Valuer v) {}
}

extension Bind<T> on Rx<T> {
  void bend(RxBool v) {}
}

class Test extends StatelessWidget {
  Test() {
    // print(display.isDistinct);
    // print(display2.isDistinct);

	DartSdk().isPackageGloballyActivated(String package);
    final liste = [0.obs, 0.obs];
    liste.observe((data) => data.first * 2);
    final rx = RxBool(true);
    final rxStr = RxString("");
    print(rxStr < 3);
    print(rx.runtimeType);
    final rnx = RxnBool(true);
    print(rnx.runtimeType);

    print("here");
    print((rnx & true).runtimeType);
    print(liste.runtimeType);
    print(liste[0].runtimeType);
    print(liste[1].runtimeType);
    print(list.runtimeType);
    print(list.length.runtimeType);

    // final test = false.obs;
    // final noti = ValueNotifier<bool>(false).obs;
    // print(noti.runtimeType);

    // final behav = BehaviorSubject<bool>.seeded(false).obs;
    // print(behav.runtimeType);
    final test = RxSet(<int>{});

    test.trigger({});
    print(test.runtimeType);
    print(test.length);
    test.refresh();

    final emit = Emitter()
      ..listen((e) {
        print("This is emiting");
      })
      ..emit();
  }

  final lel = Valuer(3);
  late final list = RxList([lel])
    ..listen((e) {
      print(runtimeType);
    });

  final cond = false.obs
    ..listen((e) {
      print("updated $e");
    });
  final plep = false.obs;

  final rxNum = 2.obs;
  final rxNum2 = 3.obs;

  late final iCond = cond.dupe();
  late final display = cond.pipe(
      (e) => (e.map((event) => event ? "Yes" : "No")),
      init: (e) => e ? "Yes" : "No");

  // late final display2 = cond.pipe(
  //   (e) => e.map((event) => "No").where((event) => event == "No").skip(2),
  //   init: (e) => "No",
  //   distinct: true,
  // )..listenNow((e) => print("Got called with $e"));

  @override
  Widget build(context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        // ObxValue((data) {
        //   print("Building ObxValue");
        //   return Text(data.toString());
        // }, false.obs),
        // Obx(
        //   () {
        //     print("Building 1");
        //     return Text("$iCond");
        //   },
        // ),
        Obx(
          () {
            print("Building 2");
            return Column(
              children: [
                Text("${rxNum * rxNum2.value}"),
              ],
            );
          },
        ),
        ElevatedButton(onPressed: () => rxNum(4), child: Text("Toggle")),
      ],
    );
  }
}
