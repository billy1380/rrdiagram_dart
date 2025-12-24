# rrdiagram_dart

A Dart library for generating Railroad Diagrams (also known as Syntax Diagrams) from grammar rules. This is a port of the [RRDiagram](https://github.com/bramp/rrdiagram) Java library.

It allows you to programmatically define grammar rules (Sequence, Choice, Repetition, etc.) and generate high-quality SVG images representing them.

## Features

- **Grammar Definition**: Define grammars using a simple object model (`Sequence`, `Choice`, `Repetition`, `Optional`, `Literal`, `Rule`).
- **SVG Export**: distinct rendering of rules to SVG format.
- **Customizable**: Control colors, fonts, and shapes of the diagram elements.
- **Text Measurement**: Pluggable `TextMeasurer` to ensure correct sizing of elements depending on the environment (CLI, Web, Flutter).

## Installation

Add `rrdiagram_dart` to your `pubspec.yaml`:

```yaml
dependencies:
  rrdiagram_dart: ^1.0.0
```

## Usage

Here is a simple example showing how to define a rule and generate an SVG.

```dart
import 'package:rrdiagram_dart/rrdiagram_dart.dart';

void main() {
  // Define a grammar rule: rule = 'a' | 'b' | ('Start' 'Repeated'{1,5} 'End');
  final rule = Rule(
    "TestRule",
    Choice([
      Literal("a"),
      Literal("b"),
      Sequence([
        Literal("Start"),
        Repetition(Literal("Repeated"), 1, 5),
        Literal("End")
      ])
    ])
  );

  // 1. Convert the Grammar Rule to a Railroad Diagram model
  final grammarToRRDiagram = GrammarToRRDiagram();
  final rrDiagram = grammarToRRDiagram.convert(rule);
  
  // 2. Convert the Railroad Diagram to SVG
  final rrDiagramToSVG = RRDiagramToSVG();
  final svg = rrDiagramToSVG.convert(rrDiagram);

  print(svg);
}
```

### Text Measuring

The library needs to know the size of the text to properly layout the diagram.
By default, it uses `EstimatedTextMeasurer` which estimates the width based on character count. This works for simple CLI tools but might not be pixel-perfect.

For accurate results, especially if you use non-standard fonts, implement the `TextMeasurer` interface.

```dart
class MyExactMeasurer implements TextMeasurer {
  @override
  double measure(String text, Font font) {
    // specific implementation (e.g., using Flutter's TextPainter or HTML Canvas)
    return ...;
  }
}

final rrDiagramToSVG = RRDiagramToSVG(textMeasurer: MyExactMeasurer());
```

## Contributing

Contributions are welcome! Please file issues or send pull requests.

## License

See LICENSE file (if available) or checking the repository settings.