# TimecodeCalc

Calculadora de timecode nativa para macOS (SwiftUI). Soma/subtração de timecodes,
conversão timecode ↔ frames, duração entre dois pontos e conversão entre frame
rates — para o dia a dia de montagem e finalização.

Feita na [Argonautas](https://argonautas.tv) (LAB de pós-produção, Brasília-DF).

## Recursos

- **Calculadora** — soma e subtração de timecodes (`CalculatorView`)
- **Conversão** timecode ↔ frames (`ConverterView`, `FramesView`)
- **Duração** entre dois timecodes (`DurationView`)
- **Frame rates** — 23.976, 24, 25, 29.97 (drop/non-drop), 30, 50, 59.94, 60
  (`FrameRate`, `Timecode`)

## Build & run

Requisitos: macOS 14+, Swift 5.9+.

```bash
swift run TimecodeCalc
```

## Licença

[MIT](LICENSE) — © 2026 Sérgio Azevedo / Argonautas.
