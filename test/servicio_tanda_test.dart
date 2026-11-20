import 'package:flutter_test/flutter_test.dart';
import 'package:tanda_dolorena/modelos/participante.dart';
import 'package:tanda_dolorena/modelos/tanda.dart';
import 'package:tanda_dolorena/logica/resultado_aportacion.dart';
import 'package:tanda_dolorena/logica/resultado_cierre.dart';
import 'package:tanda_dolorena/logica/servicio_tanda.dart';

Tanda _crearTandaDePrueba() {
  return Tanda(
    participantes: [
      Participante(id: 'p1', nombre: 'Ana'),
      Participante(id: 'p2', nombre: 'Beto'),
      Participante(id: 'p3', nombre: 'Carla'),
    ],
    ordenTurnos: ['p1', 'p2', 'p3'],
    montoAportacion: 200,
  );
}

void _completarRonda(ServicioTanda servicio) {
  servicio.registrarAportacion('p1');
  servicio.registrarAportacion('p2');
  servicio.registrarAportacion('p3');
  servicio.cerrarRondaYAvanzar();
}

void main() {
  group('Ronda 1-3: aportaciones', () {
    test('registrar una aportacion valida la agrega a la ronda actual', () {
      final tanda = _crearTandaDePrueba();
      final servicio = ServicioTanda(tanda);
      final resultado = servicio.registrarAportacion('p1');
      expect(resultado, ResultadoAportacion.registrada);
      expect(tanda.aportacionesRondaActual.contains('p1'), true);
    });

    test('un participante no puede aportar dos veces en la misma ronda', () {
      final tanda = _crearTandaDePrueba();
      final servicio = ServicioTanda(tanda);
      servicio.registrarAportacion('p1');
      final segundoIntento = servicio.registrarAportacion('p1');
      expect(segundoIntento, ResultadoAportacion.yaAporto);
    });

    test('alguien que no pertenece a la tanda no puede aportar', () {
      final tanda = _crearTandaDePrueba();
      final servicio = ServicioTanda(tanda);
      final resultado = servicio.registrarAportacion('desconocido');
      expect(resultado, ResultadoAportacion.participanteInvalido);
      expect(tanda.aportacionesRondaActual, isEmpty);
    });
  });

  group('Ronda 4-6: cierre de ronda', () {
    test('puedeCerrarRonda es falso si falta algun participante por aportar', () {
      final tanda = _crearTandaDePrueba();
      final servicio = ServicioTanda(tanda);
      servicio.registrarAportacion('p1');
      servicio.registrarAportacion('p2');
      expect(servicio.puedeCerrarRonda(), false);
    });

    test('puedeCerrarRonda es verdadero cuando todos ya aportaron', () {
      final tanda = _crearTandaDePrueba();
      final servicio = ServicioTanda(tanda);
      servicio.registrarAportacion('p1');
      servicio.registrarAportacion('p2');
      servicio.registrarAportacion('p3');
      expect(servicio.puedeCerrarRonda(), true);
    });

    test('cerrar la ronda entrega el turno al beneficiario y avanza', () {
      final tanda = _crearTandaDePrueba();
      final servicio = ServicioTanda(tanda);
      servicio.registrarAportacion('p1');
      servicio.registrarAportacion('p2');
      servicio.registrarAportacion('p3');
      final cierre = servicio.cerrarRondaYAvanzar();
      expect(cierre.resultado, ResultadoCierre.rondaCerrada);
      expect(cierre.beneficiario!.id, 'p1');
      expect(tanda.participantes.firstWhere((p) => p.id == 'p1').yaRecibioTurno, true);
      expect(tanda.turnoActual, 1);
      expect(tanda.aportacionesRondaActual.isEmpty, true);
    });

    test('el beneficiario sigue el orden acordado, no quien aporto primero', () {
      final tanda = _crearTandaDePrueba();
      final servicio = ServicioTanda(tanda);
      servicio.registrarAportacion('p3');
      servicio.registrarAportacion('p2');
      servicio.registrarAportacion('p1');
      expect(servicio.cerrarRondaYAvanzar().beneficiario!.id, 'p1');
    });

    test('no se puede cerrar la ronda si algun participante no ha aportado', () {
      final tanda = _crearTandaDePrueba();
      final servicio = ServicioTanda(tanda);
      servicio.registrarAportacion('p1');
      servicio.registrarAportacion('p2');
      final cierre = servicio.cerrarRondaYAvanzar();
      expect(cierre.resultado, ResultadoCierre.faltanAportaciones);
      expect(cierre.beneficiario, isNull);
      expect(tanda.turnoActual, 0);
    });

    test('el monto entregado es aportacion por numero de participantes', () {
      final servicio = ServicioTanda(_crearTandaDePrueba());
      expect(servicio.montoDelTurno(), 600);
    });
  });

  group('Ronda 7: fin de la tanda', () {
    test('haTerminado es falso mientras queden turnos pendientes', () {
      final servicio = ServicioTanda(_crearTandaDePrueba());
      expect(servicio.haTerminado(), false);
    });

    test('haTerminado es verdadero cuando todos ya recibieron su turno', () {
      final servicio = ServicioTanda(_crearTandaDePrueba());
      for (var i = 0; i < 3; i++) {
        _completarRonda(servicio);
      }
      expect(servicio.haTerminado(), true);
    });

    test('no se puede aportar una vez que la tanda ha terminado', () {
      final servicio = ServicioTanda(_crearTandaDePrueba());
      for (var i = 0; i < 3; i++) {
        _completarRonda(servicio);
      }
      expect(servicio.registrarAportacion('p1'), ResultadoAportacion.tandaTerminada);
    });

    test('cerrar una ronda con la tanda terminada devuelve tandaYaTermino', () {
      final servicio = ServicioTanda(_crearTandaDePrueba());
      for (var i = 0; i < 3; i++) {
        _completarRonda(servicio);
      }
      final cierre = servicio.cerrarRondaYAvanzar();
      expect(cierre.resultado, ResultadoCierre.tandaYaTermino);
      expect(cierre.beneficiario, isNull);
    });

    test('beneficiarioActual es null cuando la tanda ya termino', () {
      final servicio = ServicioTanda(_crearTandaDePrueba());
      expect(servicio.beneficiarioActual()!.nombre, 'Ana');
      for (var i = 0; i < 3; i++) {
        _completarRonda(servicio);
      }
      expect(servicio.beneficiarioActual(), isNull);
    });
  });

  group('Reto: orden barajado', () {
    test('barajar el orden conserva a todos los participantes una sola vez', () {
      final tanda = _crearTandaDePrueba();
      final servicio = ServicioTanda(tanda);
      servicio.barajarOrden(semilla: 7);
      expect(tanda.ordenTurnos.toSet(), {'p1', 'p2', 'p3'});
      expect(tanda.ordenTurnos.length, 3);
    });

    test('no se puede barajar una tanda ya iniciada', () {
      final tanda = _crearTandaDePrueba();
      final servicio = ServicioTanda(tanda);
      servicio.registrarAportacion('p1');
      expect(() => servicio.barajarOrden(semilla: 1), throwsStateError);
    });
  });

  test('simulacion completa: 3 vecinas completan una tanda de principio a fin', () {
    final tanda = _crearTandaDePrueba();
    final servicio = ServicioTanda(tanda);
    final beneficiarios = <String>[];
    while (!servicio.haTerminado()) {
      for (final p in tanda.participantes) {
        servicio.registrarAportacion(p.id);
      }
      final cierre = servicio.cerrarRondaYAvanzar();
      beneficiarios.add(cierre.beneficiario!.id);
    }
    expect(beneficiarios, ['p1', 'p2', 'p3']);
    expect(tanda.participantes.every((p) => p.yaRecibioTurno), true);
    expect(servicio.registrarAportacion('p1'), ResultadoAportacion.tandaTerminada);
  });
}
