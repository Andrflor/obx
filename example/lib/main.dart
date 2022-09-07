import 'package:flutter/material.dart';
import 'package:obx/obx.dart';

void main() => runApp(MaterialApp(home: Test()));

class Test extends StatelessWidget {
  Test({Key? key}) : super(key: key);

  final rxString = Rx("Some String");
  final rxString2 = Rx("Another String");

  final rxInt = Rx(10);
  final rxInt2 = Rx(10);

  late final rxMult = Rx.fuse(multChanged);
  int get mult => observe(multChanged);

  int multChanged() => rxInt() * rxInt2();

  @override
  Widget build(context) {
    ever(multChanged, print);
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        ElevatedButton(
          // child: Obx(() => Text(observe(() => rxString.length.toString()))),
          child: Obx(() => Text("$rxMult")),
          onPressed: () => rxInt(0),
        ),
        const SizedBox(height: 10),
        ElevatedButton(
          child: Obx(() => Text(rxString.value)),
          onPressed: () => rxInt(10),
        ),
      ],
    );
  }
}
