import '../rrdiagram/rr_diagram.dart';
import 'expression.dart';
import 'grammar_to_rr_diagram.dart';

class Rule {
  final String name;
  final Expression expression;

  Rule(this.name, this.expression);

  RRDiagram toRRDiagram(GrammarToRRDiagram grammarToRRDiagram) {
    return RRDiagram(expression.toRRElement(grammarToRRDiagram));
  }
}
