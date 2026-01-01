import "grammar.dart";

enum RuleDefinitionSign { equal, colonEqual, colonColonEqual }

enum LiteralDefinitionSign { quote, doubleQuote }

class GrammarToBnf {
  RuleDefinitionSign ruleDefinitionSign = RuleDefinitionSign.equal;
  LiteralDefinitionSign literalDefinitionSign = LiteralDefinitionSign.quote;
  bool isCommaSeparator = false;
  bool isUsingMultiplicationTokens = false;
  String? ruleConsideredAsLineBreak;

  String convert(Grammar grammar) {
    return grammar.toBnf(this);
  }
}
