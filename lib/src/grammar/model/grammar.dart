import "rule.dart";
import "grammar_to_bnf.dart";

class Grammar {
  final List<Rule> rules;

  Grammar(this.rules);

  String toBnf(GrammarToBnf grammarToBnf) {
    StringBuffer sb = StringBuffer();
    for (int i = 0; i < rules.length; i++) {
      if (i > 0) {
        sb.write("\n");
      }
      sb.write(rules[i].toBnf(grammarToBnf));
    }
    return sb.toString();
  }

  @override
  String toString() {
    return toBnf(GrammarToBnf());
  }
}
