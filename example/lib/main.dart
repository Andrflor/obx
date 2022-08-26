import 'package:flutter/material.dart';
import 'package:obx/obx.dart';

void main() => runApp(MaterialApp(home: Test()));

class Test extends StatelessWidget {
  final cond = false.obs;

  @override
  Widget build(context) {
    return Column(
      children: [
        Obx(() => Text(cond.value.toString())),
        ElevatedButton(
            onPressed: () => cond(!cond.value), child: Text("Toggle")),
      ],
    );
  }
}
