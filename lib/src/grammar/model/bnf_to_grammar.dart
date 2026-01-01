import "grammar.dart";
import "rule.dart";
import "expression.dart";

class BnfToGrammar {
  Grammar convert(String text) {
    var reader = _StringReader(text);
    var sb = StringBuffer();
    List<Rule> ruleList = [];
    int x;
    while ((x = reader.read()) != -1) {
      var c = String.fromCharCode(x);
      switch (c) {
        case "=":
          {
            var chunk = _Chunk(_ChunkType.group);
            _loadExpression(chunk, reader, ";");
            String ruleName = sb.toString();
            sb.clear();
            if (ruleName.endsWith(":")) {
              ruleName = ruleName.substring(0, ruleName.length - 1);
              if (ruleName.endsWith(":")) {
                ruleName = ruleName.substring(0, ruleName.length - 1);
              }
            }
            ruleName = ruleName.trim();
            ruleList.add(_createRule(ruleName, chunk));
            break;
          }
        // Consider that '(' in rule name is start of a comment.
        case "(":
          {
            if (reader.read() != "*".codeUnitAt(0)) {
              throw StateError(
                "Expecting start of a comment after '(' but could not find '*'!",
              );
            }
            int lastChar = 0;
            int x2;
            while ((x2 = reader.read()) != -1) {
              int c2 = x2;
              if (c2 == ")".codeUnitAt(0) && lastChar == "*".codeUnitAt(0)) {
                break;
              }
              lastChar = c2;
            }
            break;
          }
        default:
          {
            if (c.trim().isNotEmpty || sb.isNotEmpty) {
              sb.write(c);
            }
            break;
          }
      }
    }
    return Grammar(ruleList);
  }

  static Rule _createRule(String name, _Chunk chunk) {
    chunk.prune();
    Expression expression = chunk.getExpression();
    return Rule(name, expression);
  }

  static void _loadExpression(
    _Chunk parentChunk,
    _StringReader reader,
    String stopChar,
  ) {
    int lastChar = 0;
    var sb = StringBuffer();
    bool isFirst = true;
    bool isInSpecialGroup = false;
    int specialGroupChar = 0;
    bool isLiteral = parentChunk.getType() == _ChunkType.literal;
    int x;
    while ((x = reader.read()) != -1) {
      String c = String.fromCharCode(x);
      if (isLiteral) {
        if (c == stopChar) {
          String s = sb.toString();
          parentChunk.setText(s);
          return;
        }
        sb.write(c);
      } else {
        if (isFirst && parentChunk.getType() == _ChunkType.group) {
          switch (c) {
            case "*":
              isInSpecialGroup = true;
              specialGroupChar = c.codeUnitAt(0);
              break;
            case "?":
              isInSpecialGroup = true;
              specialGroupChar = c.codeUnitAt(0);
              break;
          }
        }
        isFirst = false;
        if (isInSpecialGroup) {
          if (c == ")" && lastChar == specialGroupChar) {
            // Mutate parent group
            switch (String.fromCharCode(specialGroupChar)) {
              case "*":
                parentChunk.setType(_ChunkType.comment);
                break;
              case "?":
                parentChunk.setType(_ChunkType.specialSerquence);
                break;
            }
            String comment = sb.toString();
            comment = comment.substring(1, comment.length - 1).trim();
            parentChunk.setText(comment);
            return;
          }
          if (sb.isNotEmpty || c.trim().isNotEmpty) {
            sb.write(c);
          }
        } else {
          if (c == stopChar) {
            String content = sb.toString().trim();
            if (content.isNotEmpty) {
              parentChunk.addChunk(_Chunk(_ChunkType.rule, content));
            }
            return;
          }
          switch (c) {
            case ",":
            case " ":
            case "\n":
            case "\r":
            case "\t":
              {
                String content = sb.toString().trim();
                if (content.isNotEmpty) {
                  parentChunk.addChunk(_Chunk(_ChunkType.rule, content));
                }
                sb.clear();
                //            parentChunk.addChunk(new Chunk(ChunkType.concatenation));
                break;
              }
            case "|":
              {
                String content = sb.toString().trim();
                if (content.isNotEmpty) {
                  parentChunk.addChunk(_Chunk(_ChunkType.rule, content));
                }
                sb.clear();
                parentChunk.addChunk(_Chunk(_ChunkType.alteration));
                break;
              }
            case "*":
            case "+":
            case "?":
              {
                String content = sb.toString().trim();
                if (content.isNotEmpty) {
                  parentChunk.addChunk(_Chunk(_ChunkType.rule, content));
                }
                sb.clear();
                parentChunk.addChunk(_Chunk(_ChunkType.repetitionToken, c));
                break;
              }
            case '"':
              {
                String content = sb.toString().trim();
                if (content.isNotEmpty) {
                  parentChunk.addChunk(_Chunk(_ChunkType.rule, content));
                }
                sb.clear();
                var literalChunk = _Chunk(_ChunkType.literal);
                _loadExpression(literalChunk, reader, '"');
                parentChunk.addChunk(literalChunk);
                break;
              }
            case "'":
              {
                String content = sb.toString().trim();
                if (content.isNotEmpty) {
                  parentChunk.addChunk(_Chunk(_ChunkType.rule, content));
                }
                sb.clear();
                var literalChunk = _Chunk(_ChunkType.literal);
                _loadExpression(literalChunk, reader, "'");
                parentChunk.addChunk(literalChunk);
                break;
              }
            case "(":
              {
                String content = sb.toString().trim();
                if (content.isNotEmpty) {
                  parentChunk.addChunk(_Chunk(_ChunkType.rule, content));
                }
                sb.clear();
                var groupChunk = _Chunk(_ChunkType.group);
                _loadExpression(groupChunk, reader, ")");
                parentChunk.addChunk(groupChunk);
                break;
              }
            case "[":
              {
                String content = sb.toString().trim();
                if (content.isNotEmpty) {
                  parentChunk.addChunk(_Chunk(_ChunkType.rule, content));
                }
                sb.clear();
                var optionChunk = _Chunk(_ChunkType.option);
                _loadExpression(optionChunk, reader, "]");
                parentChunk.addChunk(optionChunk);
                break;
              }
            case "{":
              {
                String content = sb.toString().trim();
                if (content.isNotEmpty) {
                  parentChunk.addChunk(_Chunk(_ChunkType.rule, content));
                }
                sb.clear();
                var repetitionChunk = _Chunk(_ChunkType.reptition);
                repetitionChunk.setMinCount(0);
                _loadExpression(repetitionChunk, reader, "}");
                parentChunk.addChunk(repetitionChunk);
                break;
              }
            default:
              {
                if (sb.isNotEmpty || c.trim().isNotEmpty) {
                  sb.write(c);
                }
                break;
              }
          }
        }
        lastChar = x;
      }
    }
  }
}

