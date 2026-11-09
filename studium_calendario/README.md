# Studium — Calendário (Flutter)

Port do módulo `paginas/calendario` + `css/calendario.css` do StudiumScope (PHP).

## Como rodar
1. `flutter create studium_calendario` (ou use um projeto existente).
2. Copie a pasta `lib/` e o `pubspec.yaml` deste pacote por cima.
3. Em `lib/main.dart`, cole a **anon key** do Supabase
   (Project Settings → API → anon public).
4. `flutter pub get && flutter run`

## O que o app espera da tabela `calendario`
`id` (int, auto), `titulo`, `descricao`, `data_evento` (date), `hora` (time, null ok),
`tipo` ('Prova' | 'Trabalho' | 'Tarefa' | 'Outro'), `id_usuario` (int).

A tabela existente do projeto PHP já serve, sem mudanças.

## Row Level Security
Pela API do Supabase, a tabela precisa de policies de RLS (ou RLS desligado
para testes). Sem isso as consultas voltam vazias ou dão erro de permissão.

## Mapeamento PHP → Flutter
| PHP | Flutter |
|---|---|
| `CalendarioController` | `calendario_repository.dart` |
| `lista.php` | `calendario_page.dart` |
| `form.php` | `evento_form_page.dart` |
| `calendario.css` | `cal_estilo.dart` + estilos inline nas telas |
| hover Editar/Excluir | toque no dia abre uma folha com as ações |
