import 'package:collection/collection.dart';
import 'package:memogenerator/data/repositories/list_reactive_repository.dart';

abstract class ListWithIdsReactiveRepository<T>
    extends ListReactiveRepository<T> {
  Future<bool> addItemOrReplaceById(final T newItem) async {
    final items = await getItems();
    final itemIndex = items.indexWhere((item) => getId(item) == getId(newItem));
    if (itemIndex < 0) {
      items.add(newItem);
      return setItems(items);
    }
    items[itemIndex] = newItem;
    return setItems(items);
  }

  Future<bool> removeFromItemsById(final dynamic id) async {
    final items = await getItems();
    items.removeWhere((item) => getId(item) == id);
    return setItems(items);
  }

  Future<T?> getItemById(final dynamic id) async {
    final items = await getItems();
    return items.firstWhereOrNull((item) => getId(item) == id);
  }

  dynamic getId(final T item);
}
