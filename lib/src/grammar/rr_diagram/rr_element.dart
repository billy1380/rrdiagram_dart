import "dart:math";
import "../../common/ui_types.dart";
import "../../common/font.dart";
import "../../common/utils.dart";
import "layout_info.dart";
import "rr_diagram_to_svg.dart";
import "svg_content.dart";
import "rr_diagram.dart"; // For CSS constants

abstract class RrElement {
  LayoutInfo? _layoutInfo;

  void setLayoutInfo(LayoutInfo layoutInfo) {
    _layoutInfo = layoutInfo;
  }

  LayoutInfo getLayoutInfo() {
    return _layoutInfo!;
  }

  void computeLayoutInfo(RrDiagramToSvg rrDiagramToSvg);

  void toSvg(
    RrDiagramToSvg rrDiagramToSvg,
    int xOffset,
    int yOffset,
    SvgContent svgContent,
  );
}

class RrBreak extends RrElement {
  @override
  void computeLayoutInfo(RrDiagramToSvg rrDiagramToSvg) {
    throw StateError(
      "This element must not be nested and should have been processed before entering generation.",
    );
  }

  @override
  void toSvg(
    RrDiagramToSvg rrDiagramToSvg,
    int xOffset,
    int yOffset,
    SvgContent svgContent,
  ) {
    throw StateError(
      "This element must not be nested and should have been processed before entering generation.",
    );
  }
}

class RrChoice extends RrElement {
  final List<RrElement> rrElements;

  RrChoice(this.rrElements);

  @override
  void computeLayoutInfo(RrDiagramToSvg rrDiagramToSvg) {
    int width = 0;
    int height = 0;
    int connectorOffset = 0;
    for (int i = 0; i < rrElements.length; i++) {
      RrElement rrElement = rrElements[i];
      rrElement.computeLayoutInfo(rrDiagramToSvg);
      LayoutInfo layoutInfo = rrElement.getLayoutInfo();
      if (i == 0) {
        connectorOffset = layoutInfo.connectorOffset;
      } else {
        height += 5;
      }
      height += layoutInfo.height;
      width = max(width, layoutInfo.width);
    }
    width += 20 + 20;
    setLayoutInfo(LayoutInfo(width, height, connectorOffset));
  }

  @override
  void toSvg(
    RrDiagramToSvg rrDiagramToSvg,
    int xOffset,
    int yOffset,
    SvgContent svgContent,
  ) {
    LayoutInfo layoutInfo = getLayoutInfo();
    int y1 = yOffset + layoutInfo.connectorOffset;
    int x1 = xOffset + 10;
    int x2 = xOffset + layoutInfo.width - 10;
    int xOffset2 = xOffset + 20;
    int y2 = 0;
    int yOffset2 = yOffset;
    for (int i = 0; i < rrElements.length; i++) {
      RrElement rrElement = rrElements[i];
      LayoutInfo layoutInfo2 = rrElement.getLayoutInfo();
      int width = layoutInfo2.width;
      int height = layoutInfo2.height;
      y2 = yOffset2 + layoutInfo2.connectorOffset;
      if (i == 0) {
        // Line to first element
        svgContent.addLineConnector(x1 - 10, y1, x1 + 10, y1);
      } else {
        if (i == rrElements.length - 1) {
          // Curve and vertical down
          svgContent.addPathConnector(x1 - 5, y1, "q5 0 5 5", x1, y1 + 5);
          svgContent.addLineConnector(x1, y1 + 5, x1, y2 - 5);
        }
        // Curve and horizontal line to element
        svgContent.addPathConnector(x1, y2 - 5, "q0 5 5 5", x1 + 5, y2);
        svgContent.addLineConnector(x1 + 5, y2, xOffset2, y2);
      }
      rrElement.toSvg(rrDiagramToSvg, xOffset2, yOffset2, svgContent);
      if (i == 0) {
        // Line to first element
        svgContent.addLineConnector(xOffset2 + width, y2, x2 + 10, y2);
      } else {
        // Horizontal line to element and curve
        svgContent.addLineConnector(x2 - 5, y2, xOffset2 + width, y2);
        svgContent.addPathConnector(x2 - 5, y2, "q5 0 5-5", x2, y2 - 5);
        if (i == rrElements.length - 1) {
          // Vertical up and curve
          svgContent.addLineConnector(x2, y2 - 5, x2, y1 + 5);
          svgContent.addPathConnector(x2, y1 + 5, "q0-5 5-5", x2 + 5, y1);
        }
      }
      yOffset2 += height + 5;
    }
  }
}

