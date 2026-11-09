import 'package:flutter/material.dart';

/// Tipos do <select> do form.php, com as cores de .cal-tipo-*
enum TipoEvento {
  prova('Prova', Color(0xFFE94B55), Color(0xFFFEE2E2)),
  trabalho('Trabalho', Color(0xFF3B82F6), Color(0xFFDBEAFE)),
  tarefa('Tarefa', Color(0xFF10B981), Color(0xFFD1FAE5)),
  outro('Outro', Color(0xFF8B5CF6), Color(0xFFEDE9FE));

  const TipoEvento(this.rotulo, this.cor, this.fundo);

  final String rotulo; // valor gravado na coluna "tipo"
  final Color cor;
  final Color fundo;

  static TipoEvento daString(String? valor) {
    return TipoEvento.values.firstWhere(
      (t) => t.rotulo.toLowerCase() == (valor ?? '').toLowerCase(),
      orElse: () => TipoEvento.outro,
    );
  }
}

class Evento {
  const Evento({
    this.id,
    required this.titulo,
    this.descricao = '',
    required this.data,
    this.hora,
    required this.tipo,
    this.idUsuario,
  });

  final int? id;
  final String titulo;
  final String descricao;
  final DateTime data; // só a data (00:00)
  final String? hora; // "HH:mm" ou null
  final TipoEvento tipo;
  final int? idUsuario;

  factory Evento.fromMap(Map<String, dynamic> m) {
    final d = DateTime.parse(m['data_evento'] as String);
    final h = m['hora'] as String?; // Postgres devolve "14:30:00"
    return Evento(
      id: m['id'] as int?,
      titulo: (m['titulo'] ?? '') as String,
      descricao: (m['descricao'] ?? '') as String,
      data: DateTime(d.year, d.month, d.day),
      hora: (h == null || h.isEmpty) ? null : h.substring(0, 5),
      tipo: TipoEvento.daString(m['tipo'] as String?),
      idUsuario: m['id_usuario'] as int?,
    );
  }

  /// Campos graváveis (sem id e sem id_usuario).
  Map<String, dynamic> toMap() => {
        'titulo': titulo,
        'descricao': descricao,
        'data_evento': dataIso,
        'hora': hora,
        'tipo': tipo.rotulo,
      };

  String get dataIso =>
      '${data.year.toString().padLeft(4, '0')}-${data.month.toString().padLeft(2, '0')}-${data.day.toString().padLeft(2, '0')}';
}
