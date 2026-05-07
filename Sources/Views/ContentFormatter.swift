import UIKit

/// Represents a segment of content with its type
enum ContentSegment {
    case text(String)
    case quote(authorInfo: String, content: String)  // authorInfo includes name and time
    case code(String)
}

/// Formats forum post content with proper styling for display
class ContentFormatter {

    // MARK: - Configuration

    struct Style {
        var font: UIFont = .systemFont(ofSize: 15)
        var textColor: UIColor = Theme.currentForeground
        var linkColor: UIColor = Theme.linkText
        var quoteBackground: UIColor = Theme.currentMuted
        var quoteTextColor: UIColor = Theme.currentSecondaryText
        var quoteAuthorColor: UIColor = Theme.primary
        var codeBackground: UIColor = Theme.currentMuted
        var lineSpacing: CGFloat = 8
        var paragraphSpacing: CGFloat = 12

        static func current() -> Style {
            return Style(
                font: .systemFont(ofSize: 15),
                textColor: Theme.currentForeground,
                linkColor: Theme.linkText,
                quoteBackground: Theme.currentMuted,
                quoteTextColor: Theme.currentSecondaryText,
                quoteAuthorColor: Theme.primary,
                codeBackground: Theme.currentMuted,
                lineSpacing: 8,
                paragraphSpacing: 12
            )
        }
    }

    static var `default`: Style {
        return Style.current()
    }

    // MARK: - Quote Parsing

    /// Parses content to extract structured segments including quotes
    static func parseContent(_ content: String) -> [ContentSegment] {
        var segments: [ContentSegment] = []
        var remaining = content

        // Pattern to match quote blocks with Discuz format
        // Formats: [quote]...[/quote] or 【quote】...【/quote】
        // Author info typically in [size=2]...[/size] at the start
        let quotePattern = #"\[quote\]([\s\S]*?)\[/quote\]|【quote】([\s\S]*?)【/quote】"#

        while true {
            guard let regex = try? NSRegularExpression(pattern: quotePattern, options: []) else {
                // No valid regex, treat rest as text
                if !remaining.isEmpty {
                    segments.append(.text(remaining))
                }
                break
            }

            let range = NSRange(remaining.startIndex..., in: remaining)
            guard let match = regex.firstMatch(in: remaining, options: [], range: range) else {
                // No more quotes found
                if !remaining.isEmpty {
                    segments.append(.text(remaining))
                }
                break
            }

            // Get text before the quote
            if match.range.location > 0 {
                let beforeRange = NSRange(location: 0, length: match.range.location)
                let beforeText = String(remaining[Range(beforeRange, in: remaining)!])
                if !beforeText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    segments.append(.text(beforeText))
                }
            }

            // Extract quote content (check both capture groups)
            var quoteContent = ""
            if match.range(at: 1).location != NSNotFound,
               let range = Range(match.range(at: 1), in: remaining) {
                quoteContent = String(remaining[range])
            } else if match.range(at: 2).location != NSNotFound,
                      let range = Range(match.range(at: 2), in: remaining) {
                quoteContent = String(remaining[range])
            }

            // Parse author info from [size=2] tag at start
            let (authorInfo, pureContent) = parseQuoteHeader(quoteContent)

            // Clean the content (remove size tags, etc)
            let cleanedContent = cleanQuoteContent(pureContent)

            segments.append(.quote(authorInfo: authorInfo, content: cleanedContent))

            // Continue with remaining text after the quote
            let matchEndIndex = remaining.index(remaining.startIndex, offsetBy: match.range.location + match.range.length)
            remaining = String(remaining[matchEndIndex...])
        }

