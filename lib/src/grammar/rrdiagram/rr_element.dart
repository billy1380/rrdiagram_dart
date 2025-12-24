import 'dart:math';
import '../../common/ui_types.dart';
import '../../common/font.dart';
import '../../common/utils.dart';
import 'layout_info.dart';
import 'rr_diagram_to_svg.dart';
import 'svg_content.dart';
import 'rr_diagram.dart'; // For CSS constants

abstract class RRElement {
  LayoutInfo? _layoutInfo;

  void setLayoutInfo(LayoutInfo layoutInfo) {
    _layoutInfo = layoutInfo;
  }

  LayoutInfo getLayoutInfo() {
    return _layoutInfo!;
  }

  void computeLayoutInfo(RRDiagramToSVG rrDiagramToSVG);

  void toSVG(
    RRDiagramToSVG rrDiagramToSVG,
    int xOffset,
    int yOffset,
    SvgContent svgContent,
  );
}

class RRBreak extends RRElement {
  @override
  void computeLayoutInfo(RRDiagramToSVG rrDiagramToSVG) {
    throw StateError(
      "This element must not be nested and should have been processed before entering generation.",
    );
  }

  @override
  void toSVG(
    RRDiagramToSVG rrDiagramToSVG,
    int xOffset,
    int yOffset,
    SvgContent svgContent,
  ) {
    throw StateError(
      "This element must not be nested and should have been processed before entering generation.",
    );
  }
}

class RRChoice extends RRElement {
  final List<RRElement> rrElements;

  RRChoice(this.rrElements);

