import 'font.dart';

/// Represents the dimensions of a block of text.
class TextDimensions {
  final double width;
  final double height;
  final double descent;

  const TextDimensions({
    required this.width,
    required this.height,
    required this.descent,
  });
}

/// Interface for measuring text dimensions.
///
/// Implementations can wrap platform-specific logic (e.g. Canvas in Web, TextPainter in Flutter)
/// or provide estimations.
abstract class TextMeasurer {
  TextDimensions measure(String text, Font font);
}

/// A simple measurer that estimates text size.
/// Useful for CLI environments where no rendering engine is available.
class EstimatedTextMeasurer implements TextMeasurer {
  @override
  TextDimensions measure(String text, Font font) {
    // Estimation logic:
    // Assume average char width is roughly 0.6 * fontSize.
    // This mimics the original Java stub implementation.
    final double width = text.length * font.size * 0.6;
    final double height = font.size.toDouble();
    // Descent is typically around 20-25% of height for many fonts.
    final double descent = height * 0.25;

    return TextDimensions(width: width, height: height, descent: descent);
  }
}
