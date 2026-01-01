import "../rr_diagram/rr_diagram.dart";
import "expression.dart";
import "grammar_to_rr_diagram.dart";
import "grammar_to_bnf.dart";

class Rule {
  final String name;
  final Expression expression;

  Rule(this.name, this.expression);

  RrDiagram toRrDiagram(GrammarToRrDiagram grammarToRRDiagram) {
    return RrDiagram(expression.toRrElement(grammarToRRDiagram));
  }

  String toBnf(GrammarToBnf grammarToBNF) {
    StringBuffer sb = StringBuffer();
    sb.write(name);
    sb.write(" ");
    switch (grammarToBNF.ruleDefinitionSign) {
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
    expression.toBnf(grammarToBNF, sb, false);
    sb.write(";");
    return sb.toString();
  }

  @override
  String toString() {
    return toBnf(GrammarToBnf());
  }
}
