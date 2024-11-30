class SortedList<E> {
  final List<E> _list = [];
  final int Function(E a, E b) _compare;

  SortedList(this._compare);

  List<E> get items => List.unmodifiable(_list);

  void update(E element, bool Function(E) finder) {
    final index = _list.indexWhere(finder);
    if (index != -1) {
      _list.removeAt(index);
      add(element);
    }
  }

  void add(E element) {
    if (_list.isEmpty) {
      _list.add(element);
      return;
    }

    final insertIndex = _findInsertIndex(element);
    _list.insert(insertIndex, element);
  }

  int _findInsertIndex(E element) {
    int low = 0;
    int high = _list.length;

    while (low < high) {
      final mid = (low + high) ~/ 2;
      if (_compare(_list[mid], element) <= 0) {
        low = mid + 1;
      } else {
        high = mid;
      }
    }

    return low;
  }

  void addAll(Iterable<E> elements) {
    elements.forEach(add);
  }

  bool remove(E element) {
    return _list.remove(element);
  }

  void removeWhere(bool Function(E) test) {
    _list.removeWhere(test);
  }

  void clear() {
    _list.clear();
  }

  int get length => _list.length;
  bool get isEmpty => _list.isEmpty;
  bool get isNotEmpty => _list.isNotEmpty;
}
