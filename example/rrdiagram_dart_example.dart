import 'package:rrdiagram_dart/rrdiagram_dart.dart';

void main() {
  // Define a complex grammar rule
  final rule = Rule(
    "MyComplexRule",
    Sequence([
      Literal("BEGIN"),
      Choice([
        Literal("Option1"),
        Literal("Option2"),
        Optional(Literal("OptionalPart")),
      ]),
      // This will be optimized into a loop with "," as separator
      RuleReference("Item"),
      ZeroOrMore(Sequence([Literal(","), RuleReference("Item")])),
      OneOrMore(Literal("Extra")),
      Literal("END"),
    ]),
  );

  final grammarToRRDiagram = GrammarToRRDiagram();

  // Create the diagram generator config
  final rrDiagramToSVG = RRDiagramToSVG();

  // You can customize colors and fonts
  rrDiagramToSVG.ruleFillColor = const Color(200, 255, 200);

  // Generate the diagram
  final rrDiagram = grammarToRRDiagram.convert(rule);

  // Convert to SVG string
  final svg = rrDiagramToSVG.convert(rrDiagram);

  print(svg);
}
