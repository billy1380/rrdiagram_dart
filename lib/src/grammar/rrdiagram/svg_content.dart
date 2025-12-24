import 'dart:math';
import '../../common/utils.dart';
import 'rr_diagram_to_svg.dart';

abstract class SvgConnector {}

class SvgPath extends SvgConnector {
  final StringBuffer pathSB = StringBuffer();
  int startX;
  int startY;
  int endX;
  int endY;

  SvgPath(this.startX, this.startY, String path, this.endX, this.endY) {
    pathSB.write(path);
  }

  void addPath(int x1, int y1, String path, int x2, int y2) {
    if (x1 != endX || y1 != endY) {
      if (x1 == endX && y1 == endY + 1) {
        pathSB.write('v${y1 - y2}');
      } else if (y1 == endY && x1 == endX + 1) {
        pathSB.write('h${x1 - x2}');
      } else {
        pathSB.write('m${x1 - endX}');
        if (y1 - endY >= 0) {
          pathSB.write(' ');
        }
        pathSB.write('${y1 - endY}');
      }
    }
    pathSB.write(path);
    endX = x2;
    endY = y2;
  }

  void addPathFromOther(SvgPath svgPath) {
    addPath(
      svgPath.startX,
      svgPath.startY,
      svgPath.getPath(),
      svgPath.endX,
      svgPath.endY,
    );
  }

  void addLine(SvgLine svgLine) {
    int x1 = svgLine.x1;
    int y1 = svgLine.y1;
    int x2 = svgLine.x2;
    int y2 = svgLine.y2;
    if (x1 == x2 && endX == x1) {
      if (endY == y1 || endY == y1 - 1) {
        pathSB.write('v${y2 - endY}');
        endY = y2;
        return;
      }
      if (endY == y2 || endY == y2 + 1) {
        pathSB.write('v${y1 - endY}');
        endY = y1;
        return;
      }
    } else if (y1 == y2 && endY == y1) {
      if (endX == x1 || endX == x1 - 1) {
        pathSB.write('h${x2 - endX}');
        endX = x2;
        return;
      }
      if (endX == x2 || endX == x2 + 1) {
        pathSB.write('h${x1 - endX}');
        endX = x1;
        return;
      }
    }
    pathSB.write('m${x1 - endX}');
    if (y1 - endY >= 0) {
      pathSB.write(' ');
    }
    pathSB.write('${y1 - endY}');
    if (x1 == x2) {
      pathSB.write('v${y2 - y1}');
    } else if (y1 == y2) {
      pathSB.write('h${x2 - x1}');
    } else {
      pathSB.write('l${x2 - x1}');
      if (y2 - y1 >= 0) {
        pathSB.write(' ');
      }
      pathSB.write('${y2 - y1}');
    }
    endX = x2;
    endY = y2;
  }

  String getPath() {
    return pathSB.toString();
  }
}

class SvgLine extends SvgConnector {
  int x1;
  int y1;
  int x2;
  int y2;

  SvgLine(this.x1, this.y1, this.x2, this.y2);

  bool mergeLine(int x1, int y1, int x2, int y2) {
    if (x1 == x2 && this.x1 == this.x2 && x1 == this.x1) {
      if (y2 >= this.y1 - 1 && y1 <= this.y2 + 1) {
        this.y1 = min(this.y1, y1);
        this.y2 = max(this.y2, y2);
        return true;
      }
    } else if (y1 == y2 && this.y1 == this.y2 && y1 == this.y1) {
      if (x2 >= this.x1 - 1 && x1 <= this.x2 + 1) {
        this.x1 = min(this.x1, x1);
        this.x2 = max(this.x2, x2);
        return true;
      }
    }
    return false;
  }
}

class SvgContent {
  final List<SvgConnector> connectorList = [];
  final StringBuffer elementsSB = StringBuffer();
  final Map<String, String> cssClassToDefinitionMap = {};
  static const String svgElementsSeparator = "";

