import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Renders AI responses (Markdown headings, bold/italic, inline code,
/// fenced code blocks, bullet/numbered lists, blockquotes, and tables)
/// as rich native Flutter widgets instead of raw `.md` syntax.
class FormattedAiText extends StatelessWidget {
  final String data;
  final Color textColor;
  final Color accentColor;
  final double fontSize;
  final bool selectable;

  const FormattedAiText({
    Key? key,
    required this.data,
    required this.textColor,
    required this.accentColor,
    this.fontSize = 13.5,
    this.selectable = true,
  }) : super(key: key);

  /// Converts raw Markdown text into clean human-readable plain text
  /// (useful for saving notes, flashcards, or clipboard copies).
  static String toPlainText(String raw) {
    final lines = raw.replaceAll('\r\n', '\n').split('\n');
    final out = <String>[];
    bool inCode = false;
    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.startsWith('```')) {
        inCode = !inCode;
        continue;
      }
      if (inCode) {
        out.add(line);
        continue;
      }
      if (RegExp(r'^[-*_]{3,}$').hasMatch(trimmed)) {
        out.add('────────────────────');
        continue;
      }
      String clean = line
          .replaceFirst(RegExp(r'^\s{0,3}#{1,6}\s+'), '')
          .replaceFirst(RegExp(r'^\s*>\s?'), '')
          .replaceFirst(RegExp(r'^(\s*)[-*+]\s+'), r'$1• ');
      clean = _stripInlineMarkdown(clean);
      out.add(clean);
    }
    return out.join('\n').trim();
  }

  static String _stripInlineMarkdown(String text) {
    return text
        .replaceAllMapped(RegExp(r'\*\*(.+?)\*\*'), (m) => m.group(1) ?? '')
        .replaceAllMapped(RegExp(r'__(.+?)__'), (m) => m.group(1) ?? '')
        .replaceAllMapped(RegExp(r'`([^`]+)`'), (m) => m.group(1) ?? '')
        .replaceAllMapped(RegExp(r'\[([^\]]+)\]\([^\)]+\)'), (m) => m.group(1) ?? '')
        .replaceAllMapped(RegExp(r'(?<!\*)\*([^\*\n]+?)\*(?!\*)'), (m) => m.group(1) ?? '')
        .replaceAllMapped(RegExp(r'\$([^$\n]+?)\$'), (m) => m.group(1) ?? '');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final blocks = _parseBlocks(data.replaceAll('\r\n', '\n'));

    if (blocks.isEmpty) {
      return _buildRichText(context, data, isDark: isDark);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int i = 0; i < blocks.length; i++) ...[
          _buildBlock(context, blocks[i], isDark),
          if (i < blocks.length - 1) SizedBox(height: blocks[i].spacingAfter),
        ],
      ],
    );
  }

  Widget _buildBlock(BuildContext context, _MdBlock block, bool isDark) {
    switch (block.type) {
      case _MdBlockType.heading:
        final sizeDelta = block.level == 1
            ? 3.5
            : (block.level == 2 ? 2.5 : (block.level == 3 ? 1.5 : 0.8));
        final headingColor = block.level <= 2
            ? (isDark ? Colors.white : accentColor)
            : textColor;
        return Container(
          padding: EdgeInsets.only(top: block.level <= 2 ? 4 : 2, bottom: 2),
          decoration: block.level <= 2
              ? BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: accentColor.withOpacity(0.22), width: 1),
                  ),
                )
              : null,
          child: _buildRichText(
            context,
            block.text,
            isDark: isDark,
            baseStyle: TextStyle(
              color: headingColor,
              fontSize: fontSize + sizeDelta,
              fontWeight: FontWeight.bold,
              height: 1.35,
            ),
          ),
        );

      case _MdBlockType.divider:
        return Divider(color: textColor.withOpacity(0.15), height: 14, thickness: 1);

      case _MdBlockType.blockquote:
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
          decoration: BoxDecoration(
            color: accentColor.withOpacity(isDark ? 0.14 : 0.08),
            borderRadius: const BorderRadius.only(
              topRight: Radius.circular(8),
              bottomRight: Radius.circular(8),
            ),
            border: Border(
              left: BorderSide(color: accentColor, width: 3.2),
            ),
          ),
          child: _buildRichText(
            context,
            block.text,
            isDark: isDark,
            baseStyle: TextStyle(
              color: textColor.withOpacity(0.92),
              fontSize: fontSize - 0.3,
              height: 1.45,
            ),
          ),
        );

      case _MdBlockType.codeBlock:
        return Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0B1220) : const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.white12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.06),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(9)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      block.language.isNotEmpty ? block.language.toUpperCase() : 'CODE / FORMULA',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.6,
                      ),
                    ),
                    InkWell(
                      onTap: () {
                        Clipboard.setData(ClipboardData(text: block.text));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Code copied to clipboard'),
                            duration: Duration(seconds: 1),
                          ),
                        );
                      },
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.copy, size: 12, color: Colors.white70),
                          SizedBox(width: 4),
                          Text('Copy', style: TextStyle(color: Colors.white70, fontSize: 10)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.all(10),
                child: SelectableText(
                  block.text,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: fontSize - 1.2,
                    color: const Color(0xFFE2E8F0),
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        );

      case _MdBlockType.bulletItem:
        final leftIndent = (block.indentLevel * 14.0).clamp(0.0, 42.0);
        return Padding(
          padding: EdgeInsets.only(left: leftIndent + 2),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 2, right: 7),
                child: Text(
                  block.indentLevel > 0 ? '◦' : '•',
                  style: TextStyle(
                    color: accentColor,
                    fontSize: fontSize + 0.5,
                    fontWeight: FontWeight.bold,
                    height: 1.35,
                  ),
                ),
              ),
              Expanded(
                child: _buildRichText(context, block.text, isDark: isDark),
              ),
            ],
          ),
        );

      case _MdBlockType.orderedItem:
        final leftIndent = (block.indentLevel * 14.0).clamp(0.0, 42.0);
        return Padding(
          padding: EdgeInsets.only(left: leftIndent),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 1, right: 7),
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Text(
                  '${block.orderIndex}.',
                  style: TextStyle(
                    color: accentColor,
                    fontSize: fontSize - 1.3,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Expanded(
                child: _buildRichText(context, block.text, isDark: isDark),
              ),
            ],
          ),
        );

      case _MdBlockType.table:
        final rows = block.tableRows;
        if (rows.isEmpty) return const SizedBox.shrink();
        final colCount = rows.fold<int>(0, (maxC, r) => r.length > maxC ? r.length : maxC);
        if (colCount == 0) return const SizedBox.shrink();

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: textColor.withOpacity(0.18)),
            ),
            clipBehavior: Clip.antiAlias,
            child: Table(
              defaultColumnWidth: const IntrinsicColumnWidth(),
              border: TableBorder.symmetric(
                inside: BorderSide(color: textColor.withOpacity(0.12)),
              ),
              children: [
                for (int rIdx = 0; rIdx < rows.length; rIdx++)
                  TableRow(
                    decoration: BoxDecoration(
                      color: rIdx == 0
                          ? accentColor.withOpacity(isDark ? 0.25 : 0.13)
                          : (rIdx.isOdd
                              ? Colors.transparent
                              : textColor.withOpacity(0.03)),
                    ),
                    children: [
                      for (int cIdx = 0; cIdx < colCount; cIdx++)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                          child: _buildRichText(
                            context,
                            cIdx < rows[rIdx].length ? rows[rIdx][cIdx] : '',
                            isDark: isDark,
                            baseStyle: TextStyle(
                              color: textColor,
                              fontSize: fontSize - 1.0,
                              fontWeight: rIdx == 0 ? FontWeight.bold : FontWeight.normal,
                              height: 1.35,
                            ),
                          ),
                        ),
                    ],
                  ),
              ],
            ),
          ),
        );

      case _MdBlockType.paragraph:
        return _buildRichText(context, block.text, isDark: isDark);
    }
  }

  Widget _buildRichText(
    BuildContext context,
    String text, {
    required bool isDark,
    TextStyle? baseStyle,
  }) {
    final effectiveBase = baseStyle ??
        TextStyle(
          color: textColor,
          fontSize: fontSize,
          height: 1.45,
        );

    final spans = _parseInlineSpans(
      text,
      effectiveBase,
      accentColor: accentColor,
      isDark: isDark,
    );

    if (selectable) {
      return SelectableText.rich(
        TextSpan(style: effectiveBase, children: spans),
      );
    }
    return RichText(
      text: TextSpan(style: effectiveBase, children: spans),
    );
  }

  List<_MdBlock> _parseBlocks(String input) {
    final lines = input.split('\n');
    final blocks = <_MdBlock>[];
    int i = 0;

    while (i < lines.length) {
      final line = lines[i];
      final trimmed = line.trim();

      if (trimmed.isEmpty) {
        i++;
        continue;
      }

      // 1. Fenced code block ```
      if (trimmed.startsWith('```')) {
        final lang = trimmed.substring(3).trim();
        final codeLines = <String>[];
        i++;
        while (i < lines.length && !lines[i].trim().startsWith('```')) {
          codeLines.add(lines[i]);
          i++;
        }
        if (i < lines.length) i++; // skip closing ```
        blocks.add(_MdBlock(
          type: _MdBlockType.codeBlock,
          text: codeLines.join('\n'),
          language: lang,
          spacingAfter: 8,
        ));
        continue;
      }

      // 2. Horizontal rule
      if (RegExp(r'^[-*_]{3,}$').hasMatch(trimmed)) {
        blocks.add(const _MdBlock(type: _MdBlockType.divider, text: '', spacingAfter: 6));
        i++;
        continue;
      }

      // 3. Heading (#, ##, ###, ####)
      final headingMatch = RegExp(r'^(#{1,6})\s+(.+)$').firstMatch(trimmed);
      if (headingMatch != null) {
        blocks.add(_MdBlock(
          type: _MdBlockType.heading,
          text: headingMatch.group(2)!.trim(),
          level: headingMatch.group(1)!.length,
          spacingAfter: 6,
        ));
        i++;
        continue;
      }

      // 4. Markdown table
      if (trimmed.startsWith('|') && trimmed.contains('|', 1)) {
        final tableRows = <List<String>>[];
        while (i < lines.length) {
          final tLine = lines[i].trim();
          if (!tLine.startsWith('|')) break;
          final cells = _splitTableRow(tLine);
          final isSeparator = cells.isNotEmpty &&
              cells.every((c) => RegExp(r'^:?-{2,}:?$').hasMatch(c.trim()));
          if (!isSeparator && cells.isNotEmpty) {
            tableRows.add(cells);
          }
          i++;
        }
        if (tableRows.isNotEmpty) {
          blocks.add(_MdBlock(
            type: _MdBlockType.table,
            text: '',
            tableRows: tableRows,
            spacingAfter: 8,
          ));
          continue;
        }
      }

      // 5. Blockquote
      if (trimmed.startsWith('>')) {
        final quoteLines = <String>[];
        while (i < lines.length && lines[i].trim().startsWith('>')) {
          quoteLines.add(lines[i].trim().replaceFirst(RegExp(r'^>\s?'), ''));
          i++;
        }
        blocks.add(_MdBlock(
          type: _MdBlockType.blockquote,
          text: quoteLines.join('\n'),
          spacingAfter: 8,
        ));
        continue;
      }

      // 6. Bullet list (-, *, +, •)
      final bulletMatch = RegExp(r'^(\s*)([-*+•])\s+(.+)$').firstMatch(line);
      if (bulletMatch != null) {
        final indentSpaces = bulletMatch.group(1)?.length ?? 0;
        final indentLevel = (indentSpaces / 2).floor();
        blocks.add(_MdBlock(
          type: _MdBlockType.bulletItem,
          text: bulletMatch.group(3)!.trim(),
          indentLevel: indentLevel,
          spacingAfter: 4,
        ));
        i++;
        continue;
      }

      // 7. Numbered list (1. or 1))
      final orderedMatch = RegExp(r'^(\s*)(\d+)[\.\)]\s+(.+)$').firstMatch(line);
      if (orderedMatch != null) {
        final indentSpaces = orderedMatch.group(1)?.length ?? 0;
        final indentLevel = (indentSpaces / 2).floor();
        final orderNum = int.tryParse(orderedMatch.group(2) ?? '1') ?? 1;
        blocks.add(_MdBlock(
          type: _MdBlockType.orderedItem,
          text: orderedMatch.group(3)!.trim(),
          indentLevel: indentLevel,
          orderIndex: orderNum,
          spacingAfter: 5,
        ));
        i++;
        continue;
      }

      // 8. Paragraph (group consecutive plain lines)
      final paraLines = <String>[trimmed];
      i++;
      while (i < lines.length) {
        final next = lines[i];
        final nextTrimmed = next.trim();
        if (nextTrimmed.isEmpty ||
            nextTrimmed.startsWith('```') ||
            nextTrimmed.startsWith('#') ||
            nextTrimmed.startsWith('>') ||
            nextTrimmed.startsWith('|') ||
            RegExp(r'^[-*_]{3,}$').hasMatch(nextTrimmed) ||
            RegExp(r'^(\s*)([-*+•]|\d+[\.\)])\s+').hasMatch(next)) {
          break;
        }
        paraLines.add(nextTrimmed);
        i++;
      }
      blocks.add(_MdBlock(
        type: _MdBlockType.paragraph,
        text: paraLines.join('\n'),
        spacingAfter: 7,
      ));
    }

    return blocks;
  }

  List<String> _splitTableRow(String line) {
    var trimmed = line.trim();
    if (trimmed.startsWith('|')) trimmed = trimmed.substring(1);
    if (trimmed.endsWith('|')) trimmed = trimmed.substring(0, trimmed.length - 1);
    return trimmed.split('|').map((c) => c.trim()).toList();
  }

  List<InlineSpan> _parseInlineSpans(
    String rawText,
    TextStyle baseStyle, {
    required Color accentColor,
    required bool isDark,
  }) {
    // Clean inline $math$ delimiters so formulas read cleanly
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
        // Bold **...** or __...__
        final inner = match.group(2) ?? match.group(3)!;
        spans.add(TextSpan(
          text: inner,
          style: baseStyle.copyWith(fontWeight: FontWeight.bold),
        ));
      } else if (match.group(4) != null) {
        // Inline code `...`
        spans.add(TextSpan(
          text: ' ${match.group(4)!} ',
          style: baseStyle.copyWith(
            fontFamily: 'monospace',
            fontSize: (baseStyle.fontSize ?? 13.5) - 0.8,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.amber.shade200 : accentColor,
            backgroundColor: accentColor.withOpacity(isDark ? 0.18 : 0.10),
          ),
        ));
      } else if (match.group(5) != null) {
        // Link [text](url)
        spans.add(TextSpan(
          text: match.group(5)!,
          style: baseStyle.copyWith(
            color: accentColor,
            decoration: TextDecoration.underline,
            fontWeight: FontWeight.w600,
          ),
        ));
      } else if (match.group(6) != null) {
        // Italic *...*
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

enum _MdBlockType {
  heading,
  paragraph,
  bulletItem,
  orderedItem,
  blockquote,
  codeBlock,
  table,
  divider,
}

class _MdBlock {
  final _MdBlockType type;
  final String text;
  final int level;
  final int indentLevel;
  final int orderIndex;
  final String language;
  final List<List<String>> tableRows;
  final double spacingAfter;

  const _MdBlock({
    required this.type,
    required this.text,
    this.level = 1,
    this.indentLevel = 0,
    this.orderIndex = 1,
    this.language = '',
    this.tableRows = const [],
    this.spacingAfter = 6,
  });
}
