//
//  MarkdownList.swift
//  Pods
//
//  Created by Ivan Bruel on 18/07/16.
//
//
import Foundation

open class MarkdownList: MarkdownLevelElement {

  fileprivate static let regex = "^([\\*\\+\\-]{1,%@})\\s+(.+)$"

  open var maxLevel: Int
  open var font: MarkdownFont?
  open var color: MarkdownColor?
  open var indicator: String
  /// String used before the indicator.
  open var paragraphPrefix: String
  /// String used between the indicator and list item content.
  open var paragraphSuffix: String
  /// Value that defines the spacing between bullet points.
  /// Default value in case `paragraphSpacing` is `nil` = `ElementFont.pointSize / 3`.
  ///
  /// Negative values are ignored as per `paragraphSpacingBefore` of `NSParagraphStyle`
  /// implementation details. The value is used to set `paragraphSpacingBefore` property
  /// of the list paragraph's string attribute.
  open var paragraphSpacing: CGFloat?

  open var regex: String {
    let level: String = maxLevel > 0 ? "\(maxLevel)" : ""
    return String(format: MarkdownList.regex, level)
  }

  public init(font: MarkdownFont? = nil,
              maxLevel: Int = 0,
              indicator: String = "•",
              paragraphPrefix: String = "  ",
              paragraphSuffix: String = " ",
              color: MarkdownColor? = nil,
              paragraphSpacing: CGFloat? = nil)
  {
    self.maxLevel = maxLevel
    self.indicator = indicator
    self.paragraphPrefix = paragraphPrefix
    self.paragraphSuffix = paragraphSuffix
    self.font = font
    self.color = color
    self.paragraphSpacing = paragraphSpacing
  }

  open func formatText(_ attributedString: NSMutableAttributedString, range: NSRange, level: Int) {
    var string = (0..<level).reduce("") { (string, _) -> String in
      return "\(string)\(paragraphPrefix)"
    }
    string = "\(string)\(indicator)\(paragraphSuffix)"

    var attrs = self.attributesForLevel(level)

    // Calculate proper offsets
    let calcFont = font ?? MarkdownParser.defaultFont
    let paragraphStyle = NSMutableParagraphStyle.init()
    paragraphStyle.paragraphSpacingBefore = paragraphSpacing ?? (calcFont.pointSize / 3)
    let headIndent = string.boundingRect(with: CGSize(width : CGFloat.greatestFiniteMagnitude,
                                                      height: CGFloat.greatestFiniteMagnitude),
                                         options: [.usesLineFragmentOrigin],
                                         attributes: [NSAttributedString.Key.font : calcFont],
                                         context: nil).size.width
    paragraphStyle.headIndent = headIndent
    attrs[NSAttributedString.Key.paragraphStyle] = paragraphStyle

    // Make sure to add attributes for the current range BEFORE we replace characters there,
    // otherwise incorrect attributes will be used for the MarkdownList element.
    attributedString.addAttributes(attrs, range: range)

    attributedString.replaceCharacters(in: range, with: string)
  }
}
