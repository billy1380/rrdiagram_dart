import "../rr_diagram/rr_element.dart";
import "grammar_to_rr_diagram.dart";
import "grammar_to_bnf.dart";

abstract class Expression {
  RrElement toRrElement(GrammarToRrDiagram grammarToRrDiagram);

  void toBnf(GrammarToBnf grammarToBnf, StringBuffer sb, bool isNested);

  @override
  String toString() {
    StringBuffer sb = StringBuffer();
    toBnf(GrammarToBnf(), sb, false);
    return sb.toString();
  }
}

class Literal extends Expression {
  final String text;

  Literal(this.text);

  @override
  RrElement toRrElement(GrammarToRrDiagram grammarToRrDiagram) {
    return RrText(RrTextType.literal, text, null);
  }

  @override
  void toBnf(GrammarToBnf grammarToBnf, StringBuffer sb, bool isNested) {
    String c =
        grammarToBnf.literalDefinitionSign == LiteralDefinitionSign.doubleQuote
        ? '"'
        : "'";
    sb.write(c);
    sb.write(text);
    sb.write(c);
  }
}

class SpecialSequence extends Expression {
  final String text;

  SpecialSequence(this.text);

  @override
  RrElement toRrElement(GrammarToRrDiagram grammarToRrDiagram) {
    return RrText(RrTextType.specialSequence, text, null);
  }

  @override
  void toBnf(GrammarToBnf grammarToBnf, StringBuffer sb, bool isNested) {
    sb.write("(? ");
    sb.write(text);
    sb.write(" ?)");
  }
}

class RuleReference extends Expression {
  final String ruleName;

  RuleReference(this.ruleName);

  @override
  RrElement toRrElement(GrammarToRrDiagram grammarToRrDiagram) {
    if (grammarToRrDiagram.ruleConsideredAsLineBreak == ruleName) {
      return RrBreak();
    }
    RuleLinkProvider ruleLinkProvider = grammarToRrDiagram.ruleLinkProvider;
    return RrText(
      RrTextType.rule,
      ruleName,
      ruleLinkProvider.getLink(ruleName),
    );
  }

  @override
  void toBnf(GrammarToBnf grammarToBnf, StringBuffer sb, bool isNested) {
    sb.write(ruleName);
    String? ruleConsideredAsLineBreak = grammarToBnf.ruleConsideredAsLineBreak;
    if (ruleConsideredAsLineBreak != null &&
        ruleConsideredAsLineBreak == ruleName) {
      sb.write("\n");
    }
  }
}

class Sequence extends Expression {
  final List<Expression> expressions;

  Sequence(this.expressions);

