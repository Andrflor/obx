import 'package:flutter/material.dart';
import 'package:obx/obx.dart';

void main() => runApp(MaterialApp(home: Test()));

class Test extends StatelessWidget {
  Test({Key? key}) : super(key: key);

  final rxString = Rx("Some String");
  final rxString2 = Rx("Another String");

  @override
  Widget build(context) {
    ever(() => "$rxString", print);
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        ElevatedButton(
          child: Obx(() => Text(observe(() => rxString.length.toString()))),
          onPressed: () => rxString("${rxString()}!"),
        ),
        const SizedBox(height: 10),
        ElevatedButton(
          child: Obx(() => Text(rxString.value)),
          onPressed: () => rxString2("${rxString2()}!"),
        ),
      ],
    );
  }
}