        return segments
    }

    /// Parses quote header to extract author info and content
    private static func parseQuoteHeader(_ quoteContent: String) -> (authorInfo: String, content: String) {
        // Look for [size=2]...[/size] pattern at the start (Discuz format)
        let sizePattern = #"^\s*\[size=2\](.*?)\[/size\]\s*"#

        if let regex = try? NSRegularExpression(pattern: sizePattern, options: [.dotMatchesLineSeparators]),
           let match = regex.firstMatch(in: quoteContent, options: [], range: NSRange(quoteContent.startIndex..., in: quoteContent)),
           let range = Range(match.range(at: 1), in: quoteContent) {
            let authorInfo = String(quoteContent[range]).trimmingCharacters(in: .whitespacesAndNewlines)
            // Get content after the size tag
            let contentStartIndex = quoteContent.index(quoteContent.startIndex, offsetBy: match.range.length)
            let content = String(quoteContent[contentStartIndex...])
            return (authorInfo, content)
        }

        // Try alternative pattern: 引用: 作者 at start
        let lines = quoteContent.components(separatedBy: "\n")
        var authorInfo = ""
        var contentLines: [String] = []
        var foundAuthor = false

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            // Check if this line looks like author info
            if !foundAuthor && (trimmed.hasPrefix("引用:") || trimmed.hasPrefix("回复:") || trimmed.contains("发表于")) {
                authorInfo = trimmed
                    .replacingOccurrences(of: "引用:", with: "")
                    .replacingOccurrences(of: "回复:", with: "")
                    .trimmingCharacters(in: .whitespaces)
                foundAuthor = true
            } else if foundAuthor {
                contentLines.append(line)
            } else {
                // First line that doesn't match author pattern
                if contentLines.isEmpty && !trimmed.isEmpty {
                    contentLines.append(line)
                } else {
                    contentLines.append(line)
                }
            }
        }

        if authorInfo.isEmpty {
            authorInfo = "引用内容"
        }

        return (authorInfo, contentLines.joined(separator: "\n"))
    }

    /// Cleans quote content by removing size tags, cleaning HTML entities
    private static func cleanQuoteContent(_ content: String) -> String {
        var result = content

        // Remove [size=X]...[/size] tags
        let sizePattern = #"\[size=[^\]]*\](.*?)\[/size\]"#
        if let regex = try? NSRegularExpression(pattern: sizePattern, options: [.dotMatchesLineSeparators]) {
            result = regex.stringByReplacingMatches(in: result, options: [], range: NSRange(result.startIndex..., in: result), withTemplate: "$1")
        }

        // Decode HTML entities
        result = decodeHTMLEntities(result)

        return result.trimmingCharacters(in: .whitespacesAndNewlines)
    }

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

        // Parse content into structured segments
        let segments = parseContent(content)

        for (index, segment) in segments.enumerated() {
            switch segment {
            case .text(let text):
                result.append(formatText(text, style: style))

            case .quote(let authorInfo, let quoteContent):
                result.append(formatQuoteBlock(authorInfo: authorInfo, content: quoteContent, style: style))

            case .code(let codeContent):
                result.append(formatCodeBlock(codeContent, style: style))
            }

            // Add line break between segments (except last)
            if index < segments.count - 1 {
                result.append(NSAttributedString(string: "\n"))
            }
        }

        return result
    }

    /// Formats plain text content
    private static func formatText(_ text: String, style: Style) -> NSAttributedString {
        var result = NSMutableAttributedString()

        // Replace GIF emoticon URLs with emoji placeholder
        var cleanedContent = text.replacingOccurrences(
            of: #"\[img\][^\[\]]*\.(gif|GIF)[^\[\]]*\[/img\]"#,
            with: "[表情]",
            options: .regularExpression
        )
        // Replace real image BBCode with [图片] placeholder (images displayed separately)
        cleanedContent = cleanedContent.replacingOccurrences(
            of: #"\[img\][^\[\]]*\[/img\]"#,
            with: "[图片]",
            options: .regularExpression
        )

        // Split into lines and format
        let lines = cleanedContent.components(separatedBy: "\n")

        for (index, line) in lines.enumerated() {
            let trimmedLine = line.trimmingCharacters(in: .whitespaces)

            if trimmedLine.isEmpty {
                let spacer = NSMutableAttributedString(string: " ")
                let paragraphStyle = NSMutableParagraphStyle()
                paragraphStyle.paragraphSpacing = style.paragraphSpacing / 2
                spacer.addAttribute(.paragraphStyle, value: paragraphStyle, range: NSRange(location: 0, length: 1))
                result.append(spacer)
                continue
            }

            // Check for list items
            if trimmedLine.hasPrefix("• ") || trimmedLine.hasPrefix("- ") || trimmedLine.hasPrefix("* ") {
                result.append(formatListItem(trimmedLine, style: style))
            } else {
                result.append(formatLine(trimmedLine, style: style))
            }

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
        // Check for code block
        if line.contains("[code]") || line.contains("【code】") {
            return formatCodeBlock(line, style: style)
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

            if lastEnd < range.lowerBound {
                let beforeText = String(remaining[lastEnd..<range.lowerBound])
                result.append(formatBBCode(beforeText, font: style.font, color: style.textColor))
            }

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

        if lastEnd < remaining.endIndex {
            let remainingText = String(remaining[lastEnd...])
            result.append(formatBBCode(remainingText, font: style.font, color: style.textColor))
        }

        if result.length == 0 {
            return formatBBCode(line, font: style.font, color: style.textColor)
        }

        return result
    }

    /// Formats text with BBCode tags like [b], [i], [url], etc.
    private static func formatBBCode(_ text: String, font: UIFont, color: UIColor) -> NSAttributedString {
        let result = NSMutableAttributedString()

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

                    if let newFont = bbc.font { currentFont = newFont }
                    if let newColor = bbc.color { currentColor = newColor }
                    if let hasUnderline = bbc.underline { currentUnderline = hasUnderline }
                    if let hasStrikethrough = bbc.strikethrough { currentStrikethrough = hasStrikethrough }
                    break
                }
            }

            if !foundTag {
                var earliestRange: Range<String.Index>?
                for bbc in bbcodes {
                    if let range = remaining.range(of: bbc.tag) {
                        if earliestRange == nil || range.lowerBound < earliestRange!.lowerBound {
                            earliestRange = range
                        }
                    }
                }

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

    /// Formats a quote block with author info and content (Android style)
    private static func formatQuoteBlock(authorInfo: String, content: String, style: Style) -> NSAttributedString {
        let result = NSMutableAttributedString()

        // Add author info line with accent color
        let authorAttr = NSMutableAttributedString(string: authorInfo, attributes: [
            .font: UIFont.systemFont(ofSize: style.font.pointSize - 1, weight: .semibold),
            .foregroundColor: style.quoteAuthorColor
        ])
        result.append(authorAttr)

        // Add separator
        result.append(NSAttributedString(string: "\n"))

        // Add content with quote styling
        let contentFont = UIFont.italicSystemFont(ofSize: style.font.pointSize - 1)
        let contentLines = content.components(separatedBy: "\n")

        for (index, line) in contentLines.enumerated() {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.isEmpty { continue }

            // Format each line with BBCode support
            let formattedLine = formatBBCode(trimmed, font: contentFont, color: style.quoteTextColor)
            result.append(formattedLine)

            if index < contentLines.count - 1 {
                result.append(NSAttributedString(string: "\n"))
            }
        }

        // Apply background to entire quote block
        let fullRange = NSRange(location: 0, length: result.length)
        result.addAttribute(.backgroundColor, value: style.quoteBackground, range: fullRange)

        // Add left border effect via paragraph style
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.headIndent = 8
        paragraphStyle.firstLineHeadIndent = 0
        result.addAttribute(.paragraphStyle, value: paragraphStyle, range: fullRange)

        return result
    }

    /// Formats a code block
    private static func formatCodeBlock(_ codeContent: String, style: Style) -> NSAttributedString {
        var content = codeContent
            .replacingOccurrences(of: "[code]", with: "")
            .replacingOccurrences(of: "[/code]", with: "")
            .replacingOccurrences(of: "【code】", with: "")
            .replacingOccurrences(of: "【/code】", with: "")

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