  @override
  RrElement toRrElement(GrammarToRrDiagram grammarToRrDiagram) {
    List<RrElement> rrElementList = [];
    for (int i = 0; i < expressions.length; i++) {
      Expression expression = expressions[i];
      RrElement rrElement = expression.toRrElement(grammarToRrDiagram);

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
            rrElement = RrLoop(
              ruleLink.toRrElement(grammarToRrDiagram),
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
              rrElement = RrLoop(
                ruleLink.toRrElement(grammarToRrDiagram),
                subExpressions[0].toRrElement(grammarToRrDiagram),
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
    return RrSequence(rrElementList);
  }

  @override
  void toBnf(GrammarToBnf grammarToBnf, StringBuffer sb, bool isNested) {
    if (expressions.isEmpty) {
      sb.write("( )");
      return;
    }
    if (isNested && expressions.length > 1) {
      sb.write("( ");
    }
    bool isCommaSeparator = grammarToBnf.isCommaSeparator;
    for (int i = 0; i < expressions.length; i++) {
      if (i > 0) {
        if (isCommaSeparator) {
          sb.write(" ,");
        }
        sb.write(" ");
      }
      expressions[i].toBnf(
        grammarToBnf,
        sb,
        expressions.length == 1 && isNested || !isCommaSeparator,
      );
    }
    if (isNested && expressions.length > 1) {
      sb.write(" )");
    }
  }
}

class Choice extends Expression {
  final List<Expression> expressions;

  Choice(this.expressions);

  @override
  RrElement toRrElement(GrammarToRrDiagram grammarToRrDiagram) {
    List<RrElement> rrElements = expressions
        .map((e) => e.toRrElement(grammarToRrDiagram))
        .toList();
    return RrChoice(rrElements);
  }

  @override
  void toBnf(GrammarToBnf grammarToBnf, StringBuffer sb, bool isNested) {
    List<Expression> expressionList = [];
    bool hasNoop = false;
    for (Expression expression in expressions) {
      if (expression is Sequence && expression.expressions.isEmpty) {
        hasNoop = true;
      } else {
        expressionList.add(expression);
      }
    }
    if (expressionList.isEmpty) {
      sb.write("( )");
    } else if (hasNoop && expressionList.length == 1) {
      bool isUsingMultiplicationTokens =
          grammarToBnf.isUsingMultiplicationTokens;
      if (!isUsingMultiplicationTokens) {
        sb.write("[ ");
      }
      expressionList[0].toBnf(grammarToBnf, sb, isUsingMultiplicationTokens);
      if (!isUsingMultiplicationTokens) {
        sb.write(" ]");
      }
    } else {
      bool isUsingMultiplicationTokens =
          grammarToBnf.isUsingMultiplicationTokens;
      if (hasNoop && !isUsingMultiplicationTokens) {
        sb.write("[ ");
      } else if (hasNoop || isNested && expressionList.length > 1) {
        sb.write("( ");
      }
      int count = expressionList.length;
      for (int i = 0; i < count; i++) {
        if (i > 0) {
          sb.write(" | ");
        }
        expressionList[i].toBnf(grammarToBnf, sb, false);
      }
      if (hasNoop && !isUsingMultiplicationTokens) {
        sb.write(" ]");
      } else if (hasNoop || isNested && expressionList.length > 1) {
        sb.write(" )");
        if (hasNoop) {
          sb.write("?");
        }
      }
    }
  }
}

class Repetition extends Expression {
  final Expression expression;
  final int minRepetitionCount;
  final int? maxRepetitionCount;

  Repetition(this.expression, this.minRepetitionCount, this.maxRepetitionCount);

  @override
  RrElement toRrElement(GrammarToRrDiagram grammarToRrDiagram) {
    RrElement rrElement = expression.toRrElement(grammarToRrDiagram);
    if (minRepetitionCount == 0) {
      if (maxRepetitionCount == null || maxRepetitionCount! > 1) {
        return RrChoice([
          RrLoop(
            rrElement,
            null,
            0,
            maxRepetitionCount == null ? null : maxRepetitionCount! - 1,
          ),
          RrLine(),
        ]);
      }
      return RrChoice([rrElement, RrLine()]);
    }
    return RrLoop(
      rrElement,
      null,
      minRepetitionCount - 1,
      maxRepetitionCount == null ? null : maxRepetitionCount! - 1,
    );
  }

  @override
  void toBnf(GrammarToBnf grammarToBnf, StringBuffer sb, bool isNested) {
    bool isUsingMultiplicationTokens = grammarToBnf.isUsingMultiplicationTokens;
    if (maxRepetitionCount == null) {
      if (minRepetitionCount > 0) {
        if (minRepetitionCount == 1 && isUsingMultiplicationTokens) {
          expression.toBnf(grammarToBnf, sb, true);
          sb.write("+");
        } else {
          if (isNested) {
            sb.write("( ");
          }
          if (minRepetitionCount > 1) {
            sb.write("$minRepetitionCount");
            sb.write(" * ");
          }
          expression.toBnf(grammarToBnf, sb, false);
          if (grammarToBnf.isCommaSeparator) {
            sb.write(" ,");
          }
          sb.write(" ");
          sb.write("{ ");
          expression.toBnf(grammarToBnf, sb, false);
          sb.write(" }");
          if (isNested) {
            sb.write(" )");
          }
        }
      } else {
        if (isUsingMultiplicationTokens) {
          expression.toBnf(grammarToBnf, sb, true);
          sb.write("*");
        } else {
          sb.write("{ ");
          expression.toBnf(grammarToBnf, sb, false);
          sb.write(" }");
        }
      }
    } else {
      if (minRepetitionCount == 0) {
        if (maxRepetitionCount == 1 && isUsingMultiplicationTokens) {
          expression.toBnf(grammarToBnf, sb, true);
          sb.write("?");
        } else {
          if (maxRepetitionCount! > 1) {
            sb.write("$maxRepetitionCount");
            sb.write(" * ");
          }
          sb.write("[ ");
          expression.toBnf(grammarToBnf, sb, false);
          sb.write(" ]");
        }
      } else {
        if (minRepetitionCount == maxRepetitionCount) {
          sb.write("$minRepetitionCount");
          sb.write(" * ");
          expression.toBnf(grammarToBnf, sb, isNested);
        } else {
          if (isNested) {
            sb.write("( ");
          }
          sb.write("$minRepetitionCount");
          sb.write(" * ");
          expression.toBnf(grammarToBnf, sb, false);
          if (grammarToBnf.isCommaSeparator) {
            sb.write(" ,");
          }
          sb.write(" ");
          sb.write("${maxRepetitionCount! - minRepetitionCount}");
          sb.write(" * ");
          sb.write("[ ");
          expression.toBnf(grammarToBnf, sb, false);
          sb.write(" ]");
          if (isNested) {
            sb.write(" )");
          }
        }
      }
    }
  }
}

class Optional extends Expression {
  final Expression expression;

  Optional(this.expression);

  @override
  RrElement toRrElement(GrammarToRrDiagram grammarToRrDiagram) {
    return Choice([expression, Sequence([])]).toRrElement(grammarToRrDiagram);
  }

  @override
  void toBnf(GrammarToBnf grammarToBnf, StringBuffer sb, bool isNested) {
    Choice([expression, Sequence([])]).toBnf(grammarToBnf, sb, isNested);
  }
}

class OneOrMore extends Expression {
  final Expression expression;

  OneOrMore(this.expression);

  @override
  RrElement toRrElement(GrammarToRrDiagram grammarToRrDiagram) {
    return Repetition(expression, 1, null).toRrElement(grammarToRrDiagram);
  }

  @override
  void toBnf(GrammarToBnf grammarToBnf, StringBuffer sb, bool isNested) {
    Repetition(expression, 1, null).toBnf(grammarToBnf, sb, isNested);
  }
}

class ZeroOrMore extends Expression {
  final Expression expression;

  ZeroOrMore(this.expression);

  @override
  RrElement toRrElement(GrammarToRrDiagram grammarToRrDiagram) {
    return Repetition(expression, 0, null).toRrElement(grammarToRrDiagram);
  }

  @override
  void toBnf(GrammarToBnf grammarToBnf, StringBuffer sb, bool isNested) {
    Repetition(expression, 0, null).toBnf(grammarToBnf, sb, isNested);
  }
}
