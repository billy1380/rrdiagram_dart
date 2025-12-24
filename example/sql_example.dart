import 'package:rrdiagram_dart/rrdiagram_dart.dart';

void main() {
  // Construct the H2_SELECT grammar rule:
  // H2_SELECT = 'SELECT' [ 'TOP' term ] [ 'DISTINCT' | 'ALL' ] selectExpression {',' selectExpression} \
  // 'FROM' tableExpression {',' tableExpression} [ 'WHERE' expression ] \
  // [ 'GROUP BY' expression {',' expression} ] [ 'HAVING' expression ] \
  // [ ( 'UNION' [ 'ALL' ] | 'MINUS' | 'EXCEPT' | 'INTERSECT' ) select ] [ 'ORDER BY' order {',' order} ] \
  // [ 'LIMIT' expression [ 'OFFSET' expression ] [ 'SAMPLE_SIZE' rowCountInt ] ] \
  // [ 'FOR UPDATE' ];

  final h2select = Rule(
    "H2_SELECT",
    Sequence([
      Literal("SELECT"),
      Optional(Sequence([Literal("TOP"), RuleReference("term")])),
      Optional(Choice([Literal("DISTINCT"), Literal("ALL")])),
      // selectExpression {',' selectExpression}
      Sequence([
        RuleReference("selectExpression"),
        ZeroOrMore(Sequence([Literal(","), RuleReference("selectExpression")])),
      ]),
      Literal("FROM"),
      // tableExpression {',' tableExpression}
      Sequence([
        RuleReference("tableExpression"),
        ZeroOrMore(Sequence([Literal(","), RuleReference("tableExpression")])),
      ]),
      Optional(Sequence([Literal("WHERE"), RuleReference("expression")])),
      Optional(
        Sequence([
          Literal("GROUP BY"),
          RuleReference("expression"),
          ZeroOrMore(Sequence([Literal(","), RuleReference("expression")])),
        ]),
      ),
      Optional(Sequence([Literal("HAVING"), RuleReference("expression")])),
      Optional(
        Sequence([
          Choice([
            Sequence([Literal("UNION"), Optional(Literal("ALL"))]),
            Literal("MINUS"),
            Literal("EXCEPT"),
            Literal("INTERSECT"),
          ]),
          RuleReference("select"),
        ]),
      ),
      Optional(
        Sequence([
          Literal("ORDER BY"),
          RuleReference("order"),
          ZeroOrMore(Sequence([Literal(","), RuleReference("order")])),
        ]),
      ),
      Optional(
        Sequence([
          Literal("LIMIT"),
          RuleReference("expression"),
          Optional(Sequence([Literal("OFFSET"), RuleReference("expression")])),
          Optional(
            Sequence([Literal("SAMPLE_SIZE"), RuleReference("rowCountInt")]),
          ),
        ]),
      ),
      Optional(Literal("FOR UPDATE")),
    ]),
  );

  final grammarToRRDiagram = GrammarToRRDiagram();
  final rrDiagramToSVG = RRDiagramToSVG();

  // Convert and generate SVG
  final rrDiagram = grammarToRRDiagram.convert(h2select);
  final svg = rrDiagramToSVG.convert(rrDiagram);

  print(svg);
}
