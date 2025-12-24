import '../../common/ui_types.dart';
import '../../common/font.dart';
import '../../common/text_measurer.dart';
import 'rr_diagram.dart';

enum BoxShape { rectangle, roundedRectangle, hexagon }

class RRDiagramToSVG {
  // The "Fix": Injectable text measurer
  final TextMeasurer textMeasurer;

  RRDiagramToSVG({TextMeasurer? textMeasurer})
    : textMeasurer = textMeasurer ?? EstimatedTextMeasurer();

  String convert(RRDiagram rrDiagram) {
    return rrDiagram.toSVG(this);
  }

  Color connectorColor = const Color(34, 34, 34);
  Font loopFont = const Font('Verdana', 10);
  Color loopTextColor = Color.black;

  Insets ruleInsets = const Insets(5, 10, 5, 10);
  Font ruleFont = const Font('Verdana', 12);
  Color ruleTextColor = Color.black;
  BoxShape ruleShape = BoxShape.rectangle;
  Color ruleBorderColor = const Color(34, 34, 34);
  Color ruleFillColor = const Color(211, 240, 255);

  Insets literalInsets = const Insets(5, 10, 5, 10);
  Font literalFont = const Font('Verdana', 12);
  Color literalTextColor = Color.black;
  BoxShape literalShape = BoxShape.roundedRectangle;
  Color literalBorderColor = const Color(34, 34, 34);
  Color literalFillColor = const Color(144, 217, 255);

  Insets specialSequenceInsets = const Insets(5, 10, 5, 10);
  Font specialSequenceFont = const Font('Verdana', 12);
  Color specialSequenceTextColor = Color.black;
  BoxShape specialSequenceShape = BoxShape.hexagon;
  Color specialSequenceBorderColor = const Color(34, 34, 34);
  Color specialSequenceFillColor = const Color(228, 244, 255);
}