  void addPathConnector(int x1, int y1, String path, int x2, int y2) {
    SvgConnector? c = connectorList.isNotEmpty ? connectorList.last : null;
    if (c != null) {
      if (c is SvgPath) {
        c.addPath(x1, y1, path, x2, y2);
      } else if (c is SvgLine) {
        int x1_ = c.x1;
        int y1_ = c.y1;
        int x2_ = c.x2;
        int y2_ = c.y2;
        if (x1_ == x2_ && x1 == x1_) {
          if (y2_ == y1 - 1) {
            c.mergeLine(x1_, y1_, x2_, y2_ + 1);
          } else if (y1_ == y1 + 1) {
            c.mergeLine(x1_, y1_ - 1, x2_, y2_);
          }
        } else if (y1_ == y2_ && y1 == y1_) {
          if (x2_ == x1 - 1) {
            c.mergeLine(x1_, y1_, x2_ + 1, y2_);
          } else if (x1_ == x1 + 1) {
            c.mergeLine(x1_ - 1, y1_, x2_, y2_);
          }
        }
        connectorList.add(SvgPath(x1, y1, path, x2, y2));
      }
    } else {
      connectorList.add(SvgPath(x1, y1, path, x2, y2));
    }
  }

  void addLineConnector(int x1, int y1, int x2, int y2) {
    int x1_ = min(x1, x2);
    int y1_ = min(y1, y2);
    int x2_ = max(x1, x2);
    int y2_ = max(y1, y2);
    SvgConnector? c = connectorList.isNotEmpty ? connectorList.last : null;
    if (c == null || c is! SvgLine || !c.mergeLine(x1_, y1_, x2_, y2_)) {
      connectorList.add(SvgLine(x1_, y1_, x2_, y2_));
    }
  }

  String getConnectorElement(RRDiagramToSVG rrDiagramToSVG) {
    if (connectorList.isEmpty) {
      return "";
    }
    SvgPath? path0;
    for (SvgConnector connector in connectorList) {
      if (path0 == null) {
        if (connector is SvgPath) {
          path0 = connector;
        } else if (connector is SvgLine) {
          int x1 = connector.x1;
          int y1 = connector.y1;
          path0 = SvgPath(x1, y1, "M$x1${y1 < 0 ? y1 : " $y1"}", x1, y1);
          path0.addLine(connector);
        }
      } else {
        if (connector is SvgPath) {
          path0.addPathFromOther(connector);
        } else if (connector is SvgLine) {
          path0.addLine(connector);
        }
      }
    }
    String connectorColor = Utils.convertColorToHtml(
      rrDiagramToSVG.connectorColor,
    );
    String cssClass = setCSSClass("c", "fill:none;stroke:$connectorColor;");
    return '<path class="$cssClass" d="${path0!.getPath()}"/>$svgElementsSeparator';
  }

  void addElement(String element) {
    elementsSB.write(element);
    elementsSB.write(svgElementsSeparator);
  }

  String getElements() {
    return elementsSB.toString();
  }

  String? getDefinedCSSClass(String style) {
    String? definition = cssClassToDefinitionMap[style];
    return definition == null
        ? null
        : (definition.endsWith(";") ? style : definition);
  }

  String setCSSClass(String cssClass, String definition) {
    String def = definition.trim();
    if (!def.endsWith(";")) {
      throw ArgumentError(
        "The definition is not well formed, it does not end with a semi-colon!",
      );
    }
    String? pDefinition = cssClassToDefinitionMap[cssClass];
    if (pDefinition != null) {
      if (!pDefinition.endsWith(";")) {
        pDefinition = cssClassToDefinitionMap[pDefinition];
      }
      if (def != pDefinition) {
        throw StateError(
          "The CSS class \"$cssClass\" is already defined, but with a different definition!",
        );
      }
    } else {
      for (var entry in cssClassToDefinitionMap.entries) {
        if (entry.value == def) {
          String redirectCssClass = entry.key;
          cssClassToDefinitionMap[cssClass] = redirectCssClass;
          return redirectCssClass;
        }
      }
      cssClassToDefinitionMap[cssClass] = def;
    }
    return cssClass;
  }

  String getCSSStyles() {
    final sb = StringBuffer();
    final cssClasses = cssClassToDefinitionMap.keys.toList()..sort();
    for (int i = 0; i < cssClasses.length; i++) {
      if (sb.isNotEmpty) {
        sb.write(svgElementsSeparator);
      }
      String cssClass = cssClasses[i];
      String? definition = cssClassToDefinitionMap[cssClass];
      if (definition != null && definition.endsWith(";")) {
        sb.write(".$cssClass{$definition}");
      }
    }
    return sb.toString();
  }
}