class RrLine extends RrElement {
  @override
  void computeLayoutInfo(RrDiagramToSvg rrDiagramToSvg) {
    setLayoutInfo(const LayoutInfo(0, 10, 5));
  }

  @override
  void toSvg(
    RrDiagramToSvg rrDiagramToSvg,
    int xOffset,
    int yOffset,
    SvgContent svgContent,
  ) {}
}

class RrLoop extends RrElement {
  final RrElement rrElement;
  final RrElement? loopElement;
  final int minRepetitionCount;
  final int? maxRepetitionCount;

  RrLoop(
    this.rrElement,
    this.loopElement, [
    this.minRepetitionCount = 0,
    this.maxRepetitionCount,
  ]);

  String? cardinalitiesText;
  int cardinalitiesWidth = 0;
  int fontYOffset = 0;

  @override
  void computeLayoutInfo(RrDiagramToSvg rrDiagramToSvg) {
    cardinalitiesText = null;
    cardinalitiesWidth = 0;
    fontYOffset = 0;
    if (minRepetitionCount > 0 || maxRepetitionCount != null) {
      cardinalitiesText = "$minRepetitionCount..${maxRepetitionCount ?? "N"}";
      Font font = rrDiagramToSvg.loopFont;

      // Use the textMeasurer
      final metrics = rrDiagramToSvg.textMeasurer.measure(
        cardinalitiesText!,
        font,
      );

      fontYOffset = metrics.descent.round();
      cardinalitiesWidth = metrics.width.round() + 2;
    }
    rrElement.computeLayoutInfo(rrDiagramToSvg);
    LayoutInfo layoutInfo1 = rrElement.getLayoutInfo();
    int width = layoutInfo1.width;
    int height = layoutInfo1.height;
    int connectorOffset = layoutInfo1.connectorOffset;
    if (loopElement != null) {
      loopElement!.computeLayoutInfo(rrDiagramToSvg);
      LayoutInfo layoutInfo2 = loopElement!.getLayoutInfo();
      width = max(width, layoutInfo2.width);
      int height2 = layoutInfo2.height;
      height += 5 + height2;
      connectorOffset += 5 + height2;
    } else {
      height += 15;
      connectorOffset += 15;
    }
    width += 20 + 20 + cardinalitiesWidth;
    setLayoutInfo(LayoutInfo(width, height, connectorOffset));
  }

