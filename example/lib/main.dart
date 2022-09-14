import 'package:flutter/material.dart';
import 'package:obx/obx.dart';

void main() => runApp(MaterialApp(home: Test()));

class Test extends StatelessWidget {
  Test({Key? key}) : super(key: key);

  final rxString = Rx("Some String");
  final rxString2 = Rx("Another String");

  final rxInt = Rx(0);
  final rxInt2 = Rx(10);

  bool val = false;

  late final rxMult = Rx.fuse(multChanged);
  int get mult => observe(() => rxInt() * rxInt2());

  int multChanged() => rxInt() * rxInt2();

  @override
  Widget build(context) {
    mult;
    mult;
    () async {
      while (true) {
        if (val) {
          rxString.isEmpty ? rxString("trolol") : rxString("");
        }
        await Future.delayed(const Duration(milliseconds: 1));
      }
    }();
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Obx(() => ElevatedButton(
              child: Column(
                children: [Text("$mult"), Text("$rxString")],
              ),
              onPressed: () => rxInt2(rxInt2() + 1),
            )),
        const SizedBox(height: 10),
        ElevatedButton(
          child: Obx(() => Text(rxString.value)),
          onPressed: () => val = !val,
        ),
      ],
    );
  }
}
