import '../../../core/network/api_client.dart';
import 'teemo_models.dart';

/// All of Teemo's server calls. Meta is cached per server URL.
class TeemoRepository {
  TeemoRepository(this._api);

  final ApiClient _api;
  TeemoMeta? _meta;
  String? _metaFor;

  TeemoMeta? get cachedMeta => _metaFor == _api.baseUrl ? _meta : null;

  Future<TeemoMeta> meta({bool refresh = false}) async {
    if (!refresh && cachedMeta != null) return _meta!;
    final json = await _api.getJson('/api/v1/teemo/meta');
    _meta = TeemoMeta.fromJson(json);
    _metaFor = _api.baseUrl;
    return _meta!;
  }

  Future<TeemoResult> predict(Map<String, dynamic> patient, {String? label}) async {
    final json = await _api.postJson('/api/v1/teemo/predict', patient);
    return TeemoResult(json, label: label);
  }
}
