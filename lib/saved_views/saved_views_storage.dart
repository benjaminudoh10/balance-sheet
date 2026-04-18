import 'dart:math';

import 'package:get_storage/get_storage.dart';

/// One named preset: [id] is stable for delete; [payload] is feature-specific JSON.
class SavedViewRecord {
  const SavedViewRecord({
    required this.id,
    required this.name,
    required this.payload,
  });

  final String id;
  final String name;
  final Map<String, dynamic> payload;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'name': name,
        'payload': payload,
      };

  factory SavedViewRecord.fromJson(Map<String, dynamic> j) {
    return SavedViewRecord(
      id: j['id'] as String,
      name: j['name'] as String,
      payload: Map<String, dynamic>.from(j['payload'] as Map<dynamic, dynamic>),
    );
  }
}

/// GetStorage-backed named views: one JSON root map `featureKey → list of records`.
class SavedViewsStorage {
  SavedViewsStorage._();

  static const String rootKey = 'saved_views_v1';

  /// Feature keys (surface id for JSON payload shape).
  static const String featureReport = 'report';
  static const String featureInsights = 'insights';
  static const String featureBudget = 'budget';

  static List<SavedViewRecord> listFor(String featureKey) {
    final GetStorage box = GetStorage();
    final dynamic raw = box.read(rootKey);
    if (raw == null) {
      return <SavedViewRecord>[];
    }
    final Map<String, dynamic> root = Map<String, dynamic>.from(raw as Map<dynamic, dynamic>);
    final List<dynamic>? list = root[featureKey] as List<dynamic>?;
    if (list == null) {
      return <SavedViewRecord>[];
    }
    return list
        .map((dynamic e) => SavedViewRecord.fromJson(Map<String, dynamic>.from(e as Map<dynamic, dynamic>)))
        .toList();
  }

  static Future<void> add(String featureKey, String name, Map<String, dynamic> payload) async {
    final String trimmed = name.trim();
    if (trimmed.isEmpty) {
      return;
    }
    final String id = '${DateTime.now().microsecondsSinceEpoch}_${_randomSuffix()}';
    final SavedViewRecord record = SavedViewRecord(id: id, name: trimmed, payload: payload);
    final List<SavedViewRecord> next = listFor(featureKey)..add(record);
    await _writeFeature(featureKey, next);
  }

  static Future<void> remove(String featureKey, String id) async {
    final List<SavedViewRecord> next = listFor(featureKey).where((SavedViewRecord e) => e.id != id).toList();
    await _writeFeature(featureKey, next);
  }

  static Future<void> _writeFeature(String featureKey, List<SavedViewRecord> list) async {
    final GetStorage box = GetStorage();
    final dynamic raw = box.read(rootKey);
    final Map<String, dynamic> root = raw == null
        ? <String, dynamic>{}
        : Map<String, dynamic>.from(raw as Map<dynamic, dynamic>);
    root[featureKey] = list.map((SavedViewRecord e) => e.toJson()).toList();
    await box.write(rootKey, root);
  }

  static String _randomSuffix() => Random().nextInt(0x7fffffff).toString();
}
