/// Represents a color with RGB values.
class Color {
  final int r;
  final int g;
  final int b;

  const Color(this.r, this.g, this.b);

  static const Color black = Color(0, 0, 0);
  static const Color white = Color(255, 255, 255);

  String toHex() {
    return '#${r.toRadixString(16).padLeft(2, '0')}${g.toRadixString(16).padLeft(2, '0')}${b.toRadixString(16).padLeft(2, '0')}';
  }
}

/// Represents the padding/margin around an element.
class Insets {
  final int top;
  final int left;
  final int bottom;
  final int right;

  const Insets(this.top, this.left, this.bottom, this.right);

  const Insets.all(int val) : top = val, left = val, bottom = val, right = val;
}
