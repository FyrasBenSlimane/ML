import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// The patient a doctor confirmed for the current evaluation. It is set by the
/// patient gate before a model runs, carried on the /predict call (header) and
/// read again on the result screen to pre-address the alert.
class ActivePatient extends Equatable {
  const ActivePatient({required this.code, required this.prenom, required this.nom});

  factory ActivePatient.fromJson(Map<String, dynamic> j) => ActivePatient(
        code: j['code'] as String,
        prenom: j['prenom'] as String? ?? '',
        nom: j['nom'] as String? ?? '',
      );

  final String code;
  final String prenom;
  final String nom;

  String get fullName => '$prenom $nom'.trim();

  @override
  List<Object?> get props => [code, prenom, nom];
}

class ActivePatientCubit extends Cubit<ActivePatient?> {
  ActivePatientCubit() : super(null);

  void select(ActivePatient patient) => emit(patient);

  void clear() => emit(null);
}
