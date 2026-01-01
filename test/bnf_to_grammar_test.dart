import "package:rrdiagram_dart/src/grammar/model/bnf_to_grammar.dart";
import "package:rrdiagram_dart/src/grammar/model/expression.dart";
import "package:rrdiagram_dart/src/grammar/model/grammar.dart";
import "package:rrdiagram_dart/src/grammar/model/grammar_to_bnf.dart";
import "package:rrdiagram_dart/src/grammar/model/grammar_to_rr_diagram.dart";
import "package:rrdiagram_dart/src/grammar/model/rule.dart";
import "package:rrdiagram_dart/src/grammar/rr_diagram/rr_diagram.dart";
import "package:rrdiagram_dart/src/grammar/rr_diagram/rr_diagram_to_svg.dart";
import "package:test/test.dart";

void main() {
  group("RrDiagramTests", () {
    test("testConsecutiveRuleReferencesSeparatedByNewline", () {
      expect(countElements("rect", svg("rule = a b\nc d\n\te;")), 5);
      expect(countElements("rect", svg("rule = a b\r\nc d\ne;")), 5);
    });

    test("testGrammarToString", () {
      expect(grammar("r = a b;").toString(), "r = a b;");
      expect(
        grammar("r1 = a b;\nr2 = c d;").toString(),
        "r1 = a b;\nr2 = c d;",
      );
    });

    test("testRuleToString", () {
      expect(rule("r = a b;").toString(), "r = a b;");
    });

    test("testChoiceToString", () {
      expect(
        Choice([RuleReference("a"), RuleReference("b")]).toString(),
        "a | b",
      );
    });

    test("testLiteralToString", () {
      expect(Literal("a").toString(), "'a'");
    });

    test("testRuleReferenceToString", () {
      expect(RuleReference("a").toString(), "a");
    });

    test("testSequenceToString", () {
      expect(
        Sequence([RuleReference("a"), RuleReference("b")]).toString(),
        "a b",
      );
    });

    test("testSpecialSequenceToString", () {
      expect(SpecialSequence("abc").toString(), "(? abc ?)");
    });

    test("testRepetitionToString", () {
      expect(Repetition(RuleReference("a"), 0, null).toString(), "{ a }");
      expect(Repetition(RuleReference("a"), 0, 1).toString(), "[ a ]");
      expect(Repetition(RuleReference("a"), 0, 2).toString(), "2 * [ a ]");
    });

    test("testConversionsToBnf", () {
      String bnf1 =
          "BNF1 = a*;"
          "BNF2 = a+;"
          "BNF3 = a?;"
          "BNF4 = a (',' a)*;"
          "BNF5 = 3 * a;"
          "BNF6 = 3 * a?;"
          "BNF7 = a 3 * (',' a);"
          "BNF8 = a 3 * (',' a)?;"
          "BNF9 = a (? [a-zA-Z]+ ?) 3 * (',' a)?;"
          "BNF10 = a | c | ();"
          "BNF11 = 3 * 'a<b\"';";
      Grammar grammar1 = grammar(bnf1);
      GrammarToBnf grammarToBnf = GrammarToBnf();
      String bnf2 = grammarToBnf.convert(grammar1);

      Grammar grammar2 = grammar(bnf2);
      List<Rule> rules1 = grammar1.rules;
      List<Rule> rules2 = grammar2.rules;
      expect(rules2.length, rules1.length);
      GrammarToRrDiagram grammarToRrDiagram = GrammarToRrDiagram();
      RrDiagramToSvg rrDiagramToSvg = RrDiagramToSvg();
      for (int i = 0; i < rules1.length; i++) {
        Rule rule1 = rules1[i];
        Rule rule2 = rules2[i];
        expect(rule2.name, rule1.name, reason: "Rules have same name");
        RrDiagram diagram1 = grammarToRrDiagram.convert(rule1);
        String svg1 = rrDiagramToSvg.convert(diagram1);
        RrDiagram diagram2 = grammarToRrDiagram.convert(rule2);
        String svg2 = rrDiagramToSvg.convert(diagram2);
        expect(svg2, svg1, reason: "SVG for \"${rule1.name}\" are identical");
      }
    });
  });
}

// Test utilities

String svg(String string) {
  Grammar g = grammar(string);
  List<Rule> rules = g.rules;
  GrammarToRrDiagram grammarToRrDiagram = GrammarToRrDiagram();
  RrDiagram diagram = grammarToRrDiagram.convert(rules[0]);
  RrDiagramToSvg rrDiagramToSvg = RrDiagramToSvg();
  String svg = rrDiagramToSvg.convert(diagram);
  return svg;
}

Grammar grammar(String string) {
  BnfToGrammar bnfToGrammar = BnfToGrammar();
  Grammar grammar = bnfToGrammar.convert(string);
  return grammar;
}

Rule rule(String string) {
  return grammar(string).rules[0];
}

int countElements(String tagName, String svg) {
  // Simple regex count to avoid XML dependency
  String pattern = "<$tagName";
  return pattern.allMatches(svg).length;
}
