import '../rrdiagram/rr_element.dart';
import 'grammar_to_rr_diagram.dart';

abstract class Expression {
  RRElement toRRElement(GrammarToRRDiagram grammarToRRDiagram);

  // toBNF is skipped for this port as per plan
}

class Literal extends Expression {
  final String text;

  Literal(this.text);

  @override
  RRElement toRRElement(GrammarToRRDiagram grammarToRRDiagram) {
    return RRText(RRTextType.literal, text, null);
  }
}

class SpecialSequence extends Expression {
  final String text;

  SpecialSequence(this.text);

  @override
  RRElement toRRElement(GrammarToRRDiagram grammarToRRDiagram) {
    return RRText(RRTextType.specialSequence, text, null);
  }
}

class RuleReference extends Expression {
  final String ruleName;

  RuleReference(this.ruleName);

  @override
  RRElement toRRElement(GrammarToRRDiagram grammarToRRDiagram) {
    if (grammarToRRDiagram.ruleConsideredAsLineBreak == ruleName) {
      return RRBreak();
    }
    RuleLinkProvider ruleLinkProvider = grammarToRRDiagram.ruleLinkProvider;
    return RRText(
      RRTextType.rule,
      ruleName,
      ruleLinkProvider.getLink(ruleName),
    );
  }
}

class Sequence extends Expression {
  final List<Expression> expressions;

  Sequence(this.expressions);

  @override
  RRElement toRRElement(GrammarToRRDiagram grammarToRRDiagram) {
    List<RRElement> rrElementList = [];
    for (int i = 0; i < expressions.length; i++) {
      Expression expression = expressions[i];
      RRElement rrElement = expression.toRRElement(grammarToRRDiagram);

      // Treat special case of: "a (',' a)*" and "a (a)*"
      if (i < expressions.length - 1 &&
          expression is RuleReference &&
          expressions[i + 1] is Repetition) {
        RuleReference ruleLink = expression;
        Repetition repetition = expressions[i + 1] as Repetition;
        Expression repetitionExpression = repetition.expression;

        // Treat special case of: a (a)*
        if (repetitionExpression is RuleReference &&
            repetitionExpression.ruleName == ruleLink.ruleName) {
          int? maxRepetitionCount = repetition.maxRepetitionCount;
          if (maxRepetitionCount == null || maxRepetitionCount > 1) {
            rrElement = RRLoop(
              ruleLink.toRRElement(grammarToRRDiagram),
              null,
              repetition.minRepetitionCount,
              maxRepetitionCount,
            );
            i++;
          }
        } else if (repetitionExpression is Sequence) {
          // Treat special case of: a (',' a)*
          List<Expression> subExpressions = repetitionExpression.expressions;
          if (subExpressions.length == 2 &&
              subExpressions[0] is Literal &&
              subExpressions[1] is RuleReference &&
              (subExpressions[1] as RuleReference).ruleName ==
                  ruleLink.ruleName) {
            int? maxRepetitionCount = repetition.maxRepetitionCount;
            if (maxRepetitionCount == null || maxRepetitionCount > 1) {
              rrElement = RRLoop(
                ruleLink.toRRElement(grammarToRRDiagram),
                subExpressions[0].toRRElement(grammarToRRDiagram),
                repetition.minRepetitionCount,
                maxRepetitionCount,
              );
              i++;
            }
          }
        }
      }
      rrElementList.add(rrElement);
    }
    return RRSequence(rrElementList);
  }
}

class Choice extends Expression {
  final List<Expression> expressions;

  Choice(this.expressions);

  @override
  RRElement toRRElement(GrammarToRRDiagram grammarToRRDiagram) {
    List<RRElement> rrElements = expressions
        .map((e) => e.toRRElement(grammarToRRDiagram))
        .toList();
    return RRChoice(rrElements);
  }
}

class Repetition extends Expression {
  final Expression expression;
  final int minRepetitionCount;
  final int? maxRepetitionCount;

  Repetition(this.expression, this.minRepetitionCount, this.maxRepetitionCount);

  @override
  RRElement toRRElement(GrammarToRRDiagram grammarToRRDiagram) {
    RRElement rrElement = expression.toRRElement(grammarToRRDiagram);
    if (minRepetitionCount == 0) {
      if (maxRepetitionCount == null || maxRepetitionCount! > 1) {
        return RRChoice([
          RRLoop(
            rrElement,
            null,
            0,
            maxRepetitionCount == null ? null : maxRepetitionCount! - 1,
          ),
          RRLine(),
        ]);
      }
      return RRChoice([rrElement, RRLine()]);
    }
    return RRLoop(
      rrElement,
      null,
      minRepetitionCount - 1,
      maxRepetitionCount == null ? null : maxRepetitionCount! - 1,
    );
  }
}

class Optional extends Expression {
  final Expression expression;

  Optional(this.expression);

  @override
  RRElement toRRElement(GrammarToRRDiagram grammarToRRDiagram) {
    return Choice([expression, Sequence([])]).toRRElement(grammarToRRDiagram);
  }
}

class OneOrMore extends Expression {
  final Expression expression;

  OneOrMore(this.expression);

  @override
  RRElement toRRElement(GrammarToRRDiagram grammarToRRDiagram) {
    return Repetition(expression, 1, null).toRRElement(grammarToRRDiagram);
  }
}

class ZeroOrMore extends Expression {
  final Expression expression;

  ZeroOrMore(this.expression);

  @override
  RRElement toRRElement(GrammarToRRDiagram grammarToRRDiagram) {
    return Repetition(expression, 0, null).toRRElement(grammarToRRDiagram);
  }
}
