import 'package:flutter/material.dart';

/// Cores extraídas de css/calendario.css e css/stylesheet.css
class CalCores {
  static const roxo = Color(0xFF5B18E8);
  static const indigo = Color(0xFF6366F1);
  static const ciano = Color(0xFF10B9D3);
  static const fundoApp = Color(0xFF6CB6FF); // body { background-color }
  static const texto = Color(0xFF111111);
  static const slate = Color(0xFF334155);
  static const cinza = Color(0xFF64748B);
  static const cinzaClaro = Color(0xFF94A3B8);
  static const borda = Color(0xFFE2E8F0);
  static const fundoClaro = Color(0xFFF8FAFC);
  static const erro = Color(0xFFE94B55);
  static const erroFundo = Color(0xFFFEE2E2);
  static const erroTexto = Color(0xFF991B1B);

  static const vazio = Color.fromRGBO(241, 245, 249, 0.6); // .cal-vazio
  static const hojeFundo = Color.fromRGBO(91, 24, 232, 0.05); // .cal-hoje
  static const roxoSuave = Color.fromRGBO(91, 24, 232, 0.1); // fundo do selo

  static const gradiente = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [indigo, roxo],
  );
}

class CalSombras {
  static const card = [
    BoxShadow(color: Color.fromRGBO(0, 0, 0, 0.08), blurRadius: 40, offset: Offset(0, 10)),
  ];
  static const leve = [
    BoxShadow(color: Color.fromRGBO(0, 0, 0, 0.05), blurRadius: 16, offset: Offset(0, 4)),
  ];
  static const botao = [
    BoxShadow(color: Color.fromRGBO(91, 24, 232, 0.25), blurRadius: 14, offset: Offset(0, 4)),
  ];
}

/// .cal-subtitulo / .cal-form-header span
class CalSelo extends StatelessWidget {
  const CalSelo(this.texto, {super.key, this.espacamento = 2.5});

  final String texto;
  final double espacamento;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: CalCores.roxoSuave,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        texto,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: espacamento,
          color: CalCores.roxo,
        ),
      ),
    );
  }
}

/// .cal-btn-novo / .cal-btn-salvar
class CalBotaoGradiente extends StatelessWidget {
  const CalBotaoGradiente({
    super.key,
    required this.texto,
    required this.onPressed,
    this.carregando = false,
    this.padding = const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
    this.fontSize = 14,
  });

  final String texto;
  final VoidCallback? onPressed;
  final bool carregando;
  final EdgeInsets padding;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final desativado = onPressed == null || carregando;
    return Opacity(
      opacity: desativado ? 0.7 : 1,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: CalCores.gradiente,
          borderRadius: BorderRadius.circular(12),
          boxShadow: CalSombras.botao,
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: desativado ? null : onPressed,
            child: Padding(
              padding: padding,
              child: Center(
                widthFactor: 1,
                child: carregando
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : Text(
                        texto,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: fontSize,
                        ),
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Bloco com faixa colorida na esquerda (border-left: 4px solid do CSS).
/// Feito com ClipRRect porque o Flutter não aceita borda só de um lado
/// junto com cantos arredondados.
class CalFaixa extends StatelessWidget {
  const CalFaixa({
    super.key,
    required this.corFaixa,
    required this.fundo,
    required this.child,
    this.largura = 4,
    this.raio = 6,
  });

  final Color corFaixa;
  final Color fundo;
  final Widget child;
  final double largura;
  final double raio;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(raio),
      child: DecoratedBox(
        decoration: BoxDecoration(color: fundo),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(width: largura, color: corFaixa),
              Expanded(child: child),
            ],
          ),
        ),
      ),
    );
  }
}
