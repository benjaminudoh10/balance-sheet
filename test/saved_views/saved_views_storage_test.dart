import 'package:balance_sheet/saved_views/saved_views_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_storage/get_storage.dart';

import '../helpers/path_provider_mock.dart';

void main() {
  setUpAll(() async {
    setupPathProviderMock();
    await GetStorage.init();
  });

  setUp(() async {
    await GetStorage().erase();
  });

  test('add list remove round-trip per feature', () async {
    expect(SavedViewsStorage.listFor(SavedViewsStorage.featureReport), isEmpty);

    await SavedViewsStorage.add(SavedViewsStorage.featureReport, 'Q1', <String, dynamic>{'type': 'month'});
    await SavedViewsStorage.add(SavedViewsStorage.featureInsights, 'Week', <String, dynamic>{'period': 'thisWeek'});

    final List<SavedViewRecord> r = SavedViewsStorage.listFor(SavedViewsStorage.featureReport);
    expect(r.length, 1);
    expect(r.first.name, 'Q1');
    expect(r.first.payload['type'], 'month');

    expect(SavedViewsStorage.listFor(SavedViewsStorage.featureInsights).length, 1);

    final String id = r.first.id;
    await SavedViewsStorage.remove(SavedViewsStorage.featureReport, id);
    expect(SavedViewsStorage.listFor(SavedViewsStorage.featureReport), isEmpty);
    expect(SavedViewsStorage.listFor(SavedViewsStorage.featureInsights).length, 1);
  });
}
