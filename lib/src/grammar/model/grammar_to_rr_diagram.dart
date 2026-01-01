import "../rr_diagram/rr_diagram.dart";
import "rule.dart";
import "grammar.dart";

abstract class RuleLinkProvider {
  String getLink(String ruleName);
}

class DefaultRuleLinkProvider implements RuleLinkProvider {
  final String linkBase;

  DefaultRuleLinkProvider(this.linkBase);

  @override
  String getLink(String ruleName) {
    return "$linkBase$ruleName";
  }
}

class GrammarToRrDiagram {
  final String linkBase;
  late RuleLinkProvider ruleLinkProvider;
  String? ruleConsideredAsLineBreak;

  GrammarToRrDiagram({this.linkBase = "#"}) {
    ruleLinkProvider = DefaultRuleLinkProvider(linkBase);
  }

  RrDiagram convert(Rule rule) {
    return rule.toRrDiagram(this);
  }

  List<RrDiagram> convertGrammar(Grammar grammar) {
    return grammar.rules.map((rule) => convert(rule)).toList();
  }
}
