/// Represents font configuration.
class Font {
  final String name;
  final int size;
  final bool isBold;
  final bool isItalic;

  const Font(
    this.name,
    this.size, {
    this.isBold = false,
    this.isItalic = false,
  });

  @override
  String toString() {
    return 'Font(name: $name, size: $size, bold: $isBold, italic: $isItalic)';
  }
}
