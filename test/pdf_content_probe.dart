import 'dart:typed_data';

/// A rectangle drawn on the page, in PDF user space (origin bottom-left).
class ProbeRect {
  const ProbeRect(this.left, this.bottom, this.right, this.top);

  final double left;
  final double bottom;
  final double right;
  final double top;

  double get width => right - left;
  double get height => top - bottom;

  @override
  String toString() =>
      'Rect(l:${left.toStringAsFixed(1)}, b:${bottom.toStringAsFixed(1)}, '
      'r:${right.toStringAsFixed(1)}, t:${top.toStringAsFixed(1)})';
}

/// A text run drawn on the page, positioned at its baseline origin.
class ProbeText {
  const ProbeText(this.text, this.x, this.y);

  final String text;
  final double x;
  final double y;

  @override
  String toString() => '"$text"@(${x.toStringAsFixed(1)},'
      '${y.toStringAsFixed(1)})';
}

/// Reads back the drawing operators of an uncompressed single-page PDF so
/// tests can assert on where things actually landed instead of only checking
/// that bytes exist.
class PdfPageProbe {
  PdfPageProbe._(this.rects, this.texts, this.rectRuns, this.images);

  final List<ProbeRect> rects;
  final List<ProbeText> texts;

  /// Rectangles grouped by the uninterrupted run they were emitted in. A QR
  /// code drawn as vector modules arrives as one long run of squares.
  final List<List<ProbeRect>> rectRuns;

  /// Where each embedded image was painted, in page coordinates. A `cover`
  /// image reports the rectangle it was painted into before the surrounding
  /// clip trimmed it, so this is placement rather than visible extent.
  final List<ProbeRect> images;

  static PdfPageProbe parse(Uint8List bytes) {
    final content = _contentStream(bytes);
    final tokens = _tokenize(content);

    final rects = <ProbeRect>[];
    final texts = <ProbeText>[];
    final runs = <List<ProbeRect>>[];
    final images = <ProbeRect>[];
    var currentRun = <ProbeRect>[];

    final stack = <List<double>>[];
    var ctm = <double>[1, 0, 0, 1, 0, 0];
    final operands = <String>[];
    var textX = 0.0;
    var textY = 0.0;

    void closeRun() {
      if (currentRun.isNotEmpty) {
        runs.add(currentRun);
        currentRun = <ProbeRect>[];
      }
    }

    double num(int fromEnd) =>
        double.parse(operands[operands.length - fromEnd]);

    for (final token in tokens) {
      if (token.startsWith('(') || token.startsWith('<')) {
        operands.add(token);
        continue;
      }
      if (double.tryParse(token) != null) {
        operands.add(token);
        continue;
      }

      switch (token) {
        case 'q':
          stack.add(List<double>.of(ctm));
        case 'Q':
          if (stack.isNotEmpty) ctm = stack.removeLast();
        case 'cm':
          if (operands.length >= 6) {
            ctm = _multiply(
              <double>[num(6), num(5), num(4), num(3), num(2), num(1)],
              ctm,
            );
          }
        case 're':
          if (operands.length >= 4) {
            final x = num(4);
            final y = num(3);
            final w = num(2);
            final h = num(1);
            final a = _apply(ctm, x, y);
            final b = _apply(ctm, x + w, y + h);
            currentRun.add(
              ProbeRect(
                a[0] < b[0] ? a[0] : b[0],
                a[1] < b[1] ? a[1] : b[1],
                a[0] > b[0] ? a[0] : b[0],
                a[1] > b[1] ? a[1] : b[1],
              ),
            );
          }
        case 'BT':
          textX = 0;
          textY = 0;
        case 'Td':
          if (operands.length >= 2) {
            textX = num(2);
            textY = num(1);
          }
        case 'TJ':
        case 'Tj':
          final drawn = operands.where((o) => o.startsWith('(')).join();
          if (drawn.isNotEmpty) {
            final point = _apply(ctm, textX, textY);
            texts.add(
              ProbeText(_unescape(drawn), point[0], point[1]),
            );
          }
        case 'Do':
          // An image is painted by drawing the unit square under the current
          // transform, so the transform is the placement.
          final a = _apply(ctm, 0, 0);
          final b = _apply(ctm, 1, 1);
          images.add(
            ProbeRect(
              a[0] < b[0] ? a[0] : b[0],
              a[1] < b[1] ? a[1] : b[1],
              a[0] > b[0] ? a[0] : b[0],
              a[1] > b[1] ? a[1] : b[1],
            ),
          );
        case 'f':
        case 'f*':
        case 'F':
        case 'B':
        case 'b':
        case 'S':
        case 's':
        case 'n':
        case 'W':
          rects.addAll(currentRun);
          closeRun();
      }
      operands.clear();
    }
    rects.addAll(currentRun);
    closeRun();

    return PdfPageProbe._(rects, texts, runs, images);
  }

