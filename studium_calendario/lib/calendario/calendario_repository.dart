import 'package:supabase_flutter/supabase_flutter.dart';

import 'evento.dart';

/// Substitui o CalendarioController.php: fala com a tabela "calendario"
/// pela API do Supabase (o app nunca abre conexão direta com o Postgres).
class CalendarioRepository {
  CalendarioRepository({SupabaseClient? client, this.idUsuario})
      : _db = client ?? Supabase.instance.client;

  final SupabaseClient _db;
  final int? idUsuario;

  static const _tabela = 'calendario';

  String _iso(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  /// index(): eventos do mês, ordenados por data e hora.
  Future<List<Evento>> listarPorMes(DateTime mes) async {
    final inicio = DateTime(mes.year, mes.month, 1);
    final fim = DateTime(mes.year, mes.month + 1, 0);

    var consulta = _db
        .from(_tabela)
        .select()
        .gte('data_evento', _iso(inicio))
        .lte('data_evento', _iso(fim));

    if (idUsuario != null) {
      consulta = consulta.eq('id_usuario', idUsuario!);
    }

    final linhas = await consulta
        .order('data_evento', ascending: true)
        .order('hora', ascending: true);

    return linhas.map<Evento>((m) => Evento.fromMap(m)).toList();
  }

  /// salvar(): INSERT quando não tem id, UPDATE quando tem.
  Future<void> salvar(Evento e) async {
    if (e.id == null) {
      await _db.from(_tabela).insert({...e.toMap(), 'id_usuario': idUsuario});
    } else {
      var q = _db.from(_tabela).update(e.toMap()).eq('id', e.id!);
      if (idUsuario != null) q = q.eq('id_usuario', idUsuario!);
      await q;
    }
  }

  /// excluir()
  Future<void> excluir(int id) async {
    var q = _db.from(_tabela).delete().eq('id', id);
    if (idUsuario != null) q = q.eq('id_usuario', idUsuario!);
    await q;
  }
}
