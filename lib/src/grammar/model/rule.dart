import "../rr_diagram/rr_diagram.dart";
import "expression.dart";
import "grammar_to_rr_diagram.dart";
import "grammar_to_bnf.dart";

class Rule {
  final String name;
  final Expression expression;

  Rule(this.name, this.expression);

  RrDiagram toRrDiagram(GrammarToRrDiagram grammarToRrDiagram) {
    return RrDiagram(expression.toRrElement(grammarToRrDiagram));
  }

  String toBnf(GrammarToBnf grammarToBnf) {
    StringBuffer sb = StringBuffer();
    sb.write(name);
    sb.write(" ");
    switch (grammarToBnf.ruleDefinitionSign) {
      case RuleDefinitionSign.equal:
        sb.write("=");
        break;
      case RuleDefinitionSign.colonEqual:
        sb.write(":=");
        break;
      case RuleDefinitionSign.colonColonEqual:
        sb.write("::=");
        break;
    }
    sb.write(" ");
    expression.toBnf(grammarToBnf, sb, false);
    sb.write(";");
    return sb.toString();
  }

  @override
  String toString() {
    return toBnf(GrammarToBnf());
  }
}
