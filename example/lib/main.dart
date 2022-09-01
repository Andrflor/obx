import 'dart:async';

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
  T get value => _value;

  set value(T val) => _value = val;
}

callback<T>(Rx<T> data) {}

extension Plopi<T> on List<Rx<T>> {
  S observe<S>(S Function(List<Rx<T>> e) toElement) {
    return toElement(this);
  }
}

obsTest() {
  final closure = () => {1 + 2};
  print(closure.hashCode);
  final numeric = 1;
  print(numeric.hashCode);
}

extension Bend<T> on Rx<T> {
  void bend(Valuer v) {}
}

extension Bind<T> on Rx<T> {
  void bend(RxBool v) {}
}

fun(Rx<bool?> rxBool) {
  rxBool.value;
}

func(RxBool rxBool, RxInt rxNum, RxInt rxNum2) async {
  while (true) {
    await Future.delayed(Duration(milliseconds: 100));
    rxNum((rxNum + 1) as int);
    rxNum2((rxNum2 + 1) as int);
  }
}

class MbEater {
  int seed;
  MbEater(this.seed) {
    data += seed.toString();
  }

  late String data =
      "lwakdlpawkdpolwakdpowakdopkawopodkawopkdopwhiouxhjcjcncn2idwopqkdfokwqmjdfqwkfpoweqjfp$seed" *
          200000;

  String eat() {
    final trol = data;
    print("eating${data[0]}");
    return toString();
  }

  @override
  String toString() => "value";
}

class Test extends StatelessWidget {
  Test() {
    // print(display.isDistinct);
    // print(display2.isDistinct);

    MbEater(0).data;

    print(Rx(null).runtimeType);

    Rx.fuse(() => plep.value && plep.value);

    // func(plep, rxNum, rxNum2);

    // final rx = Rx.indistinct(3);
    // print(rx.runtimeType);
    // print(rx.runtimeType);
    // final rxStr = RxString("");
    // print(rxStr < 3);
    // print(rx.runtimeType);
    // final rnx = RxnBool(true);
    // print(rnx.runtimeType);
    //
    // print("here");
    // print(list.runtimeType);
    // print(list.length.runtimeType);
    //
    // // final test = false.obs;
    // // final noti = ValueNotifier<bool>(false).obs;
    // // print(noti.runtimeType);
    //
    // // final behav = BehaviorSubject<bool>.seeded(false).obs;
    // // print(behav.runtimeType);
    // final test = RxSet(<int>{});

    //   test.trigger({});
    //   print(test.runtimeType);
    //   print(test.length);
    //   test.refresh();
    //
    //   final emit = Emitter()
    //     ..listen((e) {
    //       print("This is emiting");
    //     })
    //     ..emit();
  }

  // final lel = Valuer(3);
  // late final list = RxList([lel])
  //   ..listen((e) {
  //     print(runtimeType);
  //   });
  //
  // final cond = Rx(false)
  //   ..listen((e) {
  //     print("updated $e");
  //   });
  final plep = Rx(true);

  final rxNum = Rx(20);
  final rxNum2 = Rx(20);
  final rxStr = Rx("");
  //
  // late final iCond = cond.dupe();
  // late final display = cond.pipe(
  //     (e) => (e.map((event) => event ? "Yes" : "No")),
  //     init: (e) => e ? "Yes" : "No");

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
          () => plep.value
              ? Obx(() => Column(
                    children: [
                      Text(rxNum2.toString()),
                      Text(
                        observe(() => MbEater(
                              rxNum.value,
                            ).eat()),
                      ),
                    ],
                  ))
              : Obx(
                  () => Text("$rxStr"),
                ),
        ),
        ElevatedButton(
            onPressed: () {
              rxNum(2);
              rxStr("0");
            },
            child: Text("Toggle")),
        ElevatedButton(
            onPressed: () {
              rxNum((rxNum + 1) as int);
              rxNum((rxNum2 + 1) as int);
            },
            child: Text("Toggle")),
      ],
    );
  }
}
