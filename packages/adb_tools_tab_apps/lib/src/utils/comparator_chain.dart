/// 排序条件组合器
class ComparatorChain<T> {
  final List<Comparator<T>> _comparators = [];

  /// 添加一个排序条件
  ComparatorChain<T> thenCompare(Comparator<T> comparator) {
    _comparators.add(comparator);
    return this;
  }

  /// 执行比较
  int compare(T a, T b) {
    for (final comparator in _comparators) {
      final result = comparator(a, b);
      if (result != 0) return result;
    }
    return 0;
  }
}
