import '../rrdiagram/rr_diagram.dart';
import 'rule.dart';
import 'grammar.dart';

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

class GrammarToRRDiagram {
  final String linkBase;
  late RuleLinkProvider ruleLinkProvider;
  String? ruleConsideredAsLineBreak;

  GrammarToRRDiagram({this.linkBase = "#"}) {
    ruleLinkProvider = DefaultRuleLinkProvider(linkBase);
  }

  RRDiagram convert(Rule rule) {
    return rule.toRRDiagram(this);
  }

  List<RRDiagram> convertGrammar(Grammar grammar) {
    return grammar.rules.map((rule) => convert(rule)).toList();
  }
}
