import 'package:flutter/material.dart';

import 'cal_estilo.dart';
import 'calendario_repository.dart';
import 'evento.dart';

class EventoFormPage extends StatefulWidget {
  const EventoFormPage({
    super.key,
    required this.repo,
    this.evento,
    required this.dataInicial,
  });

  final CalendarioRepository repo;
  final Evento? evento; // null = novo evento
  final DateTime dataInicial;

  @override
  State<EventoFormPage> createState() => _EventoFormPageState();
}

class _EventoFormPageState extends State<EventoFormPage> {
  late final TextEditingController _tituloCtrl;
  late final TextEditingController _descCtrl;
  late DateTime _data;
  String? _hora; // "HH:mm"
  TipoEvento? _tipo;
  bool _erro = false;
  bool _salvando = false;

  bool get _editando => widget.evento != null;

  @override
  void initState() {
    super.initState();
    final e = widget.evento;
    final d = widget.dataInicial;
    _tituloCtrl = TextEditingController(text: e?.titulo ?? '');
    _descCtrl = TextEditingController(text: e?.descricao ?? '');
    _data = e?.data ?? DateTime(d.year, d.month, d.day);
    _hora = e?.hora;
    _tipo = e?.tipo;
  }

  @override
  void dispose() {
    _tituloCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  String _dois(int n) => n.toString().padLeft(2, '0');
  String _dataBr(DateTime d) => '${_dois(d.day)}/${_dois(d.month)}/${d.year}';

  Future<void> _escolherData() async {
    final r = await showDatePicker(
      context: context,
      initialDate: _data,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      helpText: 'Selecione a data',
    );
    if (r != null && mounted) setState(() => _data = DateTime(r.year, r.month, r.day));
  }

  Future<void> _escolherHora() async {
    final partes = _hora?.split(':');
    final inicial = partes != null
        ? TimeOfDay(hour: int.parse(partes[0]), minute: int.parse(partes[1]))
        : TimeOfDay.now();

    final r = await showTimePicker(
      context: context,
      initialTime: inicial,
      helpText: 'Selecione o horário',
      builder: (ctx, child) => MediaQuery(
        data: MediaQuery.of(ctx).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (r != null && mounted) setState(() => _hora = '${_dois(r.hour)}:${_dois(r.minute)}');
  }

  Future<void> _salvar() async {
    final titulo = _tituloCtrl.text.trim();
    // mesma regra do PHP: título, data e tipo obrigatórios
    if (titulo.isEmpty || _tipo == null) {
      setState(() => _erro = true);
      return;
    }

    setState(() {
      _erro = false;
      _salvando = true;
    });

    final evento = Evento(
      id: widget.evento?.id,
      titulo: titulo,
      descricao: _descCtrl.text.trim(),
      data: _data,
      hora: _hora,
      tipo: _tipo!,
    );

    try {
      await widget.repo.salvar(evento);
      if (!mounted) return;
      Navigator.pop(context, _data); // o calendário pula para o mês salvo
    } catch (_) {
      if (!mounted) return;
      setState(() => _salvando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível salvar o evento.')),
      );
    }
  }

  // ---------------------------------------------------------------- build

  @override
  Widget build(BuildContext context) {
    final mobile = MediaQuery.sizeOf(context).width <= 600;

    final horario = _campo(
      'Horário',
      _seletor(
        texto: _hora ?? '--:--',
        vazio: _hora == null,
        icone: Icons.schedule,
        onTap: _escolherHora,
        onLimpar: _hora == null ? null : () => setState(() => _hora = null),
      ),
    );
    final tipo = _campo('Tipo', _dropdownTipo());

    return Scaffold(
      backgroundColor: CalCores.fundoApp,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: mobile ? 12 : 20, vertical: mobile ? 20 : 40),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: Container(
                padding: EdgeInsets.all(mobile ? 25 : 40),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: const [
                    BoxShadow(
                      color: Color.fromRGBO(0, 0, 0, 0.1),
                      blurRadius: 40,
                      offset: Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    InkWell(
                      onTap: () => Navigator.pop(context),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 4),
                        child: Text(
                          '← Voltar para o calendário',
                          style: TextStyle(
                            color: CalCores.cinza,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const CalSelo('CALENDÁRIO', espacamento: 2),
                    const SizedBox(height: 12),
                    Text(
                      _editando ? 'Editar Evento' : 'Novo Evento',
                      style: TextStyle(
                        fontSize: mobile ? 22 : 28,
                        fontWeight: FontWeight.w800,
                        color: CalCores.texto,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Adicione uma informação importante ao seu calendário.',
                      style: TextStyle(color: CalCores.cinza, fontSize: 14),
                    ),
                    const SizedBox(height: 30),
                    if (_erro) _alerta(),
                    _campo(
                      'Título',
                      TextField(
                        controller: _tituloCtrl,
                        maxLength: 150,
                        autofocus: !_editando,
                        textCapitalization: TextCapitalization.sentences,
                        style: const TextStyle(fontSize: 15),
                        decoration: _decoracao('Ex.: Prova de Matemática'),
                      ),
                    ),
                    _campo(
                      'Descrição',
                      TextField(
                        controller: _descCtrl,
                        minLines: 4,
                        maxLines: 4,
                        keyboardType: TextInputType.multiline,
                        textCapitalization: TextCapitalization.sentences,
                        style: const TextStyle(fontSize: 15),
                        decoration: _decoracao('Adicione os detalhes do evento...'),
                      ),
                    ),
                    _campo(
                      'Data',
                      _seletor(
                        texto: _dataBr(_data),
                        vazio: false,
                        icone: Icons.calendar_today,
                        onTap: _escolherData,
                      ),
                    ),
                    if (mobile) ...[horario, tipo] else
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: horario),
                          const SizedBox(width: 16),
                          Expanded(child: tipo),
                        ],
                      ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: Material(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(12),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: _salvando ? null : () => Navigator.pop(context),
                              child: const Padding(
                                padding: EdgeInsets.symmetric(vertical: 14),
                                child: Center(
                                  child: Text(
                                    'Cancelar',
                                    style: TextStyle(
                                      color: Color(0xFF475569),
                                      fontWeight: FontWeight.w700,
                                      fontSize: 15,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: CalBotaoGradiente(
                            texto: _editando ? 'Salvar' : 'Adicionar',
                            carregando: _salvando,
                            onPressed: _salvar,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // -------------------------------------------------------------- helpers

  /// .cal-alerta
  Widget _alerta() {
    return const Padding(
      padding: EdgeInsets.only(bottom: 20),
      child: CalFaixa(
        corFaixa: CalCores.erro,
        fundo: CalCores.erroFundo,
        raio: 12,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          child: Text(
            'Preencha o título, a data e o tipo do evento.',
            style: TextStyle(
              color: CalCores.erroTexto,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  /// .cal-campo (rótulo em caixa alta + campo)
  Widget _campo(String rotulo, Widget filho) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            rotulo.toUpperCase(),
            style: const TextStyle(
              color: CalCores.slate,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 8),
          filho,
        ],
      ),
    );
  }

  OutlineInputBorder _borda(Color cor) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: cor, width: 2),
      );

  InputDecoration _decoracao(String dica) {
    return InputDecoration(
      hintText: dica,
      hintStyle: const TextStyle(color: CalCores.cinzaClaro),
      filled: true,
      fillColor: CalCores.fundoClaro,
      counterText: '',
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      border: _borda(CalCores.borda),
      enabledBorder: _borda(CalCores.borda),
      focusedBorder: _borda(CalCores.roxo),
    );
  }

  BoxDecoration get _caixaCampo => BoxDecoration(
        color: CalCores.fundoClaro,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: CalCores.borda, width: 2),
      );

  Widget _seletor({
    required String texto,
    required bool vazio,
    required IconData icone,
    required VoidCallback onTap,
    VoidCallback? onLimpar,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        decoration: _caixaCampo,
        child: Row(
          children: [
            Expanded(
              child: Text(
                texto,
                style: TextStyle(
                  fontSize: 15,
                  color: vazio ? CalCores.cinzaClaro : CalCores.texto,
                ),
              ),
            ),
            if (onLimpar != null)
              InkWell(
                customBorder: const CircleBorder(),
                onTap: onLimpar,
                child: const Padding(
                  padding: EdgeInsets.all(2),
                  child: Icon(Icons.close, size: 18, color: CalCores.cinza),
                ),
              ),
            const SizedBox(width: 6),
            Icon(icone, size: 18, color: CalCores.cinza),
          ],
        ),
      ),
    );
  }

  Widget _dropdownTipo() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: _caixaCampo,
      child: DropdownButtonHideUnderline(
        child: DropdownButton<TipoEvento>(
          isExpanded: true,
          value: _tipo,
          borderRadius: BorderRadius.circular(12),
          icon: const Icon(Icons.expand_more, color: CalCores.cinza),
          hint: const Text(
            'Selecione',
            style: TextStyle(fontSize: 15, color: CalCores.cinzaClaro),
          ),
          items: [
            for (final t in TipoEvento.values)
              DropdownMenuItem(
                value: t,
                child: Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(color: t.cor, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 10),
                    Text(t.rotulo, style: const TextStyle(fontSize: 15, color: CalCores.texto)),
                  ],
                ),
              ),
          ],
          onChanged: (v) => setState(() => _tipo = v),
        ),
      ),
    );
  }
}
