import UIKit

/// Formats forum post content with proper styling for display
class ContentFormatter {

    // MARK: - Configuration

    struct Style {
        var font: UIFont = .systemFont(ofSize: 15)
        var textColor: UIColor = Theme.bodyText
        var linkColor: UIColor = Theme.linkText
        var quoteBackground: UIColor = Theme.muted
        var quoteTextColor: UIColor = Theme.secondaryText
        var codeBackground: UIColor = Theme.muted
        var lineSpacing: CGFloat = 6
        var paragraphSpacing: CGFloat = 12
    }

    static var `default` = Style()

    // MARK: - HTML Entity Decoding

    /// Decodes common HTML entities in text
    static func decodeHTMLEntities(_ text: String) -> String {
        var result = text
        let entities: [String: String] = [
            "&nbsp;": " ",
            "&ensp;": " ",
            "&emsp;": "    ",
            "&lt;": "<",
            "&gt;": ">",
            "&amp;": "&",
            "&quot;": "\"",
            "&apos;": "'",
            "&#39;": "'",
            "&mdash;": "\u{2014}",
            "&ndash;": "\u{2013}",
            "&copy;": "\u{00A9}",
            "&reg;": "\u{00AE}",
            "&trade;": "\u{2122}",
            "&hellip;": "\u{2026}",
            "&bull;": "\u{2022}",
            "&middot;": "\u{00B7}",
            "&#x27;": "'",
            "&lsquo;": "\u{2018}",
            "&rsquo;": "\u{2019}",
            "&ldquo;": "\u{201C}",
            "&rdquo;": "\u{201D}",
        ]

        for (entity, replacement) in entities {
            result = result.replacingOccurrences(of: entity, with: replacement)
        }

        // Handle numeric entities
        let numericPattern = #"&#(\d+);"#
        if let regex = try? NSRegularExpression(pattern: numericPattern, options: []) {
            let range = NSRange(result.startIndex..., in: result)
            result = regex.stringByReplacingMatches(in: result, options: [], range: range, withTemplate: "")
        }

        return result
    }

    // MARK: - Main Formatting

    /// Converts raw post content to attributed string with proper formatting
    static func format(_ content: String, style: Style = `default`) -> NSAttributedString {
        let result = NSMutableAttributedString()

        // Decode HTML entities first
        let cleanedContent = decodeHTMLEntities(content)

        // Detect and preserve list structure
        let lines = cleanedContent.components(separatedBy: "\n")

        for (index, line) in lines.enumerated() {
            let trimmedLine = line.trimmingCharacters(in: .whitespaces)

            if trimmedLine.isEmpty {
                // Empty line - add small spacing
                let spacer = NSMutableAttributedString(string: " ")
                let paragraphStyle = NSMutableParagraphStyle()
                paragraphStyle.paragraphSpacing = style.paragraphSpacing / 2
                spacer.addAttribute(.paragraphStyle, value: paragraphStyle, range: NSRange(location: 0, length: 1))
                result.append(spacer)
                continue
            }

            // Check for list items
            if trimmedLine.hasPrefix("• ") || trimmedLine.hasPrefix("- ") || trimmedLine.hasPrefix("* ") {
                let listItem = formatListItem(trimmedLine, style: style)
                result.append(listItem)
            } else {
                // Format the line
                let formattedLine = formatLine(trimmedLine, style: style)
                result.append(formattedLine)
            }

            // Add line break if not the last line
            if index < lines.count - 1 {
                result.append(NSAttributedString(string: "\n"))
            }
        }

        return result
    }

    /// Formats a list item with bullet
    private static func formatListItem(_ line: String, style: Style) -> NSAttributedString {
        let bullet = "  •  "
        let content: String
        if line.hasPrefix("• ") {
            content = String(line.dropFirst(2))
        } else if line.hasPrefix("- ") || line.hasPrefix("* ") {
            content = String(line.dropFirst(2))
        } else {
            content = line
        }

        let result = NSMutableAttributedString(attributedString: formatLine(content, style: style))
        result.insert(NSAttributedString(string: bullet), at: 0)
        return result
    }

