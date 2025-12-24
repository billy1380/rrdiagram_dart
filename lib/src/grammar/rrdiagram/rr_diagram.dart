import 'dart:math';
import 'rr_diagram_to_svg.dart';
import 'rr_element.dart';
import 'svg_content.dart';
import 'layout_info.dart';

class RRDiagram {
  final RRElement rrElement;

  RRDiagram(this.rrElement);

  static const String cssConnectorClass = "c";
  static const String cssRuleClass = "r";
  static const String cssRuleTextClass = "i";
  static const String cssLiteralClass = "l";
  static const String cssLiteralTextClass = "j";
  static const String cssSpecialSequenceClass = "s";
  static const String cssSpecialSequenceTextClass = "k";
  static const String cssLoopCardinalitiesTextClass = "u";

  String toSVG(RRDiagramToSVG rrDiagramToSVG) {
    List<RRElement> rrElementList = [];
    if (rrElement is RRSequence) {
      List<RRElement> cursorElementList = [];
      for (RRElement element in (rrElement as RRSequence).rrElements) {
        if (element is RRBreak) {
          if (cursorElementList.isNotEmpty) {
            rrElementList.add(
              cursorElementList.length == 1
                  ? cursorElementList[0]
                  : RRSequence(List.from(cursorElementList)),
            );
            cursorElementList.clear();
          }
        } else {
          cursorElementList.add(element);
        }
      }
      if (cursorElementList.isNotEmpty) {
        rrElementList.add(
          cursorElementList.length == 1
              ? cursorElementList[0]
              : RRSequence(List.from(cursorElementList)),
        );
      }
    } else {
      rrElementList.add(rrElement);
    }

    int width = 5;
    int height = 5;
    for (int i = 0; i < rrElementList.length; i++) {
      if (i > 0) {
        height += 5;
      }
      RRElement rrElement = rrElementList[i];
      rrElement.computeLayoutInfo(rrDiagramToSVG);
      LayoutInfo layoutInfo = rrElement.getLayoutInfo();
      width = max(width, 5 + layoutInfo.width + 5);
      height += layoutInfo.height + 5;
    }

    SvgContent svgContent = SvgContent();
    // First, generate the XML for the elements, to know the usage.
    int xOffset = 0;
    int yOffset = 5;
    for (RRElement rrElement in rrElementList) {
      LayoutInfo layoutInfo2 = rrElement.getLayoutInfo();
      int connectorOffset2 = layoutInfo2.connectorOffset;
      int width2 = layoutInfo2.width;
      int height2 = layoutInfo2.height;
      int y1 = yOffset + connectorOffset2;
      svgContent.addLineConnector(xOffset, y1, xOffset + 5, y1);
      // TODO: add decorations (like arrows)?
      rrElement.toSVG(rrDiagramToSVG, xOffset + 5, yOffset, svgContent);
      svgContent.addLineConnector(
        xOffset + 5 + width2,
        y1,
        xOffset + 5 + width2 + 5,
        y1,
      );
      yOffset += height2 + 10;
    }

    String connectorElement = svgContent.getConnectorElement(rrDiagramToSVG);
    String elements = svgContent.getElements();

    // Then generate the rest (CSS and SVG container tags) based on that usage.
    StringBuffer sb = StringBuffer();
    sb.write(
      '<svg version="1.1" xmlns:xlink="http://www.w3.org/1999/xlink" xmlns="http://www.w3.org/2000/svg" width="$width" height="$height" viewbox="0 0 $width $height">${SvgContent.svgElementsSeparator}',
    );
    String styles = svgContent.getCSSStyles();
    if (styles.isNotEmpty) {
      sb.write(
        '<defs><style type="text/css">${SvgContent.svgElementsSeparator}',
      );
      sb.write('$styles${SvgContent.svgElementsSeparator}');
      sb.write('</style></defs>${SvgContent.svgElementsSeparator}');
    }
    sb.write(connectorElement);
    sb.write(elements);
    sb.write('</svg>');
    return sb.toString();
  }
}
