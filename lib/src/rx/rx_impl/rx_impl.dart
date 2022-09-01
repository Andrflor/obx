import '../../notifier.dart';
import 'rx_mixins.dart';

// TODO: add docs
class RxImpl<T> extends Reactive<T>
    with StreamCapable<T>, Actionable<T>, Descriptible<T>, Distinctive<T> {
  RxImpl(super.val, {bool distinct = true})
      : _distinct = T == Null ? false : distinct;

  @override
  bool get isDistinct => _distinct;
  final bool _distinct;
}
