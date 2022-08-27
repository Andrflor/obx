import 'package:flutter/material.dart';
import 'package:obx/obx.dart';

void main() => runApp(MaterialApp(home: Test()));

class Test extends StatelessWidget {
  late final cond = false.obs;

  // late final display = cond
  //     .obsWhere((e) => e != null)
  //     .pipe((e) => e == null ? "None" : (e ? "Great" : "Bad"));
  // late final display2 = cond
  //     .pipe((e) => e == null ? "None2" : (e ? "Great2" : "Bad2"))
  //     .pipe((e) => "Yoy");

  @override
  Widget build(context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        ObxValue((Rx<bool> data) {
          print("Building ObxValue");
          return Text(cond().toString());
        }, false.obs),
        Obx(
          () {
            print("Building Obx");
            return Text(cond().toString());
          },
        ),
        ElevatedButton(onPressed: () => cond(!cond()), child: Text("Toggle")),
      ],
    );
  }
}
