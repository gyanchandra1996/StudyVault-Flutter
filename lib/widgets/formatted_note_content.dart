import 'package:flutter/material.dart';
import 'formatted_ai_text.dart';

/// Cleanly formats study notes, handbook formulas, grammar rules, and timelines
/// for comfortable reading:
/// - Keeps short pipe-separated data (formulas, fractions) on one line
/// - Splits long descriptive pipe items onto clean separate lines
/// - Renders nested bullets (`•`, `-`, `*`) and numbered lists with proper hanging indentation
/// - Automatically highlights concise `Key: Explanation` labels
/// - Renders Markdown headings, bold/italic, inline code, blockquotes, and tables cleanly
class FormattedNoteContent extends StatelessWidget {
  final String data;
  final Color? textColor;
  final Color accentColor;
  final double fontSize;
  final bool selectable;
  final int? maxBlocks;

  const FormattedNoteContent({
    Key? key,
    required this.data,
    this.textColor,
    this.accentColor = const Color(0xFF1E3A8A),
    this.fontSize = 13.5,
    this.selectable = true,
    this.maxBlocks,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final effectiveTextColor =
        textColor ?? (isDark ? const Color(0xFFE2E8F0) : const Color(0xFF1E293B));

    // If text has Markdown fenced code blocks or tables, delegate directly to FormattedAiText
    final normalized = data.replaceAll('\r\n', '\n').trim();
    if (normalized.isEmpty) {
      return const SizedBox.shrink();
    }
    if (normalized.contains('```') || _hasMarkdownTable(normalized)) {
      return FormattedAiText(
        data: normalized,
        textColor: effectiveTextColor,
        accentColor: accentColor,
        fontSize: fontSize,
        selectable: selectable,
      );
    }

    final items = _parseLines(normalized);
    final visibleItems =
        (maxBlocks != null && items.length > maxBlocks!) ? items.sublist(0, maxBlocks!) : items;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int i = 0; i < visibleItems.length; i++) ...[
          _buildItem(context, visibleItems[i], effectiveTextColor, isDark),
          if (i < visibleItems.length - 1)
            SizedBox(height: visibleItems[i].spacingAfter),
        ],
      ],
    );
  }

  static bool _hasMarkdownTable(String text) {
    final lines = text.split('\n');
    for (int i = 0; i < lines.length - 1; i++) {
      final a = lines[i].trim();
      final b = lines[i + 1].trim();
      if (a.startsWith('|') && b.startsWith('|') && RegExp(r'^\|[\s:|-]+\|?$').hasMatch(b)) {
        return true;
      }
    }
    return false;
  }

  /// Splits raw note text into well-structured lines.
  /// Short pipe-separated items (formulas, fractions, percentages) stay inline.
  /// Long descriptive pipe items are split onto separate lines.
  static List<_NoteLine> _parseLines(String raw) {
    final rawLines = raw.split('\n');
    final result = <_NoteLine>[];

    for (final rawLine in rawLines) {
      final trimmed = rawLine.trim();
      if (trimmed.isEmpty) continue;

      // 1. Markdown heading (#, ##, ###)
      final headingMatch = RegExp(r'^(#{1,6})\s+(.+)$').firstMatch(trimmed);
      if (headingMatch != null) {
        result.add(_NoteLine(
          type: _NoteLineType.heading,
          text: headingMatch.group(2)!.trim(),
          spacingAfter: 6,
        ));
        continue;
      }

      // 2. Horizontal divider
      if (RegExp(r'^[-*_]{3,}$').hasMatch(trimmed)) {
        result.add(const _NoteLine(type: _NoteLineType.divider, text: '', spacingAfter: 6));
        continue;
      }

      // 3. Blockquote
      if (trimmed.startsWith('>')) {
        result.add(_NoteLine(
          type: _NoteLineType.quote,
          text: trimmed.replaceFirst(RegExp(r'^>\s?'), ''),
          spacingAfter: 6,
        ));
        continue;
      }

      // 4. Detect indent & marker on the raw line
      final bulletMatch = RegExp(r'^(\s*)([•◦▪]|[-*+])\s+(.+)$').firstMatch(rawLine);
      final orderedMatch = RegExp(r'^(\s*)(\d+)[\.\\)]\s+(.+)$').firstMatch(rawLine);

      int indentLevel = 0;
      _NoteLineType baseType = _NoteLineType.paragraph;
      String body = trimmed;
      String? orderLabel;

      if (bulletMatch != null) {
        final spaces = bulletMatch.group(1)?.length ?? 0;
        final marker = bulletMatch.group(2) ?? '•';
        indentLevel = (spaces >= 2 || marker == '-' || marker == '*') && marker != '•'
            ? (spaces >= 4 ? 2 : 1)
            : (spaces ~/ 2).clamp(0, 2);
        baseType = _NoteLineType.bullet;
        body = bulletMatch.group(3)!.trim();
      } else if (orderedMatch != null) {
        final spaces = orderedMatch.group(1)?.length ?? 0;
        indentLevel = (spaces ~/ 2).clamp(0, 2);
        baseType = _NoteLineType.ordered;
        orderLabel = '${orderedMatch.group(2)}.';
        body = orderedMatch.group(3)!.trim();
      }

      // 5. Split inline ` | ` segments only when they are long descriptive items
      //    Keep short inline data (formulas, fractions, percentages) together on one line
      if (!trimmed.startsWith('|') && body.contains(' | ')) {
        final segments = body
            .split(' | ')
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toList();

        if (segments.length > 1) {
          // Calculate average segment length to decide split strategy
          final avgLen = segments.fold<int>(0, (sum, s) => sum + s.length) ~/ segments.length;
          // Detect short formula/data segments (contain =, %, /, digits, math symbols)
          final shortDataCount = segments.where((s) =>
              s.length < 28 &&
              (s.contains('=') || s.contains('%') || s.contains('/') ||
               RegExp(r'^\d').hasMatch(s))).length;
          final isShortData = shortDataCount > segments.length / 2 || avgLen < 25;

          if (!isShortData) {
            // Long descriptive segments: split into separate lines
            for (int sIdx = 0; sIdx < segments.length; sIdx++) {
              final seg = segments[sIdx];
              final segOrdered = RegExp(r'^(\d+)[\.\\)]\s+(.+)$').firstMatch(seg);
              if (segOrdered != null) {
                result.add(_NoteLine(
                  type: _NoteLineType.ordered,
                  text: segOrdered.group(2)!.trim(),
                  orderLabel: '${segOrdered.group(1)}.',
                  indentLevel: indentLevel,
                  spacingAfter: 4.5,
                ));
              } else {
                result.add(_NoteLine(
                  type: baseType == _NoteLineType.ordered && sIdx == 0
                      ? _NoteLineType.ordered
                      : _NoteLineType.bullet,
                  text: seg,
                  orderLabel: (baseType == _NoteLineType.ordered && sIdx == 0) ? orderLabel : null,
                  indentLevel: (baseType == _NoteLineType.ordered && sIdx > 0)
                      ? (indentLevel + 1).clamp(0, 2)
                      : indentLevel,
                  spacingAfter: sIdx == segments.length - 1 ? 5.5 : 3.5,
                ));
              }
            }
            continue;
          }
          // Short data segments: keep as a single line (fall through below)
        }
      }

      result.add(_NoteLine(
        type: baseType,
        text: body,
        orderLabel: orderLabel,
        indentLevel: indentLevel,
        spacingAfter: indentLevel > 0 ? 4 : 5.5,
      ));
    }

    return result;
  }

  Widget _buildItem(
    BuildContext context,
    _NoteLine item,
    Color textColor,
    bool isDark,
  ) {
    switch (item.type) {
      case _NoteLineType.heading:
        return Padding(
          padding: const EdgeInsets.only(top: 2, bottom: 2),
          child: _buildFormattedText(
            item.text,
            textColor: isDark ? Colors.white : accentColor,
            isDark: isDark,
            baseStyle: TextStyle(
              color: isDark ? Colors.white : accentColor,
              fontSize: fontSize + 1.5,
              fontWeight: FontWeight.bold,
              height: 1.38,
            ),
          ),
        );

      case _NoteLineType.divider:
        return Divider(color: textColor.withOpacity(0.16), height: 12);

      case _NoteLineType.quote:
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: accentColor.withOpacity(isDark ? 0.14 : 0.07),
            borderRadius: const BorderRadius.only(
              topRight: Radius.circular(8),
              bottomRight: Radius.circular(8),
            ),
            border: Border(left: BorderSide(color: accentColor, width: 3)),
          ),
          child: _buildFormattedText(
            item.text,
            textColor: textColor,
            isDark: isDark,
          ),
        );

      case _NoteLineType.bullet:
        final leftIndent = item.indentLevel * 14.0;
        final bulletChar = item.indentLevel == 0 ? '•' : (item.indentLevel == 1 ? '◦' : '▪');
        return Padding(
          padding: EdgeInsets.only(left: leftIndent),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 1, right: 7),
                child: Text(
                  bulletChar,
                  style: TextStyle(
                    color: item.indentLevel == 0
                        ? accentColor
                        : accentColor.withOpacity(0.75),
                    fontSize: fontSize + 1,
                    fontWeight: FontWeight.bold,
                    height: 1.38,
                  ),
                ),
              ),
              Expanded(
                child: _buildKeyValueOrRich(
                  item.text,
                  textColor: textColor,
                  isDark: isDark,
                ),
              ),
            ],
          ),
        );

      case _NoteLineType.ordered:
        final leftIndent = item.indentLevel * 14.0;
        return Padding(
          padding: EdgeInsets.only(left: leftIndent),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 2, right: 7),
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Text(
                  item.orderLabel ?? '1.',
                  style: TextStyle(
                    color: accentColor,
                    fontSize: fontSize - 1.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Expanded(
                child: _buildKeyValueOrRich(
                  item.text,
                  textColor: textColor,
                  isDark: isDark,
                ),
              ),
            ],
          ),
        );

      case _NoteLineType.paragraph:
        return _buildKeyValueOrRich(
          item.text,
          textColor: textColor,
          isDark: isDark,
        );
    }
  }

  Widget _buildKeyValueOrRich(
    String text, {
    required Color textColor,
    required bool isDark,
  }) {
    final baseStyle = TextStyle(
      color: textColor,
      fontSize: fontSize,
      height: 1.48,
    );

    // Highlight concise "Term: Definition" pairs when not already markdown-bolded
    if (!text.contains('**')) {
      final colonIdx = text.indexOf(': ');
      if (colonIdx > 1 && colonIdx <= 44) {
        final keyPart = text.substring(0, colonIdx).trim();
        final valPart = text.substring(colonIdx + 2).trim();
        if (keyPart.isNotEmpty &&
            valPart.isNotEmpty &&
            !keyPart.contains('http') &&
            !keyPart.contains('=')) {
          final spans = [
            TextSpan(
              text: '$keyPart: ',
              style: baseStyle.copyWith(
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.amber.shade200 : const Color(0xFF0F172A),
              ),
            ),
            ..._parseInlineSpans(valPart, baseStyle, isDark: isDark),
          ];
          return selectable
              ? SelectableText.rich(TextSpan(style: baseStyle, children: spans))
              : RichText(text: TextSpan(style: baseStyle, children: spans));
        }
      }
    }

    return _buildFormattedText(text, textColor: textColor, isDark: isDark, baseStyle: baseStyle);
  }

  Widget _buildFormattedText(
    String text, {
    required Color textColor,
    required bool isDark,
    TextStyle? baseStyle,
  }) {
    final effectiveBase = baseStyle ??
        TextStyle(
          color: textColor,
          fontSize: fontSize,
          height: 1.48,
        );
    final spans = _parseInlineSpans(text, effectiveBase, isDark: isDark);
    return selectable
        ? SelectableText.rich(TextSpan(style: effectiveBase, children: spans))
        : RichText(text: TextSpan(style: effectiveBase, children: spans));
  }

  List<InlineSpan> _parseInlineSpans(
    String rawText,
    TextStyle baseStyle, {
    required bool isDark,
  }) {
    final text = rawText.replaceAllMapped(
      RegExp(r'\$([^$\n]+?)\$'),
      (m) => m.group(1) ?? '',
    );

    final pattern = RegExp(
      r'(\*\*(.+?)\*\*|__(.+?)__|`([^`]+)`|\[([^\]]+)\]\([^\)]+\)|(?<!\*)\*([^\*\n]+?)\*(?!\*))',
    );

    final spans = <InlineSpan>[];
    int lastEnd = 0;

    for (final match in pattern.allMatches(text)) {
      if (match.start > lastEnd) {
        spans.add(TextSpan(text: text.substring(lastEnd, match.start)));
      }
      if (match.group(2) != null || match.group(3) != null) {
        final inner = match.group(2) ?? match.group(3)!;
        spans.add(TextSpan(
          text: inner,
          style: baseStyle.copyWith(fontWeight: FontWeight.bold),
        ));
      } else if (match.group(4) != null) {
        spans.add(TextSpan(
          text: ' ${match.group(4)!} ',
          style: baseStyle.copyWith(
            fontFamily: 'monospace',
            fontSize: (baseStyle.fontSize ?? 13.5) - 0.8,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.amber.shade200 : accentColor,
            backgroundColor: accentColor.withOpacity(isDark ? 0.18 : 0.08),
          ),
        ));
      } else if (match.group(5) != null) {
        spans.add(TextSpan(
          text: match.group(5)!,
          style: baseStyle.copyWith(
            color: accentColor,
            decoration: TextDecoration.underline,
            fontWeight: FontWeight.w600,
          ),
        ));
      } else if (match.group(6) != null) {
        spans.add(TextSpan(
          text: match.group(6)!,
          style: baseStyle.copyWith(fontStyle: FontStyle.italic),
        ));
      }
      lastEnd = match.end;
    }

    if (lastEnd < text.length) {
      spans.add(TextSpan(text: text.substring(lastEnd)));
    }
    if (spans.isEmpty) {
      spans.add(TextSpan(text: text));
    }
    return spans;
  }
}

enum _NoteLineType { heading, paragraph, bullet, ordered, quote, divider }

class _NoteLine {
  final _NoteLineType type;
  final String text;
  final String? orderLabel;
  final int indentLevel;
  final double spacingAfter;

  const _NoteLine({
    required this.type,
    required this.text,
    this.orderLabel,
    this.indentLevel = 0,
    this.spacingAfter = 5,
  });
}