  @override
  void computeLayoutInfo(RRDiagramToSVG rrDiagramToSVG) {
    int width = 0;
    int height = 0;
    int connectorOffset = 0;
    for (int i = 0; i < rrElements.length; i++) {
      RRElement rrElement = rrElements[i];
      rrElement.computeLayoutInfo(rrDiagramToSVG);
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
  void toSVG(
    RRDiagramToSVG rrDiagramToSVG,
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
      RRElement rrElement = rrElements[i];
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
      rrElement.toSVG(rrDiagramToSVG, xOffset2, yOffset2, svgContent);
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

class RRLine extends RRElement {
  @override
  void computeLayoutInfo(RRDiagramToSVG rrDiagramToSVG) {
    setLayoutInfo(const LayoutInfo(0, 10, 5));
  }

  @override
  void toSVG(
    RRDiagramToSVG rrDiagramToSVG,
    int xOffset,
    int yOffset,
    SvgContent svgContent,
  ) {}
}

class RRLoop extends RRElement {
  final RRElement rrElement;
  final RRElement? loopElement;
  final int minRepetitionCount;
  final int? maxRepetitionCount;

  RRLoop(
    this.rrElement,
    this.loopElement, [
    this.minRepetitionCount = 0,
    this.maxRepetitionCount,
  ]);

  String? cardinalitiesText;
  int cardinalitiesWidth = 0;
  int fontYOffset = 0;

  @override
  void computeLayoutInfo(RRDiagramToSVG rrDiagramToSVG) {
    cardinalitiesText = null;
    cardinalitiesWidth = 0;
    fontYOffset = 0;
    if (minRepetitionCount > 0 || maxRepetitionCount != null) {
      cardinalitiesText = "$minRepetitionCount..${maxRepetitionCount ?? "N"}";
      Font font = rrDiagramToSVG.loopFont;

      // Use the textMeasurer
      final metrics = rrDiagramToSVG.textMeasurer.measure(
        cardinalitiesText!,
        font,
      );

      fontYOffset = metrics.descent.round();
      cardinalitiesWidth = metrics.width.round() + 2;
    }
    rrElement.computeLayoutInfo(rrDiagramToSVG);
    LayoutInfo layoutInfo1 = rrElement.getLayoutInfo();
    int width = layoutInfo1.width;
    int height = layoutInfo1.height;
    int connectorOffset = layoutInfo1.connectorOffset;
    if (loopElement != null) {
      loopElement!.computeLayoutInfo(rrDiagramToSVG);
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
  void toSVG(
    RRDiagramToSVG rrDiagramToSVG,
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
      loopElement!.toSVG(rrDiagramToSVG, loopOffset, yOffset, svgContent);
      loopPathStartX = loopOffset + loopWidth;
    }
    svgContent.addLineConnector(loopPathStartX, y1, x2 - 5, y1);
    svgContent.addPathConnector(x2 - 5, y1, "q5 0 5 5", x2, y1 + 5);
    svgContent.addLineConnector(x2, y1 + 5, x2, y2 - 5);
    svgContent.addPathConnector(x2, y2 - 5, "q0 5-5 5", x2 - 5, y2);
    if (cardinalitiesText != null) {
      String? cssClass = svgContent.getDefinedCSSClass(
        RRDiagram.cssLoopCardinalitiesTextClass,
      );
      if (cssClass == null) {
        Font loopFont = rrDiagramToSVG.loopFont;
        String loopTextColor = Utils.convertColorToHtml(
          rrDiagramToSVG.loopTextColor,
        );
        cssClass = svgContent.setCSSClass(
          RRDiagram.cssLoopCardinalitiesTextClass,
          "fill:$loopTextColor;${Utils.convertFontToCss(loopFont)}",
        );
      }
      svgContent.addElement(
        '<text class="$cssClass" x="${x2 - cardinalitiesWidth}" y="${y2 - fontYOffset - 5}">${Utils.escapeXML(cardinalitiesText)}</text>',
      );
    }
    rrElement.toSVG(
      rrDiagramToSVG,
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

class RRSequence extends RRElement {
  final List<RRElement> rrElements;

  RRSequence(this.rrElements);

  @override
  void computeLayoutInfo(RRDiagramToSVG rrDiagramToSVG) {
    int width = 0;
    int aboveConnector = 0;
    int belowConnector = 0;
    for (int i = 0; i < rrElements.length; i++) {
      RRElement rrElement = rrElements[i];
      rrElement.computeLayoutInfo(rrDiagramToSVG);
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
  void toSVG(
    RRDiagramToSVG rrDiagramToSVG,
    int xOffset,
    int yOffset,
    SvgContent svgContent,
  ) {
    LayoutInfo layoutInfo = getLayoutInfo();
    int connectorOffset = layoutInfo.connectorOffset;
    int widthOffset = 0;
    for (int i = 0; i < rrElements.length; i++) {
      RRElement rrElement = rrElements[i];
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
      rrElement.toSVG(rrDiagramToSVG, xOffset2, yOffset2, svgContent);
      widthOffset += 10;
      widthOffset += width2;
    }
  }
}

enum RRTextType { literal, rule, specialSequence }

class RRText extends RRElement {
  final RRTextType type;
  final String text;
  final String? link;

  RRText(this.type, this.text, this.link);

  int fontYOffset = 0;

  @override
  void computeLayoutInfo(RRDiagramToSVG rrDiagramToSVG) {
    Font font;
    Insets insets;
    switch (type) {
      case RRTextType.rule:
        insets = rrDiagramToSVG.ruleInsets;
        font = rrDiagramToSVG.ruleFont;
        break;
      case RRTextType.literal:
        insets = rrDiagramToSVG.literalInsets;
        font = rrDiagramToSVG.literalFont;
        break;
      case RRTextType.specialSequence:
        insets = rrDiagramToSVG.specialSequenceInsets;
        font = rrDiagramToSVG.specialSequenceFont;
        break;
    }

    // Use the textMeasurer
    final metrics = rrDiagramToSVG.textMeasurer.measure(text, font);
    fontYOffset = metrics.descent.round();
    int width = metrics.width.round();
    int height = metrics.height.round();

    int connectorOffset = insets.top + height - fontYOffset;
    width += insets.left + insets.right;
    height += insets.top + insets.bottom;
    setLayoutInfo(LayoutInfo(width, height, connectorOffset));
  }

  @override
  void toSVG(
    RRDiagramToSVG rrDiagramToSVG,
    int xOffset,
    int yOffset,
    SvgContent svgContent,
  ) {
    LayoutInfo layoutInfo = getLayoutInfo();
    int width = layoutInfo.width;
    int height = layoutInfo.height;
    if (link != null) {
      svgContent.addElement('<a xlink:href="${Utils.escapeXML(link)}">');
    }
    Insets insets;
    Font font;
    String? cssClass;
    String? cssTextClass;
    BoxShape shape;
    switch (type) {
      case RRTextType.rule:
        insets = rrDiagramToSVG.ruleInsets;
        font = rrDiagramToSVG.ruleFont;
        cssClass = svgContent.getDefinedCSSClass(RRDiagram.cssRuleClass);
        cssTextClass = svgContent.getDefinedCSSClass(
          RRDiagram.cssRuleTextClass,
        );
        if (cssClass == null) {
          String ruleBorderColor = Utils.convertColorToHtml(
            rrDiagramToSVG.ruleBorderColor,
          );
          String ruleFillColor = Utils.convertColorToHtml(
            rrDiagramToSVG.ruleFillColor,
          );
          Font ruleFont = rrDiagramToSVG.ruleFont;
          String ruleTextColor = Utils.convertColorToHtml(
            rrDiagramToSVG.ruleTextColor,
          );
          cssClass = svgContent.setCSSClass(
            RRDiagram.cssRuleClass,
            "fill:$ruleFillColor;stroke:$ruleBorderColor;",
          );
          cssTextClass = svgContent.setCSSClass(
            RRDiagram.cssRuleTextClass,
            "fill:$ruleTextColor;${Utils.convertFontToCss(ruleFont)}",
          );
        }
        shape = rrDiagramToSVG.ruleShape;
        break;
      case RRTextType.literal:
        insets = rrDiagramToSVG.literalInsets;
        font = rrDiagramToSVG.literalFont;
        cssClass = svgContent.getDefinedCSSClass(RRDiagram.cssLiteralClass);
        cssTextClass = svgContent.getDefinedCSSClass(
          RRDiagram.cssLiteralTextClass,
        );
        if (cssClass == null) {
          String literalBorderColor = Utils.convertColorToHtml(
            rrDiagramToSVG.literalBorderColor,
          );
          String literalFillColor = Utils.convertColorToHtml(
            rrDiagramToSVG.literalFillColor,
          );
          Font literalFont = rrDiagramToSVG.literalFont;
          String literalTextColor = Utils.convertColorToHtml(
            rrDiagramToSVG.literalTextColor,
          );
          cssClass = svgContent.setCSSClass(
            RRDiagram.cssLiteralClass,
            "fill:$literalFillColor;stroke:$literalBorderColor;",
          );
          cssTextClass = svgContent.setCSSClass(
            RRDiagram.cssLiteralTextClass,
            "fill:$literalTextColor;${Utils.convertFontToCss(literalFont)}",
          );
        }
        shape = rrDiagramToSVG.literalShape;
        break;
      case RRTextType.specialSequence:
        insets = rrDiagramToSVG.specialSequenceInsets;
        font = rrDiagramToSVG.specialSequenceFont;
        cssClass = svgContent.getDefinedCSSClass(
          RRDiagram.cssSpecialSequenceClass,
        );
        cssTextClass = svgContent.getDefinedCSSClass(
          RRDiagram.cssSpecialSequenceTextClass,
        );
        if (cssClass == null) {
          String specialSequenceBorderColor = Utils.convertColorToHtml(
            rrDiagramToSVG.specialSequenceBorderColor,
          );
          String specialSequenceFillColor = Utils.convertColorToHtml(
            rrDiagramToSVG.specialSequenceFillColor,
          );
          Font specialSequenceFont = rrDiagramToSVG.specialSequenceFont;
          String specialSequenceTextColor = Utils.convertColorToHtml(
            rrDiagramToSVG.specialSequenceTextColor,
          );
          cssClass = svgContent.setCSSClass(
            RRDiagram.cssSpecialSequenceClass,
            "fill:$specialSequenceFillColor;stroke:$specialSequenceBorderColor;",
          );
          cssTextClass = svgContent.setCSSClass(
            RRDiagram.cssSpecialSequenceTextClass,
            "fill:$specialSequenceTextColor;${Utils.convertFontToCss(specialSequenceFont)}",
          );
        }
        shape = rrDiagramToSVG.specialSequenceShape;
        break;
    }

    switch (shape) {
      case BoxShape.rectangle:
        svgContent.addElement(
          '<rect class="$cssClass" x="$xOffset" y="$yOffset" width="$width" height="$height"/>',
        );
        break;
      case BoxShape.roundedRectangle:
        int rx = (insets.left + insets.right + insets.top + insets.bottom) ~/ 4;
        svgContent.addElement(
          '<rect class="$cssClass" x="$xOffset" y="$yOffset" width="$width" height="$height" rx="$rx"/>',
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
          '<polygon class="$cssClass" points="$xOffset ${yOffset + height / 2} ${xOffset + insets.left} $yOffset ${xOffset + width - insets.right} $yOffset ${xOffset + width} ${yOffset + height / 2} ${xOffset + width - insets.right} ${yOffset + height} ${xOffset + insets.left} ${yOffset + height}"/>',
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
    final metrics = rrDiagramToSVG.textMeasurer.measure(text, font);

    int textXOffset = xOffset + insets.left;
    int textYOffset =
        yOffset + insets.top + metrics.height.round() - fontYOffset;
    svgContent.addElement(
      '<text class="$cssTextClass" x="$textXOffset" y="$textYOffset">${Utils.escapeXML(text)}</text>',
    );
    if (link != null) {
      svgContent.addElement("</a>");
    }
  }
}
