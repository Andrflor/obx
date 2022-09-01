import '../../functions.dart';
import '../rx_impl/rx_core.dart';

// TODO: add docuementation from dart
// TODO: add all needed from iterable
// TODO: add map specific stuff
// TODO: add length comparating stuff
// TODO: make sure it properly works with implem
// TODO: write the extension for Rx<Map<K,V>?>
extension RxMapExt<K, V> on Rx<Map<K, V>> {
  V? operator [](Object? key) => observe(() => value[key as K]);

  void operator []=(K key, V value) {
    this.value[key] = value;
    refresh();
  }

  Map<RK, RV> cast<RK, RV>() => value.cast<RK, RV>();
  Rx<Map<RK, RV>> pipeCast<RK, RV>() => pipeMap((e) => e.cast<RK, RV>());

  void clear() {
    value.clear();
    refresh();
  }

  Iterable<K> get keys => value.keys;
  Iterable<V> get values => value.values;

  V? remove(Object? key) {
    final val = value.remove(key);
    refresh();
    return val;
  }
}
