import '../../../core/network/api_client.dart';
import 'carestep_models.dart';

/// CareStep's two server calls, through the shared [ApiClient] (which already
/// carries the doctor's token). Errors surface as [ApiException].
class CareStepApi {
  const CareStepApi(this._api);

  final ApiClient _api;

  Future<CareStepMeta> meta() async =>
      CareStepMeta.fromJson(await _api.getJson('/api/v1/carestep/meta'));

  Future<CareStepResult> predict(Map<String, Object> answers, {String? patientCode}) async {
    final json = await _api.postJson('/api/v1/carestep/predict', answers,
        headers: patientCode == null ? null : {'X-Patient-Code': patientCode});
    return CareStepResult(json);
  }
}
