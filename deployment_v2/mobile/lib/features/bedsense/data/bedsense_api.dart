import '../../../core/network/api_client.dart';
import 'bedsense_models.dart';

/// Calls to /api/v1/bedsense through the shared ApiClient (token, base URL and
/// ApiException handling are shared with the other modules).
class BedSenseApi {
  BedSenseApi(this._client);

  final ApiClient _client;

  static const _base = '/api/v1/bedsense';

  String _query(Map<String, String?> params) {
    final kept = {
      for (final e in params.entries)
        if (e.value != null && e.value!.isNotEmpty) e.key: e.value!,
    };
    return kept.isEmpty ? '' : '?${Uri(queryParameters: kept).query}';
  }

  Future<BsMeta> meta() async => BsMeta(await _client.getJson('$_base/meta'));

  /// The patient code header lets the portal log the evaluation (like Sora / MedOracle).
  Future<BsPrediction> predict(Map<String, dynamic> form, {String? patientCode}) async =>
      BsPrediction(await _client.postJson(
        '$_base/predict',
        form,
        headers: patientCode == null ? null : {'X-Patient-Code': patientCode},
      ));

  Future<BsPlan> plan({String? service, int? horizon}) async => BsPlan(await _client.getJson(
        '$_base/plan${_query({'service': service, 'horizon': horizon?.toString()})}',
        timeout: const Duration(seconds: 40),
      ));

  Future<BsFollowup> followup({String? service, int top = 20}) async =>
      BsFollowup(await _client.getJson(
        '$_base/followup${_query({'service': service, 'top': '$top'})}',
        timeout: const Duration(seconds: 40),
      ));
}
