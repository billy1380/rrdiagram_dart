import 'ui_types.dart';
import 'font.dart';

class Utils {
  static String escapeXML(String? s) {
    if (s == null || s.isEmpty) {
      return s ?? '';
    }
    final sb = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      final c = s[i];
      switch (c) {
        case '<':
          sb.write('&lt;');
          break;
        case '>':
          sb.write('&gt;');
          break;
        case '&':
          sb.write('&amp;');
          break;
        case '\'':
          sb.write('&apos;');
          break;
        case '"':
          sb.write('&quot;');
          break;
        default:
          sb.write(c);
          break;
      }
    }
    return sb.toString();
  }

  static String convertColorToHtml(Color c) {
    return c.toHex();
  }

  static String convertFontToCss(Font font) {
    final sb = StringBuffer();
    sb.write('font-family:${font.name},Sans-serif;');
    if (font.isItalic) {
      sb.write('font-style:italic;');
    }
    if (font.isBold) {
      sb.write('font-weight:bold;');
    }
    sb.write('font-size:${font.size}px;');
    return sb.toString();
  }
}
