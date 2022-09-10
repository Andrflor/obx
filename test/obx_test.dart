import 'package:collection/collection.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:obx/obx.dart';
import 'package:equatable/equatable.dart';

class Person extends Equatable {
  // ignore: prefer_const_constructors_in_immutables
  Person(this.name);

  final String name;

  @override
  List<Object> get props => [name];
}

RxBool obs = Rx(false);
RxnBool nobs = Rxn(false);
RxBool iobs = Rx.indistinct(false);
RxnBool inobs = Rxn.indistinct(false);

void init() {
  obs = Rx(false);
  nobs = Rxn(false);
  iobs = Rx.indistinct(false);
  inobs = Rxn.indistinct(false);
}

void main() {
  group('Rx', () {
    group('listen', () {
      group('base', () {
        init();
        boolListen('obs', obs, false);
        boolListen('nobs', nobs, false);
        boolListen('iobs', iobs, true);
        boolListen('inobs', inobs, true);
      });

      group('detatch', () {
        init();
        boolListen('obs', obs, false, obs.dupe()..detatch(), false);
        boolListen('nobs', nobs, false, nobs.dupe()..detatch(), false);
        boolListen('iobs', iobs, false, iobs.dupe()..detatch(), false);
        boolListen('inobs', inobs, false, inobs.dupe()..detatch(), false);
      });

      group('emiter', () {
        init();
        nullListen('Emitter', Emitter());
      });

      group('dupe', () {
        init();
        boolListen('obs', obs, false, obs.dupe());
        boolListen('nobs', nobs, false, nobs.dupe());
        boolListen('iobs', iobs, true, iobs.dupe());
        boolListen('inobs', inobs, true, inobs.dupe());
      });

      group('distinct', () {
        init();
        boolListen('obs', obs, false, obs.distinct());
        boolListen('nobs', nobs, false, nobs.distinct());
        boolListen('iobs', iobs, false, iobs.distinct());
        boolListen('inobs', inobs, false, inobs.distinct());
      });

      group('indistinct', () {
        init();
        boolListen('obs', obs, false, obs.indistinct());
        boolListen('nobs', nobs, false, nobs.indistinct());
        boolListen('iobs', iobs, true, iobs.indistinct());
        boolListen('inobs', inobs, true, inobs.indistinct());
      });

      group('pipe', () {
        group('where', () {
          init();
          boolListen('obs', obs, false,
              obs.pipe((e) => e.where((e) => e == false)), false);
          boolListen('nobs', nobs, false,
              nobs.pipe((e) => e.where((e) => e == false)), false);
          boolListen('iobs', iobs, true,
              iobs.pipe((e) => e.where((e) => e == false)), false);
          boolListen('inobs', inobs, true,
              inobs.pipe((e) => e.where((e) => e == false)), false);
        });

        group('map', () {
          init();
          boolListen('obs', obs, false,
              obs.pipe((e) => e.map((e) => ""), init: (e) => ""), false);
          boolListen('nobs', nobs, false,
              nobs.pipe((e) => e.map((e) => ""), init: (e) => ""), false);
          boolListen('iobs', iobs, true,
              iobs.pipe((e) => e.map((e) => ""), init: (e) => ""));
          boolListen('inobs', inobs, true,
              inobs.pipe((e) => e.map((e) => ""), init: (e) => ""));
        });
      });

      group('trigger', () {
        init();
        boolTriggerListen('obs', obs);
        boolTriggerListen('nobs', nobs);
        boolTriggerListen('iobs', iobs);
        boolTriggerListen('inobs', inobs);
      });

      group('silent', () {
        init();
        boolSilentListen('obs', obs);
        boolSilentListen('nobs', nobs);
        boolSilentListen('iobs', iobs);
        boolSilentListen('inobs', inobs);
      });
    });
    group('equal', () {
      equals(
        "boolean",
        Rx(false),
        Rx(false),
      );
      equals(
        "list empty",
        Rx.withEq(eq: const ListEquality(), init: []),
        Rx.withEq(eq: const ListEquality(), init: []),
      );
      equals(
        "list int",
        Rx.withEq(eq: const ListEquality(), init: [1]),
        Rx.withEq(eq: const ListEquality(), init: [1]),
      );
      equals(
        "list int?",
        Rx.withEq(eq: const ListEquality(), init: <int?>[1]),
        Rx.withEq(eq: const ListEquality(), init: <int?>[1]),
      );
      equals(
        "equatable",
        Rx(Person("bill")),
        Rx(Person("bill")),
      );
    });
    group('inequal', () {
      inequals(
        "boolean",
        Rx(false),
        Rx(true),
      );
      inequals(
        "list int",
        Rx.withEq(eq: const ListEquality(), init: [1]),
        Rx.withEq(eq: const ListEquality(), init: [2]),
      );
      inequals(
        "list int?",
        Rx(<int?>[1]),
        Rx(<int?>[2]),
      );
      inequals(
        "equatable",
        Rx(Person("bill")),
        Rx(Person("billy")),
      );
    });
  });
}

void isEqual<S, T>(String name, Rx<T> t, Rx<S> s, bool isEqual) {
  return test(name, () {
    expect(t.equalizer.equals(t.value, s.value), isEqual);
    expect(s.equalizer.equals(t.value, s.value), isEqual);
  });
}

void equals<S, T>(String name, Rx<T> t, Rx<S> s) {
  isEqual(name, t, s, true);
}

void inequals<S, T>(String name, Rx<T> t, Rx<S> s) {
  isEqual(name, t, s, false);
}

void boolListen(String name, Rx<bool?> rxBool, bool shouldFire,
    [Rx? child, bool? shouldSecondFire]) {
  return test(name, () async {
    bool fired = false;
    (child ?? rxBool).subscribe((e) {
      fired = true;
    });
    rxBool(rxBool());
    await Future.delayed(Duration.zero);
    expect(fired, shouldFire, reason: "same failed");
    fired = false;
    rxBool(!rxBool()!);
    await Future.delayed(Duration.zero);
    expect(fired, shouldSecondFire ?? true, reason: "diff failed");
  });
}

void nullListen(String name, Emitter emitter) {
  return test(name, () async {
    bool fired = false;
    emitter.subscribe((e) {
      fired = true;
    });
    emitter.emit();
    await Future.delayed(Duration.zero);
    expect(fired, true, reason: "same failed");
    fired = false;
    emitter.emit();
    await Future.delayed(Duration.zero);
    expect(fired, true, reason: "diff failed");
  });
}

void boolTriggerListen(String name, Rx<bool?> rxBool) {
  return test(name, () async {
    bool fired = false;
    rxBool.subscribe((e) {
      fired = true;
    });
    rxBool.trigger(rxBool());
    await Future.delayed(Duration.zero);
    expect(fired, true, reason: "same failed");
    fired = false;
    rxBool.trigger(!rxBool()!);
    await Future.delayed(Duration.zero);
    expect(fired, true, reason: "diff failed");
  });
}

void boolSilentListen(String name, Rx<bool?> rxBool) {
  return test(name, () async {
    bool fired = false;
    rxBool.subscribe((e) {
      fired = true;
    });
    rxBool.silent(rxBool());
    await Future.delayed(Duration.zero);
    expect(fired, false, reason: "same failed");
    fired = false;
    rxBool.silent(!rxBool()!);
    await Future.delayed(Duration.zero);
    expect(fired, false, reason: "diff failed");
  });
}
