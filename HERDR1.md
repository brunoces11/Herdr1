# Herdr1

Personalizacao experimental de Herdr 0.9.3, mantida na branch `herdr1`.
O repositorio `origin` e o Herdr1; `upstream` referencia o Herdr oficial.

O fluxo manual **Herdr1 Windows (experimental)** no GitHub Actions compila
no Windows, executa o teste dos indicadores e disponibiliza o executavel
como artefato. O executavel ainda se chama `herdr.exe` para preservar as
expectativas internas do programa. A compilacao nao instala nem atualiza o
Herdr existente; o artefato ainda precisa de testes em sessao isolada.

Para compilar localmente sao necessarios Rust 1.96.1, Zig 0.16.0 e o MSVC
com Windows SDK, conforme a documentacao do Herdr. Execute `cargo build
--release --locked --target x86_64-pc-windows-msvc` no diretorio deste arquivo.
As dependencias e os arquivos gerados nao sao enviados ao repositorio.

Os indicadores sao experimentais: erro nao e detectado separadamente, e a
apresentacao e o reconhecimento de conclusao ainda precisam de teste real.