  /// Bounding box of the QR code: the longest uninterrupted run of drawn
  /// squares on the page. Returns null when no code was drawn.
  ProbeRect? qrBounds({int minimumModules = 50}) {
    List<ProbeRect>? longest;
    for (final run in rectRuns) {
      if (longest == null || run.length > longest.length) longest = run;
    }
    if (longest == null || longest.length < minimumModules) return null;

    var left = longest.first.left;
    var bottom = longest.first.bottom;
    var right = longest.first.right;
    var top = longest.first.top;
    for (final rect in longest) {
      if (rect.left < left) left = rect.left;
      if (rect.bottom < bottom) bottom = rect.bottom;
      if (rect.right > right) right = rect.right;
      if (rect.top > top) top = rect.top;
    }
    return ProbeRect(left, bottom, right, top);
  }

  /// Drawn images with a square placement. A ticket's QR code is the only
  /// square image it embeds, unless a test feeds it a square event photo.
  List<ProbeRect> get squareImages => images
      .where((image) => (image.width - image.height).abs() < 0.5)
      .toList();

  /// First text run whose content contains [needle].
  ProbeText? textAt(String needle) {
    for (final text in texts) {
      if (text.text.contains(needle)) return text;
    }
    return null;
  }

  /// The page content stream: the readable operator block, told apart from
  /// font streams by how much of it is printable text, and from image streams
  /// by their dictionary — an ASCII85 image is printable and far longer than
  /// the operators, so length alone would pick the wrong block.
  static String _contentStream(Uint8List bytes) {
    final source = String.fromCharCodes(bytes);
    var best = '';
    var index = source.indexOf('stream');
    while (index >= 0) {
      var start = index + 'stream'.length;
      if (start < source.length && source[start] == '\r') start++;
      if (start < source.length && source[start] == '\n') start++;
      final end = source.indexOf('endstream', start);
      if (end < 0) break;
      final block = source.substring(start, end);
      if (!_isImageObject(source, index) &&
          _looksLikeOperators(block) &&
          block.length > best.length) {
        best = block;
      }
      index = source.indexOf('stream', end + 'endstream'.length);
    }
    return best;
  }

  static bool _isImageObject(String source, int streamKeyword) {
    final from = streamKeyword < 400 ? 0 : streamKeyword - 400;
    return source
        .substring(from, streamKeyword)
        .contains('/Subtype/Image');
  }

  static bool _looksLikeOperators(String block) {
    if (!block.contains('re ') && !block.contains('BT ')) return false;
    var printable = 0;
    final sample = block.length > 4096 ? block.substring(0, 4096) : block;
    for (final unit in sample.codeUnits) {
      if (unit == 9 || unit == 10 || unit == 13 || (unit >= 32 && unit < 127)) {
        printable++;
      }
    }
    return printable > sample.length * 0.9;
  }

  static List<String> _tokenize(String content) {
    final tokens = <String>[];
    final buffer = StringBuffer();

    void flush() {
      if (buffer.isNotEmpty) {
        tokens.add(buffer.toString());
        buffer.clear();
      }
    }

    for (var i = 0; i < content.length; i++) {
      final char = content[i];
      if (char == '(') {
        flush();
        final literal = StringBuffer('(');
        var depth = 1;
        i++;
        while (i < content.length && depth > 0) {
          final inner = content[i];
          if (inner == r'\' && i + 1 < content.length) {
            literal.write(inner);
            literal.write(content[i + 1]);
            i += 2;
            continue;
          }
          if (inner == '(') depth++;
          if (inner == ')') depth--;
          if (depth > 0) literal.write(inner);
          i++;
        }
        i--;
        tokens.add(literal.toString());
        continue;
      }
      if (char == ' ' || char == '\n' || char == '\r' || char == '\t') {
        flush();
        continue;
      }
      if (char == '[' || char == ']') {
        flush();
        continue;
      }
      if (char == '/') {
        flush();
        buffer.write(char);
        continue;
      }
      buffer.write(char);
    }
    flush();
    return tokens;
  }

  static String _unescape(String literal) {
    final raw = literal.replaceAll('(', '');
    return raw
        .replaceAll(r'\(', '(')
        .replaceAll(r'\)', ')')
        .replaceAll(r'\\', r'\');
  }

  static List<double> _multiply(List<double> m, List<double> n) {
    return <double>[
      m[0] * n[0] + m[1] * n[2],
      m[0] * n[1] + m[1] * n[3],
      m[2] * n[0] + m[3] * n[2],
      m[2] * n[1] + m[3] * n[3],
      m[4] * n[0] + m[5] * n[2] + n[4],
      m[4] * n[1] + m[5] * n[3] + n[5],
    ];
  }

  static List<double> _apply(List<double> m, double x, double y) {
    return <double>[
      x * m[0] + y * m[2] + m[4],
      x * m[1] + y * m[3] + m[5],
    ];
  }
}
