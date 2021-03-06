import 'dart:async';
import 'package:rxdart/rxdart.dart';
import '../models/item_model.dart';
import '../resources/repository.dart';

class StoriesBloc {
  final _repository = Repository();
  final _topIds = PublishSubject<List<int>>(); //StreamController

  //Item Controller which every StreamBuilder widget listens to
  final _itemsOutput = BehaviorSubject<Map<int, Future<ItemModel>>>();

  //StreamController used to pump ids
  final _itemsFetcher = PublishSubject<int>();

  //Getters to Streams
  Observable<List<int>> get topIds => _topIds.stream;
  Observable<Map<int, Future<ItemModel>>> get items => _itemsOutput.stream;

  //Getters to Sinks
  Function(int) get fetchItem => _itemsFetcher.sink.add;

  StoriesBloc() {
    _itemsFetcher.stream.transform(_itemsTransformer()).pipe(_itemsOutput);
  }

  //Get list of Ids from the Repository and add it to the sink on our topIds StreamController
  fetchTopIds() async {
    final ids = await _repository.fetchTopIds();
    _topIds.sink.add(ids);
  }

  clearCache() {
    return _repository.clearCache();
  }

  _itemsTransformer() {
    return ScanStreamTransformer(
      //cache is used by each StreamBuilder while rebuilding widget for specific id
      (Map<int, Future<ItemModel>> cache, int id, _) {
        cache[id] = _repository.fetchItem(id);
        return cache; //cache gets persisted everytime this transformer gets called.
      },
      <int, Future<ItemModel>>{}, //initial value - cache map in our case
    );
  }

  dispose() {
    _topIds.close();
    _itemsFetcher.close();
    _itemsOutput.close();
  }
}