class _StringReader {
  final String text;
  int _index = 0;

  _StringReader(this.text);

  int read() {
    if (_index >= text.length) {
      return -1;
    }
    return text.codeUnitAt(_index++);
  }
}

enum _ChunkType {
  rule,
  repetitionToken,
  //    concatenation,
  alteration,
  group,
  comment,
  specialSerquence,
  literal,
  option,
  reptition,
  choice,
}

class _Chunk {
  _ChunkType type;
  String? text;
  int minCount = 0;
  int? maxCount;
  List<_Chunk>? chunkList;

  _Chunk(this.type, [this.text]);

  _ChunkType getType() {
    return type;
  }

  void setType(_ChunkType type) {
    this.type = type;
  }

  void setText(String text) {
    this.text = text;
  }

  void setMinCount(int minCount) {
    this.minCount = minCount;
  }

  void setMaxCount(int? maxCount) {
    this.maxCount = maxCount;
  }

  void addChunk(_Chunk chunk) {
    chunkList ??= [];
    chunkList!.add(chunk);
  }

  void prune() {
    bool hasAlternation = false;
    if (chunkList != null) {
      for (int i = chunkList!.length - 1; i >= 0; i--) {
        _Chunk chunk = chunkList![i];
        switch (chunk.getType()) {
          case _ChunkType.repetitionToken:
            {
              if ("*" == chunk.text) {
                chunkList!.removeAt(i);
                _Chunk previousChunk = chunkList![i - 1];
                int? multiplier;
                // Case of: 3 * expression
                if (previousChunk.getType() == _ChunkType.rule) {
                  try {
                    if (previousChunk.text != null) {
                      multiplier = int.parse(previousChunk.text!);
                    }
                  } catch (e) {
                    // Ignore
                  }
                }
                if (multiplier != null) {
                  // The current one is removed, so next one is at index i.
                  _Chunk nextChunk = chunkList![i];
                  if (nextChunk.getType() == _ChunkType.option) {
                    _Chunk newChunk = _Chunk(_ChunkType.reptition);
                    newChunk.setMinCount(0);
                    newChunk.setMaxCount(multiplier);
                    if (nextChunk.chunkList != null) {
                      for (_Chunk c in nextChunk.chunkList!) {
                        newChunk.addChunk(c);
                      }
                    }
                    chunkList!.removeAt(i);
                    chunkList![i - 1] = newChunk;
                  } else {
                    _Chunk newChunk = _Chunk(_ChunkType.reptition);
                    newChunk.setMinCount(multiplier);
                    newChunk.setMaxCount(multiplier);
                    newChunk.addChunk(nextChunk);
                    chunkList!.removeAt(i);
                    chunkList![i - 1] = newChunk;
                  }
                } else {
                  _Chunk newChunk = _Chunk(_ChunkType.reptition);
                  newChunk.setMinCount(0);
                  newChunk.addChunk(previousChunk);
                  chunkList![i - 1] = newChunk;
                }
              } else if ("+" == chunk.text) {
                chunkList!.removeAt(i);
                _Chunk newChunk = _Chunk(_ChunkType.reptition);
                newChunk.setMinCount(1);
                _Chunk previousChunk = chunkList![i - 1];
                newChunk.addChunk(previousChunk);
                chunkList![i - 1] = newChunk;
              } else if ("?" == chunk.text) {
                chunkList!.removeAt(i);
                _Chunk newChunk = _Chunk(_ChunkType.option);
                _Chunk previousChunk = chunkList![i - 1];
                newChunk.addChunk(previousChunk);
                chunkList![i - 1] = newChunk;
              }
              break;
            }
          case _ChunkType.comment:
            {
              // For now, nothing to do
              chunkList!.removeAt(i);
              break;
            }
          case _ChunkType.alteration:
            {
              hasAlternation = true;
              break;
            }
          case _ChunkType.group:
            {
              // Group could be empty
              if (chunk.chunkList != null) {
                chunk.prune();
                if (chunk.chunkList!.length == 1) {
                  chunkList![i] = chunk.chunkList![0];
                }
              }
              break;
            }
          case _ChunkType.option:
          case _ChunkType.reptition:
            {
              chunk.prune();
              break;
            }
          default:
            break;
        }
      }
      if (hasAlternation) {
        List<List<_Chunk>> alternationSequenceList = [];
        alternationSequenceList.add([]);
        for (_Chunk chunk in chunkList!) {
          if (chunk.getType() == _ChunkType.alteration) {
            alternationSequenceList.add([]);
          } else {
            List<_Chunk> list =
                alternationSequenceList[alternationSequenceList.length - 1];
            list.add(chunk);
          }
        }
        _Chunk choiceChunk = _Chunk(_ChunkType.choice);
        for (List<_Chunk> subList in alternationSequenceList) {
          if (subList.length == 1) {
            choiceChunk.addChunk(subList[0]);
          } else {
            _Chunk groupChunk = _Chunk(_ChunkType.group);
            for (_Chunk c in subList) {
              groupChunk.addChunk(c);
            }
            choiceChunk.addChunk(groupChunk);
          }
        }
        chunkList!.clear();
        chunkList!.add(choiceChunk);
      }
    }
  }

