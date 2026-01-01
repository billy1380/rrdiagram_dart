import "package:rrdiagram_dart/rr_diagram_dart.dart";

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

  final grammarToRrDiagram = GrammarToRrDiagram();

  // Create the diagram generator config
  final rrDiagramToSvg = RrDiagramToSvg();

  // You can customize colors and fonts
  rrDiagramToSvg.ruleFillColor = const Color(200, 255, 200);

  // Generate the diagram
  final rrDiagram = grammarToRrDiagram.convert(rule);

  // Convert to SVG string
  final svg = rrDiagramToSvg.convert(rrDiagram);

  print(svg);
}
