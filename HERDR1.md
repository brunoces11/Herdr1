# Herdr1

Personalizacao de Herdr 0.9.3, mantida na branch `herdr1`.
O repositorio `origin` e o Herdr1; `upstream` referencia o Herdr oficial.

## Customizacoes
- Indicadores de status do agente nas abas (experimental: erro nao e detectado separadamente).
- Largura estavel das abas (espaco reservado para indicador e botao de fechar).
- Botao `x` de fechar no hover da aba (oculto enquanto ha modal aberto).
- Windows: QuickEdit do console e desligado enquanto o Herdr roda (senao o conhost engole o mouse);
  o modo original e restaurado na saida.
- `herdr --version` identifica o build: `herdr 0.9.3 (herdr1 <data>-<commit>)` (ou `herdr1 dev`).
- `herdr update` desativado (instalaria o Herdr oficial por cima do fork).

## Ambientes
| Ambiente | Local | Uso |
|---|---|---|
| Herdr original | `~\.herdr\packages\standalone\releases\...` | reserva, intocado |
| Herdr1 codigo | `WCONFIG\HERDR1\herdr-src` | edicao e compilacao |
| Herdr1 teste | `target\...` + `WCONFIG\HERDR1\.sandbox` | validacao isolada |
| Herdr2 | `WCONFIG\HERDR2\current` | ambiente de trabalho (no PATH) |

## Scripts (`herdr1\`)
- `dev.ps1` - compila e abre o Herdr1 isolado; vigia o codigo (`-Once`, `-Fast`).
- `deploy.ps1` - exige codigo commitado, compila release marcado e publica em `HERDR2\current`.
- `usar-herdr2.ps1` / `usar-original.ps1` - trocam o `herdr` do PATH do usuario.

## Compilacao local
Rust (testado com 1.99.1), Zig **exatamente 0.16.0** (passado via `ZIG`) e MSVC com Windows SDK.
Os scripts localizam o Zig em `%LOCALAPPDATA%\zig-0.16.0\zig-x86_64-windows-0.16.0\zig.exe`.

## Testes
`cargo test --bin herdr`. Falha conhecida e pre-existente no Windows, sem relacao com o Herdr1:
`app::api::plugins::tests::windows_plugin_pane_commands_resolve_from_plugin_root_with_cwd_override`.
