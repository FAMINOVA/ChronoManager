import 'package:flutter/material.dart';

import 'cal_estilo.dart';
import 'calendario_repository.dart';
import 'evento.dart';
import 'evento_form_page.dart';

const _meses = [
  'Janeiro', 'Fevereiro', 'Março', 'Abril', 'Maio', 'Junho',
  'Julho', 'Agosto', 'Setembro', 'Outubro', 'Novembro', 'Dezembro',
];
const _diasSemana = [
  'Domingo', 'Segunda-feira', 'Terça-feira', 'Quarta-feira',
  'Quinta-feira', 'Sexta-feira', 'Sábado',
];
const _diasCurtos = ['DOM', 'SEG', 'TER', 'QUA', 'QUI', 'SEX', 'SÁB'];

class CalendarioPage extends StatefulWidget {
  const CalendarioPage({super.key, required this.repo});

  final CalendarioRepository repo;

  @override
  State<CalendarioPage> createState() => _CalendarioPageState();
}

class _CalendarioPageState extends State<CalendarioPage> {
  late DateTime _mes;
  List<Evento> _eventos = [];
  bool _carregando = true;
  String? _erro;
  int _requisicao = 0; // evita resposta antiga sobrescrever a do mês atual

  @override
  void initState() {
    super.initState();
    final h = DateTime.now();
    _mes = DateTime(h.year, h.month);
    _carregar();
  }

  Future<void> _carregar() async {
    final minha = ++_requisicao;
    setState(() {
      _carregando = true;
      _erro = null;
    });
    try {
      final r = await widget.repo.listarPorMes(_mes);
      if (!mounted || minha != _requisicao) return;
      setState(() {
        _eventos = r;
        _carregando = false;
      });
    } catch (_) {
      if (!mounted || minha != _requisicao) return;
      setState(() {
        _erro = 'Não foi possível carregar os eventos.';
        _carregando = false;
      });
    }
  }

  void _mudarMes(int delta) {
    setState(() => _mes = DateTime(_mes.year, _mes.month + delta));
    _carregar();
  }

  Future<void> _abrirForm({Evento? evento, DateTime? data}) async {
    final salvo = await Navigator.push<DateTime>(
      context,
      MaterialPageRoute(
        builder: (_) => EventoFormPage(
          repo: widget.repo,
          evento: evento,
          dataInicial: data ?? DateTime.now(),
        ),
      ),
    );
    if (salvo != null && mounted) {
      setState(() => _mes = DateTime(salvo.year, salvo.month));
      _carregar();
    }
  }

