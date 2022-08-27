import 'package:flutter/material.dart';
import 'package:obx/obx.dart';

void main() => runApp(MaterialApp(home: Test()));

class Test extends StatelessWidget {
  Test() {
    print(display.isDistinct);
  }

  late final cond = false.nobs;

  late final display = cond.pipe((e) => e.map((event) => "Yes"))..listen(print);

  @override
  Widget build(context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        // ObxValue((Rx<bool> data) {
        //   print("Building ObxValue");
        //   return Text(cond().toString());
        // }, false.obs),
        Obx(
          () {
            print("Building Obx");
            return Text("$display");
          },
        ),
        ElevatedButton(onPressed: () => cond(!cond()!), child: Text("Toggle")),
      ],
    );
  }
}