  Expression getExpression() {
    switch (type) {
      case _ChunkType.group:
        {
          if (chunkList == null) {
            // Group is empty.
            return Sequence([]);
          }
          if (chunkList!.length == 1) {
            return chunkList![0].getExpression();
          }
          List<Expression> expressionList = [];
          for (_Chunk chunk in chunkList!) {
            expressionList.add(chunk.getExpression());
          }
          return Sequence(expressionList);
        }
      case _ChunkType.choice:
        {
          if (chunkList!.length == 1) {
            return chunkList![0].getExpression();
          }
          List<Expression> expressionList = [];
          bool hasLine = false;
          for (_Chunk chunk in chunkList!) {
            Expression expression = chunk.getExpression();
            if (expression is Repetition) {
              Repetition repetition = expression;
              if (repetition.minRepetitionCount == 0) {
                if (repetition.maxRepetitionCount == null ||
                    repetition.maxRepetitionCount != 1) {
                  expression = Repetition(
                    repetition.expression,
                    1,
                    repetition.maxRepetitionCount,
                  );
                } else {
                  expression = repetition.expression;
                }
                hasLine = true;
              }
            }
            if (expression is Choice) {
              for (Expression exp in expression.expressions) {
                expressionList.add(exp);
              }
            } else {
              expressionList.add(expression);
            }
          }
          if (hasLine &&
              (expressionList.isEmpty ||
                  !_isNoop(expressionList[expressionList.length - 1]))) {
            expressionList.add(Sequence([]));
          }
          return Choice(expressionList);
        }
      case _ChunkType.rule:
        {
          return RuleReference(text!);
        }
      case _ChunkType.literal:
        {
          return Literal(text!);
        }
      case _ChunkType.specialSerquence:
        {
          return SpecialSequence(text!);
        }
      case _ChunkType.option:
        {
          if (chunkList!.length == 1) {
            _Chunk subChunk = chunkList![0];
            if (subChunk.getType() == _ChunkType.choice) {
              _Chunk newChunk = _Chunk(_ChunkType.choice);
              if (subChunk.chunkList != null) {
                for (_Chunk cChunk in subChunk.chunkList!) {
                  newChunk.addChunk(cChunk);
                }
              }
              newChunk.addChunk(_Chunk(_ChunkType.group));
              return newChunk.getExpression();
            }
            return Repetition(subChunk.getExpression(), 0, 1);
          }
          List<Expression> expressionList = [];
          for (_Chunk chunk in chunkList!) {
            expressionList.add(chunk.getExpression());
          }
          return Repetition(Sequence(expressionList), 0, 1);
        }
      case _ChunkType.reptition:
        {
          if (chunkList!.length == 1) {
            return Repetition(
              chunkList![0].getExpression(),
              minCount,
              maxCount,
            );
          }
          List<Expression> expressionList = [];
          for (_Chunk chunk in chunkList!) {
            expressionList.add(chunk.getExpression());
          }
          return Repetition(Sequence(expressionList), minCount, maxCount);
        }
      default:
        throw StateError("Type should not be reachable: $type");
    }
  }

  @override
  String toString() {
    String s = type.toString();
    if (text != null) {
      s += " ($text)";
    }
    return s;
  }
}

bool _isNoop(Expression expression) {
  return expression is Sequence && expression.expressions.isEmpty;
}