  Future<void> _confirmarExcluir(Evento e) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir evento'),
        content: const Text('Deseja excluir este evento?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Excluir', style: TextStyle(color: CalCores.erro)),
          ),
        ],
      ),
    );
    if (ok != true || e.id == null) return;

    try {
      await widget.repo.excluir(e.id!);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível excluir o evento.')),
      );
      return;
    }
    await _carregar();
  }

  void _abrirDia(DateTime dia) {
    final doDia = _eventos
        .where((e) => e.data.year == dia.year && e.data.month == dia.month && e.data.day == dia.day)
        .toList();

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => _DiaSheet(
        dia: dia,
        eventos: doDia,
        onNovo: () {
          Navigator.pop(sheetCtx);
          _abrirForm(data: dia);
        },
        onEditar: (e) {
          Navigator.pop(sheetCtx);
          _abrirForm(evento: e);
        },
        onExcluir: (e) {
          Navigator.pop(sheetCtx);
          _confirmarExcluir(e);
        },
      ),
    );
  }

  // ---------------------------------------------------------------- build

  @override
  Widget build(BuildContext context) {
    final largura = MediaQuery.sizeOf(context).width;
    final mobile = largura <= 600;
    final hoje = DateTime.now();

    return Scaffold(
      backgroundColor: CalCores.fundoApp,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _carregar,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.symmetric(
              horizontal: mobile ? 12 : 25,
              vertical: mobile ? 20 : 30,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1200),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _topo(mobile),
                    const SizedBox(height: 25),
                    _cartao(mobile, largura, hoje),
                    const SizedBox(height: 25),
                    _legenda(mobile),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ----------------------------------------------------------------- topo

  Widget _topo(bool mobile) {
    final textos = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const CalSelo('ORGANIZAÇÃO DO ALUNO'),
        const SizedBox(height: 12),
        Text(
          'Meu Calendário',
          style: TextStyle(
            fontSize: mobile ? 22 : 34,
            fontWeight: FontWeight.w800,
            color: CalCores.texto,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Organize provas, trabalhos, tarefas e compromissos.',
          style: TextStyle(color: CalCores.cinza, fontSize: 14),
        ),
      ],
    );
    final botao = CalBotaoGradiente(
      texto: '+ Novo Evento',
      onPressed: () => _abrirForm(),
    );

    if (mobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [textos, const SizedBox(height: 16), botao],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [Expanded(child: textos), const SizedBox(width: 20), botao],
    );
  }

  // --------------------------------------------------------------- cartão

  Widget _cartao(bool mobile, double largura, DateTime hoje) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: CalSombras.card,
      ),
      child: Column(
        children: [
          _controles(mobile),
          SizedBox(
            height: 3,
            child: _carregando
                ? const LinearProgressIndicator(
                    minHeight: 3,
                    color: CalCores.roxo,
                    backgroundColor: Colors.transparent,
                  )
                : null,
          ),
          _cabecalhoSemana(mobile),
          if (_erro != null) _mensagemErro() else _grade(mobile, largura, hoje),
        ],
      ),
    );
  }

  Widget _controles(bool mobile) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: mobile ? 16 : 30,
        vertical: mobile ? 16 : 22,
      ),
      decoration: const BoxDecoration(gradient: CalCores.gradiente),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _botaoMes('‹', 'Mês anterior', () => _mudarMes(-1), mobile),
          Text.rich(
            TextSpan(
              text: _meses[_mes.month - 1],
              style: TextStyle(
                fontSize: mobile ? 15 : 22,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
              children: [
                TextSpan(
                  text: '  ${_mes.year}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w400,
                    color: Color.fromRGBO(255, 255, 255, 0.85),
                  ),
                ),
              ],
            ),
          ),
          _botaoMes('›', 'Próximo mês', () => _mudarMes(1), mobile),
        ],
      ),
    );
  }

  Widget _botaoMes(String simbolo, String rotulo, VoidCallback onTap, bool mobile) {
    final tam = mobile ? 36.0 : 44.0;
    return Semantics(
      button: true,
      label: rotulo,
      child: Material(
        color: const Color.fromRGBO(255, 255, 255, 0.15),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: SizedBox(
            width: tam,
            height: tam,
            child: Center(
              child: Text(
                simbolo,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: mobile ? 20 : 24,
                  fontWeight: FontWeight.w700,
                  height: 1,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _cabecalhoSemana(bool mobile) {
    return Container(
      decoration: const BoxDecoration(
        color: CalCores.fundoClaro,
        border: Border(bottom: BorderSide(color: CalCores.borda, width: 2)),
      ),
      padding: EdgeInsets.symmetric(vertical: mobile ? 10 : 14),
      child: Row(
        children: [
          for (final d in _diasCurtos)
            Expanded(
              child: Center(
                child: Text(
                  d,
                  style: TextStyle(
                    fontSize: mobile ? 10 : 12,
                    fontWeight: FontWeight.w800,
                    color: CalCores.cinza,
                    letterSpacing: mobile ? 0.5 : 1.5,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _mensagemErro() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Text(_erro!, style: const TextStyle(color: CalCores.erroTexto, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          TextButton(onPressed: _carregar, child: const Text('Tentar novamente')),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------- grade

  Widget _grade(bool mobile, double largura, DateTime hoje) {
    final primeiro = DateTime(_mes.year, _mes.month, 1);
    final offset = primeiro.weekday % 7; // DateTime: seg=1..dom=7 → dom=0
    final diasNoMes = DateTime(_mes.year, _mes.month + 1, 0).day;
    final semanas = ((offset + diasNoMes) / 7).ceil();
    final altura = mobile ? 84.0 : (largura <= 900 ? 90.0 : 120.0);

    final porDia = <int, List<Evento>>{};
    for (final e in _eventos) {
      if (e.data.year == _mes.year && e.data.month == _mes.month) {
        porDia.putIfAbsent(e.data.day, () => []).add(e);
      }
    }

    return Column(
      children: [
        for (var s = 0; s < semanas; s++)
          SizedBox(
            height: altura,
            child: Row(
              children: [
                for (var c = 0; c < 7; c++)
                  Expanded(
                    child: _celula(
                      dia: s * 7 + c - offset + 1,
                      coluna: c,
                      diasNoMes: diasNoMes,
                      eventos: porDia[s * 7 + c - offset + 1] ?? const [],
                      hoje: hoje,
                      mobile: mobile,
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _celula({
    required int dia,
    required int coluna,
    required int diasNoMes,
    required List<Evento> eventos,
    required DateTime hoje,
    required bool mobile,
  }) {
    const linha = BorderSide(color: CalCores.borda);
    final borda = Border(
      right: coluna == 6 ? BorderSide.none : linha,
      bottom: linha,
    );

    // .cal-vazio (antes do dia 1)
    if (dia < 1) {
      return Container(
        decoration: BoxDecoration(color: CalCores.vazio, border: borda),
      );
    }
    // depois do último dia o CSS não desenha nada
    if (dia > diasNoMes) {
      return const SizedBox.shrink();
    }

    final data = DateTime(_mes.year, _mes.month, dia);
    final ehHoje = data.year == hoje.year && data.month == hoje.month && data.day == hoje.day;

    return Material(
      color: ehHoje ? CalCores.hojeFundo : Colors.white,
      child: InkWell(
        onTap: () => _abrirDia(data),
        child: Container(
          padding: EdgeInsets.all(mobile ? 4 : 10),
          decoration: BoxDecoration(border: borda),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _numeroDia(dia, ehHoje, data, mobile),
              SizedBox(height: mobile ? 3 : 6),
              // overflow: hidden do CSS
              Expanded(
                child: ClipRect(
                  child: OverflowBox(
                    alignment: Alignment.topCenter,
                    minHeight: 0,
                    maxHeight: double.infinity,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [for (final e in eventos) _chipEvento(e, mobile)],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Toque no número = novo evento naquele dia (como o link do PHP).
  Widget _numeroDia(int dia, bool ehHoje, DateTime data, bool mobile) {
    final tam = mobile ? 24.0 : 32.0;
    return Semantics(
      button: true,
      label: 'Adicionar evento no dia $dia',
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () => _abrirForm(data: data),
        child: Container(
          width: tam,
          height: tam,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: ehHoje ? CalCores.roxo : null,
            boxShadow: ehHoje
                ? const [
                    BoxShadow(
                      color: Color.fromRGBO(91, 24, 232, 0.35),
                      blurRadius: 12,
                      offset: Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Text(
            '$dia',
            style: TextStyle(
              fontSize: mobile ? 12 : 14,
              fontWeight: ehHoje ? FontWeight.w800 : FontWeight.w700,
              color: ehHoje ? Colors.white : CalCores.slate,
            ),
          ),
        ),
      ),
    );
  }

  Widget _chipEvento(Evento e, bool mobile) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: CalFaixa(
        corFaixa: e.tipo.cor,
        fundo: e.tipo.fundo,
        largura: mobile ? 3 : 4,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: mobile ? 4 : 8, vertical: mobile ? 3 : 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                e.titulo,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: mobile ? 9 : 11,
                  fontWeight: FontWeight.w700,
                  color: CalCores.texto,
                ),
              ),
              if (!mobile && e.hora != null)
                Text(
                  e.hora!,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: CalCores.cinza,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // -------------------------------------------------------------- legenda

  Widget _legenda(bool mobile) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: CalSombras.leve,
      ),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: mobile ? 16 : 28,
        runSpacing: 8,
        children: [
          for (final t in TipoEvento.values)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(color: t.cor, shape: BoxShape.circle),
                ),
                const SizedBox(width: 8),
                Text(
                  t.rotulo,
                  style: const TextStyle(
                    color: CalCores.slate,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

/// Substitui o hover do PHP (Editar / Excluir): no celular não existe hover,
/// então o toque no dia abre esta folha com os eventos e as ações.
class _DiaSheet extends StatelessWidget {
  const _DiaSheet({
    required this.dia,
    required this.eventos,
    required this.onNovo,
    required this.onEditar,
    required this.onExcluir,
  });

  final DateTime dia;
  final List<Evento> eventos;
  final VoidCallback onNovo;
  final void Function(Evento) onEditar;
  final void Function(Evento) onExcluir;

  @override
  Widget build(BuildContext context) {
    final titulo =
        '${_diasSemana[dia.weekday % 7]}, ${dia.day} de ${_meses[dia.month - 1].toLowerCase()}';
    final subtitulo = eventos.isEmpty
        ? 'Nenhum evento neste dia.'
        : (eventos.length == 1 ? '1 evento' : '${eventos.length} eventos');

    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.8),
      padding: EdgeInsets.fromLTRB(20, 12, 20, 20 + MediaQuery.paddingOf(context).bottom),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: CalCores.borda,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            titulo,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: CalCores.texto,
            ),
          ),
          const SizedBox(height: 4),
          Text(subtitulo, style: const TextStyle(color: CalCores.cinza, fontSize: 14)),
          const SizedBox(height: 12),
          if (eventos.isNotEmpty)
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: eventos.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (_, i) => _cartaoEvento(eventos[i]),
              ),
            ),
          const SizedBox(height: 16),
          CalBotaoGradiente(
            texto: '+ Novo evento neste dia',
            onPressed: onNovo,
            padding: const EdgeInsets.symmetric(vertical: 14),
            fontSize: 15,
          ),
        ],
      ),
    );
  }

  Widget _cartaoEvento(Evento e) {
    return CalFaixa(
      corFaixa: e.tipo.cor,
      fundo: e.tipo.fundo,
      raio: 10,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              e.titulo,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: CalCores.texto,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              e.hora == null ? e.tipo.rotulo : '${e.tipo.rotulo} • ${e.hora}',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: CalCores.cinza,
              ),
            ),
            if (e.descricao.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(e.descricao, style: const TextStyle(fontSize: 13, color: CalCores.slate)),
            ],
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => onEditar(e),
                  child: const Text(
                    'EDITAR',
                    style: TextStyle(
                      color: CalCores.roxo,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => onExcluir(e),
                  child: const Text(
                    'EXCLUIR',
                    style: TextStyle(
                      color: CalCores.erro,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