    /// Formats a single line with BBCode-style formatting
    private static func formatLine(_ line: String, style: Style) -> NSAttributedString {
        // Check for quote block (may be anywhere in line)
        if line.contains("[quote]") || line.contains("【quote】") {
            return formatQuote(line, style: style)
        }

        // Check for code block
        if line.contains("[code]") || line.contains("【code】") {
            return formatCode(line, style: style)
        }

        // Process URLs first
        var remaining = line
        let result = NSMutableAttributedString()
        let urlPattern = #"https?://[^\s\u4e00-\u9fa5<>\[\]]+"#

        guard let urlRegex = try? NSRegularExpression(pattern: urlPattern, options: []) else {
            return formatBBCode(line, font: style.font, color: style.textColor)
        }

        let searchRange = NSRange(remaining.startIndex..., in: remaining)
        var lastEnd = remaining.startIndex

        let matches = urlRegex.matches(in: remaining, options: [], range: searchRange)

        for match in matches {
            guard let range = Range(match.range, in: remaining) else { continue }

            // Add text before this match with BBCode formatting
            if lastEnd < range.lowerBound {
                let beforeText = String(remaining[lastEnd..<range.lowerBound])
                result.append(formatBBCode(beforeText, font: style.font, color: style.textColor))
            }

            // Add the URL with styling
            let urlString = String(remaining[range])
            let urlAttributed = NSMutableAttributedString(string: urlString)
            urlAttributed.addAttributes([
                .font: style.font,
                .foregroundColor: style.linkColor,
                .underlineStyle: NSUnderlineStyle.single.rawValue
            ], range: NSRange(location: 0, length: urlString.count))

            if let url = URL(string: urlString) {
                urlAttributed.addAttribute(.link, value: url, range: NSRange(location: 0, length: urlString.count))
            }
            result.append(urlAttributed)

            lastEnd = range.upperBound
        }

        // Add remaining text with BBCode formatting
        if lastEnd < remaining.endIndex {
            let remainingText = String(remaining[lastEnd...])
            result.append(formatBBCode(remainingText, font: style.font, color: style.textColor))
        }

        // If result is empty, just return BBCode formatted line
        if result.length == 0 {
            return formatBBCode(line, font: style.font, color: style.textColor)
        }

        return result
    }

    /// Formats text with BBCode tags like [b], [i], [url], etc.
    private static func formatBBCode(_ text: String, font: UIFont, color: UIColor) -> NSAttributedString {
        let result = NSMutableAttributedString()

        // BBCode patterns in order of processing
        struct BBCodePattern {
            let tag: String
            let font: UIFont?
            let color: UIColor?
            let underline: Bool?
            let strikethrough: Bool?
        }

        let bbcodes: [BBCodePattern] = [
            BBCodePattern(tag: "[b]", font: UIFont.boldSystemFont(ofSize: font.pointSize), color: nil, underline: nil, strikethrough: nil),
            BBCodePattern(tag: "[/b]", font: font, color: nil, underline: nil, strikethrough: nil),
            BBCodePattern(tag: "[i]", font: UIFont.italicSystemFont(ofSize: font.pointSize), color: nil, underline: nil, strikethrough: nil),
            BBCodePattern(tag: "[/i]", font: font, color: nil, underline: nil, strikethrough: nil),
            BBCodePattern(tag: "[u]", font: nil, color: nil, underline: true, strikethrough: nil),
            BBCodePattern(tag: "[/u]", font: nil, color: nil, underline: false, strikethrough: nil),
            BBCodePattern(tag: "[red]", font: nil, color: UIColor.systemRed, underline: nil, strikethrough: nil),
            BBCodePattern(tag: "[/red]", font: nil, color: color, underline: nil, strikethrough: nil),
            BBCodePattern(tag: "[blue]", font: nil, color: UIColor.systemBlue, underline: nil, strikethrough: nil),
            BBCodePattern(tag: "[/blue]", font: nil, color: color, underline: nil, strikethrough: nil),
            BBCodePattern(tag: "[green]", font: nil, color: UIColor.systemGreen, underline: nil, strikethrough: nil),
            BBCodePattern(tag: "[/green]", font: nil, color: color, underline: nil, strikethrough: nil),
            BBCodePattern(tag: "[s]", font: nil, color: nil, underline: nil, strikethrough: true),
            BBCodePattern(tag: "[/s]", font: nil, color: nil, underline: nil, strikethrough: false),
        ]

        var remaining = text
        var currentFont = font
        var currentColor = color
        var currentUnderline = false
        var currentStrikethrough = false

        while !remaining.isEmpty {
            var foundTag = false

            for bbc in bbcodes {
                if remaining.hasPrefix(bbc.tag) {
                    remaining = String(remaining.dropFirst(bbc.tag.count))
                    foundTag = true

                    // Apply attributes based on tag
                    if let newFont = bbc.font {
                        currentFont = newFont
                    }
                    if let newColor = bbc.color {
                        currentColor = newColor
                    }
                    if let hasUnderline = bbc.underline {
                        currentUnderline = hasUnderline
                    }
                    if let hasStrikethrough = bbc.strikethrough {
                        currentStrikethrough = hasStrikethrough
                    }
                    break
                }
            }

            if !foundTag {
                // Find next tag
                var earliestRange: Range<String.Index>?
                for bbc in bbcodes {
                    if let range = remaining.range(of: bbc.tag) {
                        if earliestRange == nil || range.lowerBound < earliestRange!.lowerBound {
                            earliestRange = range
                        }
                    }
                }

                // Add text up to next tag (or end)
                let textToAdd: String
                if let range = earliestRange {
                    textToAdd = String(remaining[..<range.lowerBound])
                    remaining = String(remaining[range.lowerBound...])
                } else {
                    textToAdd = remaining
                    remaining = ""
                }

                if !textToAdd.isEmpty {
                    var attributes: [NSAttributedString.Key: Any] = [
                        .font: currentFont,
                        .foregroundColor: currentColor
                    ]

                    if currentUnderline {
                        attributes[.underlineStyle] = NSUnderlineStyle.single.rawValue
                    }
                    if currentStrikethrough {
                        attributes[.strikethroughStyle] = NSUnderlineStyle.single.rawValue
                    }

                    let attrStr = NSAttributedString(string: textToAdd, attributes: attributes)
                    result.append(attrStr)
                }
            }
        }

        return result
    }

