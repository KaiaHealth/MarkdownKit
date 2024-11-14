//
//  MarkdownLink.swift
//  Pods
//
//  Created by Ivan Bruel on 18/07/16.
//
//
import Foundation

open class MarkdownLink: MarkdownLinkElement {
  private struct Constants {
    /// The RFC 5322 official standard email regex
    ///
    /// Source: https://emailregex.com/
    static let emailRegex = "^(?:[A-Za-z0-9!#$%&'*+/=?^_`{|}~-]+(?:\\.[A-Za-z0-9!#$%&'*+/=?^_`{|}~-]+)*|\"(?:[\\x01-\\x08\\x0b\\x0c\\x0e-\\x1f\\x21\\x23-\\x5b\\x5d-\\x7f]|\\\\[\\x01-\\x09\\x0b\\x0c\\x0e-\\x7f])*\")@(?:(?:[A-Za-z0-9](?:[A-Za-z0-9-]*[A-Za-z0-9])?\\.)+[A-Za-z0-9](?:[A-Za-z0-9-]*[A-Za-z0-9])?|\\[(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?|[A-Za-z0-9-]*[A-Za-z0-9]:(?:[\\x01-\\x08\\x0b\\x0c\\x0e-\\x1f\\x21-\\x5a\\x53-\\x7f]|\\\\[\\x01-\\x09\\x0b\\x0c\\x0e-\\x7f])+)\\])$"
    static let emailScheme = "mailto:"
  }

  fileprivate static let regex = "(\\[[^\\]]+)(\\]\\([^\\s]+)?\\)"

  private let schemeRegex = "([a-z]{2,20}):\\/\\/"
  private var defaultSchemeOrHttps: String { defaultScheme ?? "https://" }

  open var font: MarkdownFont?
  open var color: MarkdownColor?
  open var defaultScheme: String?

  open var regex: String {
    return MarkdownLink.regex
  }

  open func regularExpression() throws -> NSRegularExpression {
    return try NSRegularExpression(pattern: regex, options: .dotMatchesLineSeparators)
  }

  public init(font: MarkdownFont? = nil, color: MarkdownColor? = MarkdownLink.defaultColor) {
    self.font = font
    self.color = color
  }

  open func formatText(_ attributedString: NSMutableAttributedString, range: NSRange, link: String) {
    let regex = try? NSRegularExpression(pattern: schemeRegex, options: .caseInsensitive)
    let hasScheme = regex?.firstMatch(
      in: link,
      options: .anchored,
      range: NSRange(0..<link.count)
    ) != nil

    let fullLink = hasScheme ? link : "\(defaultSchemeOrHttps)\(link)"

    guard let encodedLink = fullLink.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) else { return }
    guard let url = URL(string: link) ?? URL(string: encodedLink), let transformedURL = transformedURL(url) else { return }
    attributedString.addAttribute(NSAttributedString.Key.link, value: transformedURL, range: range)
  }

  open func match(_ match: NSTextCheckingResult, attributedString: NSMutableAttributedString) {
    // Remove opening bracket
    attributedString.deleteCharacters(in: NSRange(location: match.range(at: 1).location, length: 1))

    // Remove closing bracket
    attributedString.deleteCharacters(in: NSRange(location: match.range(at: 2).location - 1, length: 1))

    let urlStart = match.range(at: 2).location

    let string = NSString(string: attributedString.string)
    var urlString = String(string.substring(with: NSRange(urlStart..<match.range(at: 2).upperBound - 2 )))

    // Balance opening and closing parantheses inside the url
    var numberOfOpeningParantheses = 0
    var numberOfClosingParantheses = 0
    for (index, character) in urlString.enumerated() {
      switch character {
      case "(": numberOfOpeningParantheses += 1
      case ")": numberOfClosingParantheses += 1
      default: continue
      }
      if numberOfClosingParantheses > numberOfOpeningParantheses {
        urlString = NSString(string: urlString).substring(with: NSRange(0..<index))
        break
      }
    }

    // Remove opening parantheses
    attributedString.deleteCharacters(in: NSRange(location: match.range(at: 2).location, length: 1))

    // Remove closing parantheses
    let trailingMarkdownRange = NSRange(location: match.range(at: 2).location - 1, length: urlString.count + 1)
    attributedString.deleteCharacters(in: trailingMarkdownRange)

    let formatRange = NSRange(match.range(at: 1).location..<match.range(at: 2).location - 1)

    // Add attributes while preserving current attributes

    let currentAttributes = attributedString.attributes(
      at: formatRange.location,
      longestEffectiveRange: nil,
      in: formatRange
    )

    addAttributes(attributedString, range: formatRange)
    formatText(attributedString, range: formatRange, link: urlString)

    if let font = currentAttributes[.font] as? MarkdownFont {
      attributedString.addAttribute(
        NSAttributedString.Key.font,
        value: font,
        range: formatRange
      )
    }
  }

  open func addAttributes(_ attributedString: NSMutableAttributedString, range: NSRange) {
    attributedString.addAttributes(attributes, range: range)
  }

  /// - Returns: A transformed version of the given `URL`, adding e-mail or default scheme.
  /// Ignores URLs which already has a scheme.
  private func transformedURL(_ url: URL) -> URL? {
    guard url.scheme == nil else {
      return url
    }

    let urlString = url.absoluteString
    return URL(string: (isEmailAddress(urlString) ? Constants.emailScheme : defaultSchemeOrHttps) + urlString)
  }

  private func isEmailAddress(_ string: String) -> Bool {
    return string.range(of: Constants.emailRegex, options: .regularExpression) != nil
  }
}
