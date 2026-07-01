# TimecodeCalc

Calculadora de timecode nativa para macOS (SwiftUI). Soma/subtração de timecodes,
conversão timecode ↔ frames, duração entre dois pontos e conversão entre frame
rates — para o dia a dia de montagem e finalização.

Feita na [Argonautas](https://argonautas.tv) (LAB de pós-produção, Brasília-DF).

## Recursos

- **Calculadora** — soma e subtração de timecodes, com acumulador tipo fita
  (**M+** encadeia somas, **MC** limpa) para totalizar durações de reels/cenas.
  Soma faz *wrap* em 24h como um contador de deck, com badge `+24h`.
- **Conversão** de frame rate em dois modos (`ConverterView`):
  - **Realtime** — preserva o instante no relógio (mudança de velocidade real)
  - **Frame** — preserva o índice de frame (conform / relabel entre cortes)
- **Frames** — timecode ↔ contagem de frames (`FramesView`)
- **Duração** entre dois timecodes (`DurationView`)
- **Colar timecode** — cole `01:02:03:04`, `01;02;03;04` ou `01020304`
  direto do Avid/Resolve em qualquer campo
- **Drop-frame correto** — valores DF ilegais (ex. `00:01:00;00`) são
  ajustados para o próximo TC válido, como no Avid
- **Frame rates** — 23.976, 24, 25, 29.97 (drop/non-drop), 30, 50, 59.94, 60

Atalhos: `⇧⌘C` copia o resultado · `⌘↵` adiciona à fita · `⌘⌫` limpa · `⌘1–4` alterna abas.

## Estrutura

- `Sources/TimecodeCore` — lógica pura de timecode (`Timecode`, `FrameRate`),
  sem SwiftUI, testável isoladamente
- `Sources/TimecodeCalc` — o app macOS (SwiftUI)
- `Sources/TimecodeCoreTests` — runner de testes

## Build & run

Requisitos: macOS 14+, Swift 5.9+.

```bash
swift run TimecodeCalc        # roda o app durante o desenvolvimento
swift run TimecodeCoreTests   # roda a suíte de testes (sem precisar de Xcode)
./build.sh --install          # monta o ArgoTimecode.app e instala em /Applications
```

O ícone do app é gerado por `swift Icon/make_icon.swift` (produz `Icon/AppIcon.png`,
convertido em `Icon/AppIcon.icns` via `iconutil`).

## Licença

[MIT](LICENSE) — © 2026 Sérgio Azevedo / Argonautas.