  @override
  void toSvg(
    RrDiagramToSvg rrDiagramToSvg,
    int xOffset,
    int yOffset,
    SvgContent svgContent,
  ) {
    LayoutInfo layoutInfo1 = rrElement.getLayoutInfo();
    int width1 = layoutInfo1.width;
    int maxWidth = width1;
    int yOffset2 = yOffset;
    LayoutInfo layoutInfo = getLayoutInfo();
    int connectorOffset = layoutInfo.connectorOffset;
    int y1 = yOffset;
    int loopOffset = 0;
    int loopWidth = 0;
    if (loopElement != null) {
      LayoutInfo layoutInfo2 = loopElement!.getLayoutInfo();
      loopWidth = layoutInfo2.width;
      maxWidth = max(maxWidth, loopWidth);
      loopOffset = xOffset + 20 + (maxWidth - loopWidth) ~/ 2;
      yOffset2 += 5 + layoutInfo2.height;
      y1 += layoutInfo2.connectorOffset;
    } else {
      yOffset2 += 15;
      y1 += 5;
    }
    int x1 = xOffset + 10;
    int x2 = xOffset + 20 + maxWidth + 10 + cardinalitiesWidth;
    int y2 = yOffset + connectorOffset;
    svgContent.addLineConnector(
      x1 - 10,
      y2,
      x1 + 10 + (maxWidth - width1) ~/ 2,
      y2,
    );
    int loopPathStartX = x1 + 5;
    svgContent.addPathConnector(x1 + 5, y2, "q-5 0-5-5", x1, y2 - 5);
    svgContent.addLineConnector(x1, y2 - 5, x1, y1 + 5);
    svgContent.addPathConnector(x1, y1 + 5, "q0-5 5-5", x1 + 5, y1);
    if (loopElement != null) {
      svgContent.addLineConnector(x1 + 5, y1, loopOffset, y1);
      loopElement!.toSvg(rrDiagramToSvg, loopOffset, yOffset, svgContent);
      loopPathStartX = loopOffset + loopWidth;
    }
    svgContent.addLineConnector(loopPathStartX, y1, x2 - 5, y1);
    svgContent.addPathConnector(x2 - 5, y1, "q5 0 5 5", x2, y1 + 5);
    svgContent.addLineConnector(x2, y1 + 5, x2, y2 - 5);
    svgContent.addPathConnector(x2, y2 - 5, "q0 5-5 5", x2 - 5, y2);
    if (cardinalitiesText != null) {
      String? cssClass;
      if (!rrDiagramToSvg.useInlineStyles) {
        cssClass = svgContent.getDefinedCssClass(
          RrDiagram.cssLoopCardinalitiesTextClass,
        );
      }
      if (cssClass == null) {
        Font loopFont = rrDiagramToSvg.loopFont;
        String loopTextColor = Utils.convertColorToHtml(
          rrDiagramToSvg.loopTextColor,
        );
        cssClass = svgContent.setCssClass(
          RrDiagram.cssLoopCardinalitiesTextClass,
          "fill:$loopTextColor;${Utils.convertFontToCss(loopFont)}",
          useInlineStyles: rrDiagramToSvg.useInlineStyles,
        );
      }
      String attr = rrDiagramToSvg.useInlineStyles ? "style" : "class";
      svgContent.addElement(
        '<text $attr="$cssClass" x="${x2 - cardinalitiesWidth}" y="${y2 - fontYOffset - 5}">${Utils.escapeXml(cardinalitiesText)}</text>',
      );
    }
    rrElement.toSvg(
      rrDiagramToSvg,
      xOffset + 20 + (maxWidth - width1) ~/ 2,
      yOffset2,
      svgContent,
    );
    svgContent.addLineConnector(
      x2 - cardinalitiesWidth - 10 - (maxWidth - width1) ~/ 2,
      y2,
      xOffset + layoutInfo.width,
      y2,
    );
  }
}

class RrSequence extends RrElement {
  final List<RrElement> rrElements;

  RrSequence(this.rrElements);

  @override
  void computeLayoutInfo(RrDiagramToSvg rrDiagramToSvg) {
    int width = 0;
    int aboveConnector = 0;
    int belowConnector = 0;
    for (int i = 0; i < rrElements.length; i++) {
      RrElement rrElement = rrElements[i];
      rrElement.computeLayoutInfo(rrDiagramToSvg);
      if (i > 0) {
        width += 10;
      }
      LayoutInfo layoutInfo = rrElement.getLayoutInfo();
      width += layoutInfo.width;
      int height = layoutInfo.height;
      int connectorOffset = layoutInfo.connectorOffset;
      aboveConnector = max(aboveConnector, connectorOffset);
      belowConnector = max(belowConnector, height - connectorOffset);
    }
    setLayoutInfo(
      LayoutInfo(width, aboveConnector + belowConnector, aboveConnector),
    );
  }

  @override
  void toSvg(
    RrDiagramToSvg rrDiagramToSvg,
    int xOffset,
    int yOffset,
    SvgContent svgContent,
  ) {
    LayoutInfo layoutInfo = getLayoutInfo();
    int connectorOffset = layoutInfo.connectorOffset;
    int widthOffset = 0;
    for (int i = 0; i < rrElements.length; i++) {
      RrElement rrElement = rrElements[i];
      LayoutInfo layoutInfo2 = rrElement.getLayoutInfo();
      int width2 = layoutInfo2.width;
      int connectorOffset2 = layoutInfo2.connectorOffset;
      int xOffset2 = widthOffset + xOffset;
      int yOffset2 = yOffset + connectorOffset - connectorOffset2;
      if (i > 0) {
        svgContent.addLineConnector(
          xOffset2 - 10,
          yOffset + connectorOffset,
          xOffset2,
          yOffset + connectorOffset,
        );
      }
      rrElement.toSvg(rrDiagramToSvg, xOffset2, yOffset2, svgContent);
      widthOffset += 10;
      widthOffset += width2;
    }
  }
}

