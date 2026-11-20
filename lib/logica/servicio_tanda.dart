import 'dart:math';

import '../modelos/cierre_ronda.dart';
import '../modelos/participante.dart';
import '../modelos/tanda.dart';
import 'resultado_aportacion.dart';
import 'resultado_cierre.dart';

/// Reglas de negocio de la tanda. Dart puro: no importa Flutter.
class ServicioTanda {
  final Tanda tanda;

  ServicioTanda(this.tanda);

  bool haTerminado() => tanda.turnoActual >= tanda.ordenTurnos.length;

  double montoDelTurno() => tanda.montoAportacion * tanda.participantes.length;

  Participante? beneficiarioActual() {
    if (haTerminado()) return null;
    final id = tanda.ordenTurnos[tanda.turnoActual];
    return tanda.participantes.firstWhere((p) => p.id == id);
  }

  ResultadoAportacion registrarAportacion(String idParticipante) {
    if (haTerminado()) return ResultadoAportacion.tandaTerminada;

    final esParticipante = tanda.participantes.any((p) => p.id == idParticipante);
    if (!esParticipante) return ResultadoAportacion.participanteInvalido;

    final yaAporto = tanda.aportacionesRondaActual.contains(idParticipante);
    if (yaAporto) return ResultadoAportacion.yaAporto;

    tanda.aportacionesRondaActual.add(idParticipante);
    return ResultadoAportacion.registrada;
  }

  bool puedeCerrarRonda() =>
      tanda.participantes.every((p) => tanda.aportacionesRondaActual.contains(p.id));

  CierreRonda cerrarRondaYAvanzar() {
    if (haTerminado()) return CierreRonda(ResultadoCierre.tandaYaTermino, null);
    if (!puedeCerrarRonda()) return CierreRonda(ResultadoCierre.faltanAportaciones, null);

    final beneficiario = beneficiarioActual()!;
    beneficiario.yaRecibioTurno = true;
    tanda.aportacionesRondaActual.clear();
    tanda.turnoActual++;
    return CierreRonda(ResultadoCierre.rondaCerrada, beneficiario);
  }

  /// Reto: sortea el orden de turnos antes de empezar.
  void barajarOrden({int? semilla}) {
    final yaInicio = tanda.turnoActual > 0 || tanda.aportacionesRondaActual.isNotEmpty;
    if (yaInicio) throw StateError('La tanda ya empezó: no se puede cambiar el orden.');
    tanda.ordenTurnos.shuffle(Random(semilla));
  }
}
