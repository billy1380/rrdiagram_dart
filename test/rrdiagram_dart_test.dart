import 'package:rrdiagram_dart/rrdiagram_dart.dart';
import 'package:test/test.dart';

void main() {
  group('RRDiagram Generation', () {
    final grammarToRRDiagram = GrammarToRRDiagram();
    final rrDiagramToSVG = RRDiagramToSVG();

    test('Generates SVG for simple literal', () {
      final rule = Rule("test", Literal("hello"));
      final rrDiagram = grammarToRRDiagram.convert(rule);
      final svg = rrDiagramToSVG.convert(rrDiagram);

      expect(svg, startsWith('<svg'));
      expect(svg, contains('hello'));
      expect(svg, endsWith('</svg>'));
    });

    test('Generates SVG for sequence', () {
      final rule = Rule("seq", Sequence([Literal("a"), Literal("b")]));
      final rrDiagram = grammarToRRDiagram.convert(rule);
      final svg = rrDiagramToSVG.convert(rrDiagram);

      expect(svg, contains('>a<'));
      expect(svg, contains('>b<'));
    });

    test('Generates SVG for choice', () {
      final rule = Rule("choice", Choice([Literal("a"), Literal("b")]));
      final rrDiagram = grammarToRRDiagram.convert(rule);
      final svg = rrDiagramToSVG.convert(rrDiagram);

      expect(svg, contains('>a<'));
      expect(svg, contains('>b<'));
    });

    test('Generates SVG for repetition', () {
      final rule = Rule("rep", Repetition(Literal("a"), 1, 5));
      final rrDiagram = grammarToRRDiagram.convert(rule);
      final svg = rrDiagramToSVG.convert(rrDiagram);

      expect(svg, contains('>a<'));
      expect(svg, contains('>0..4<'));
    });

    test('Generates SVG for Optional', () {
      final rule = Rule("opt", Optional(Literal("a")));
      final rrDiagram = grammarToRRDiagram.convert(rule);
      final svg = rrDiagramToSVG.convert(rrDiagram);

      expect(svg, contains('>a<'));
    });

    test('Generates SVG for OneOrMore', () {
      final rule = Rule("oom", OneOrMore(Literal("a")));
      final rrDiagram = grammarToRRDiagram.convert(rule);
      final svg = rrDiagramToSVG.convert(rrDiagram);

      expect(svg, contains('>a<'));
      // OneOrMore(1, null) becomes RRLoop(0, null), which displays no cardinality text by default
    });

    test('Generates SVG for ZeroOrMore', () {
      final rule = Rule("zom", ZeroOrMore(Literal("a")));
      final rrDiagram = grammarToRRDiagram.convert(rule);
      final svg = rrDiagramToSVG.convert(rrDiagram);

      expect(svg, contains('>a<'));
    });

    test('Generates SVG for SpecialSequence', () {
      final rule = Rule("special", SpecialSequence("any char"));
      final rrDiagram = grammarToRRDiagram.convert(rule);
      final svg = rrDiagramToSVG.convert(rrDiagram);

      expect(svg, contains('any char'));
    });

    test('Generates SVG for RuleReference', () {
      final rule = Rule("ref", RuleReference("OtherRule"));
      final rrDiagram = grammarToRRDiagram.convert(rule);
      final svg = rrDiagramToSVG.convert(rrDiagram);

      expect(svg, contains('OtherRule'));
      expect(svg, contains('xlink:href="#OtherRule"'));
    });

    test('Optimizes sequence and repetition into loop with separator', () {
      // a (',' a)*
      final rule = Rule(
        "opt_loop",
        Sequence([
          RuleReference("a"),
          Repetition(Sequence([Literal(","), RuleReference("a")]), 0, null),
        ]),
      );
      final rrDiagram = grammarToRRDiagram.convert(rule);
      // RRLoop should be created with "," as loop element
      expect(rrDiagram.rrElement, isA<RRSequence>());
      final seq = rrDiagram.rrElement as RRSequence;
      expect(seq.rrElements[0], isA<RRLoop>());
      final loop = seq.rrElements[0] as RRLoop;
      expect(loop.loopElement, isA<RRText>());
      expect((loop.loopElement as RRText).text, equals(","));
    });
  });
}