enum RrTextType { literal, rule, specialSequence }

class RrText extends RrElement {
  final RrTextType type;
  final String text;
  final String? link;

  RrText(this.type, this.text, this.link);

  int fontYOffset = 0;

  @override
  void computeLayoutInfo(RrDiagramToSvg rrDiagramToSvg) {
    Font font;
    Insets insets;
    switch (type) {
      case RrTextType.rule:
        insets = rrDiagramToSvg.ruleInsets;
        font = rrDiagramToSvg.ruleFont;
        break;
      case RrTextType.literal:
        insets = rrDiagramToSvg.literalInsets;
        font = rrDiagramToSvg.literalFont;
        break;
      case RrTextType.specialSequence:
        insets = rrDiagramToSvg.specialSequenceInsets;
        font = rrDiagramToSvg.specialSequenceFont;
        break;
    }

    // Use the textMeasurer
    final metrics = rrDiagramToSvg.textMeasurer.measure(text, font);
    fontYOffset = metrics.descent.round();
    int width = metrics.width.round();
    int height = metrics.height.round();

    int connectorOffset = insets.top + height - fontYOffset;
    width += insets.left + insets.right;
    height += insets.top + insets.bottom;
    setLayoutInfo(LayoutInfo(width, height, connectorOffset));
  }