    /// Formats a quote block
    private static func formatQuote(_ line: String, style: Style) -> NSAttributedString {
        // Remove quote markers
        var content = line
            .replacingOccurrences(of: "[quote]", with: "")
            .replacingOccurrences(of: "[/quote]", with: "")
            .replacingOccurrences(of: "【quote】", with: "")
            .replacingOccurrences(of: "【/quote】", with: "")

        // Remove "引用:" or "回复:" prefix
        let prefixes = ["引用:", "回复:", "Originally posted by", "原帖:"]
        for prefix in prefixes {
            if content.hasPrefix(prefix) {
                content = String(content.dropFirst(prefix.count)).trimmingCharacters(in: .whitespaces)
            }
        }

        // Format with quote styling
        let quoteFont = UIFont.italicSystemFont(ofSize: style.font.pointSize - 1)
        let attributed = NSMutableAttributedString(string: content, attributes: [
            .font: quoteFont,
            .foregroundColor: style.quoteTextColor
        ])

        // Add background
        let fullRange = NSRange(location: 0, length: attributed.length)
        attributed.addAttribute(.backgroundColor, value: style.quoteBackground, range: fullRange)

        return attributed
    }

    /// Formats a code block
    private static func formatCode(_ line: String, style: Style) -> NSAttributedString {
        var content = line
            .replacingOccurrences(of: "[code]", with: "")
            .replacingOccurrences(of: "[/code]", with: "")
            .replacingOccurrences(of: "【code】", with: "")
            .replacingOccurrences(of: "【/code】", with: "")

        // Monospace font for code
        let codeFont = UIFont.monospacedSystemFont(ofSize: style.font.pointSize - 1, weight: .regular)
        let attributed = NSMutableAttributedString(string: content, attributes: [
            .font: codeFont,
            .foregroundColor: style.textColor,
            .backgroundColor: style.codeBackground
        ])

        return attributed
    }
}

// MARK: - PostCell Content Update

extension PostCell {

    /// Updates the content label with formatted content
    func setFormattedContent(_ content: String) {
        let formattedContent = ContentFormatter.format(content)

        contentLabel.attributedText = formattedContent
        contentLabel.numberOfLines = 0
        contentLabel.isUserInteractionEnabled = true
    }
}