  @override
  void toSvg(
    RrDiagramToSvg rrDiagramToSvg,
    int xOffset,
    int yOffset,
    SvgContent svgContent,
  ) {
    LayoutInfo layoutInfo = getLayoutInfo();
    int width = layoutInfo.width;
    int height = layoutInfo.height;
    if (link != null) {
      svgContent.addElement('<a xlink:href="${Utils.escapeXml(link)}">');
    }
    Insets insets;
    Font font;
    Color fillColor;
    Color borderColor;
    Color textColor;
    BoxShape shape;
    // Helper to get defined class
    String? cssClass;
    String? cssTextClass;

    // Resolve styles based on type
    switch (type) {
      case RrTextType.rule:
        insets = rrDiagramToSvg.ruleInsets;
        font = rrDiagramToSvg.ruleFont;
        fillColor = rrDiagramToSvg.ruleFillColor;
        borderColor = rrDiagramToSvg.ruleBorderColor;
        textColor = rrDiagramToSvg.ruleTextColor;
        shape = rrDiagramToSvg.ruleShape;
        if (!rrDiagramToSvg.useInlineStyles) {
          cssClass = svgContent.getDefinedCssClass(RrDiagram.cssRuleClass);
          cssTextClass = svgContent.getDefinedCssClass(
            RrDiagram.cssRuleTextClass,
          );
        }
        break;
      case RrTextType.literal:
        insets = rrDiagramToSvg.literalInsets;
        font = rrDiagramToSvg.literalFont;
        fillColor = rrDiagramToSvg.literalFillColor;
        borderColor = rrDiagramToSvg.literalBorderColor;
        textColor = rrDiagramToSvg.literalTextColor;
        shape = rrDiagramToSvg.literalShape;
        if (!rrDiagramToSvg.useInlineStyles) {
          cssClass = svgContent.getDefinedCssClass(RrDiagram.cssLiteralClass);
          cssTextClass = svgContent.getDefinedCssClass(
            RrDiagram.cssLiteralTextClass,
          );
        }
        break;
      case RrTextType.specialSequence:
        insets = rrDiagramToSvg.specialSequenceInsets;
        font = rrDiagramToSvg.specialSequenceFont;
        fillColor = rrDiagramToSvg.specialSequenceFillColor;
        borderColor = rrDiagramToSvg.specialSequenceBorderColor;
        textColor = rrDiagramToSvg.specialSequenceTextColor;
        shape = rrDiagramToSvg.specialSequenceShape;
        if (!rrDiagramToSvg.useInlineStyles) {
          cssClass = svgContent.getDefinedCssClass(
            RrDiagram.cssSpecialSequenceClass,
          );
          cssTextClass = svgContent.getDefinedCssClass(
            RrDiagram.cssSpecialSequenceTextClass,
          );
        }
        break;
    }

    // Generate box attributes
    String boxAttributes;
    if (rrDiagramToSvg.useInlineStyles) {
      String fill = Utils.convertColorToHtml(fillColor);
      String stroke = Utils.convertColorToHtml(borderColor);
      boxAttributes = 'fill="$fill" stroke="$stroke"';
    } else {
      // Create class if not defined
      if (cssClass == null) {
        String sFill = Utils.convertColorToHtml(fillColor);
        String sStroke = Utils.convertColorToHtml(borderColor);
        String className;
        switch (type) {
          case RrTextType.rule:
            className = RrDiagram.cssRuleClass;
            break;
          case RrTextType.literal:
            className = RrDiagram.cssLiteralClass;
            break;
          case RrTextType.specialSequence:
            className = RrDiagram.cssSpecialSequenceClass;
            break;
        }
        cssClass = svgContent.setCssClass(
          className,
          "fill:$sFill;stroke:$sStroke;",
          useInlineStyles: false,
        );
      }
      boxAttributes = 'class="$cssClass"';
    }

    // Generate text attributes (keep using style/class for text as it is complex)
    String textAttributes;
    if (rrDiagramToSvg.useInlineStyles) {
      // Re-use logic to generate style string for text
      String sText = Utils.convertColorToHtml(textColor);
      String sFont = Utils.convertFontToCss(font);
      // Note: setCssClass with inline=true simply returns the definition now (thanks to my previous fix)
      String style = "fill:$sText;$sFont";
      textAttributes = 'style="$style"';
    } else {
      if (cssTextClass == null) {
        String sText = Utils.convertColorToHtml(textColor);
        String sFont = Utils.convertFontToCss(font);
        String className;
        switch (type) {
          case RrTextType.rule:
            className = RrDiagram.cssRuleTextClass;
            break;
          case RrTextType.literal:
            className = RrDiagram.cssLiteralTextClass;
            break;
          case RrTextType.specialSequence:
            className = RrDiagram.cssSpecialSequenceTextClass;
            break;
        }
        cssTextClass = svgContent.setCssClass(
          className,
          "fill:$sText;$sFont",
          useInlineStyles: false,
        );
      }
      textAttributes = 'class="$cssTextClass"';
    }

    // Draw Shape
    switch (shape) {
      case BoxShape.rectangle:
        svgContent.addElement(
          '<rect $boxAttributes x="$xOffset" y="$yOffset" width="$width" height="$height"/>',
        );
        break;
      case BoxShape.roundedRectangle:
        int rx = (insets.left + insets.right + insets.top + insets.bottom) ~/ 4;
        svgContent.addElement(
          '<rect $boxAttributes x="$xOffset" y="$yOffset" width="$width" height="$height" rx="$rx"/>',
        );
        break;
      case BoxShape.hexagon:
        int connectorOffset = layoutInfo.connectorOffset;
        svgContent.addLineConnector(
          xOffset,
          yOffset + connectorOffset,
          xOffset + insets.left,
          yOffset + connectorOffset,
        );
        svgContent.addElement(
          '<polygon $boxAttributes points="$xOffset ${yOffset + height / 2} ${xOffset + insets.left} $yOffset ${xOffset + width - insets.right} $yOffset ${xOffset + width} ${yOffset + height / 2} ${xOffset + width - insets.right} ${yOffset + height} ${xOffset + insets.left} ${yOffset + height}"/>',
        );
        svgContent.addLineConnector(
          xOffset + width,
          yOffset + connectorOffset,
          xOffset + width - insets.right,
          yOffset + connectorOffset,
        );
        break;
    }

    // Recalculate stringBounds just for height reference if needed, but we have it in layoutInfo and textMeasurer result
    // The original code used font.getStringBounds again here.
    final metrics = rrDiagramToSvg.textMeasurer.measure(text, font);

    int textXOffset = xOffset + insets.left;
    int textYOffset =
        yOffset + insets.top + metrics.height.round() - fontYOffset;
    svgContent.addElement(
      '<text $textAttributes x="$textXOffset" y="$textYOffset">${Utils.escapeXml(text)}</text>',
    );
    if (link != null) {
      svgContent.addElement("</a>");
    }
  }
}
