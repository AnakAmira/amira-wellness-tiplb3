//
//  String+Extensions.swift
//  AmiraWellness
//
//  Created for Amira Wellness app
//  Copyright © 2023 Amira Wellness. All rights reserved.
//

import Foundation
// CommonCrypto - iOS SDK
import CommonCrypto

/// Types of sensitive data that can be masked
public enum SensitiveDataType {
    case email
    case creditCard
    case phoneNumber
    case custom(pattern: String, replacement: String)
}

// MARK: - String Extension
extension String {
    
    // MARK: - Localization
    
    /// Returns a localized version of the string
    var localized: String {
        return NSLocalizedString(self, comment: "")
    }
    
    /// Returns a localized formatted string with the provided arguments
    func localizedWithFormat(_ args: CVarArg...) -> String {
        let localizedFormat = self.localized
        return String(format: localizedFormat, arguments: args)
    }
    
    // MARK: - Validation
    
    /// Checks if the string is a valid email address
    var isValidEmail: Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: self)
    }
    
    /// Checks if the string meets password requirements
    func isValidPassword(minLength: Int = 10, 
                        requiresSpecialCharacter: Bool = true, 
                        requiresNumber: Bool = true, 
                        requiresUppercase: Bool = true) -> Bool {
        
        // Check minimum length
        guard self.count >= minLength else { return false }
        
        // Check for special character if required
        if requiresSpecialCharacter {
            let specialCharacterRegex = ".*[^A-Za-z0-9].*"
            let specialCharacterPredicate = NSPredicate(format: "SELF MATCHES %@", specialCharacterRegex)
            guard specialCharacterPredicate.evaluate(with: self) else { return false }
        }
        
        // Check for number if required
        if requiresNumber {
            let numberRegex = ".*[0-9].*"
            let numberPredicate = NSPredicate(format: "SELF MATCHES %@", numberRegex)
            guard numberPredicate.evaluate(with: self) else { return false }
        }
        
        // Check for uppercase if required
        if requiresUppercase {
            let uppercaseRegex = ".*[A-Z].*"
            let uppercasePredicate = NSPredicate(format: "SELF MATCHES %@", uppercaseRegex)
            guard uppercasePredicate.evaluate(with: self) else { return false }
        }
        
        return true
    }
    
    /// Checks if the string is a valid URL
    var isValidURL: Bool {
        guard let url = URL(string: self) else { return false }
        return UIApplication.shared.canOpenURL(url)
    }
    
    /// Checks if the string is empty or contains only whitespace
    var isEmptyOrWhitespace: Bool {
        return self.trimmed.isEmpty
    }
    
    /// Checks if the string contains only digit characters
    var containsOnlyDigits: Bool {
        guard !self.isEmpty else { return false }
        return CharacterSet.decimalDigits.isSuperset(of: CharacterSet(charactersIn: self))
    }
    
    /// Checks if the string contains only letter characters
    var containsOnlyLetters: Bool {
        guard !self.isEmpty else { return false }
        return CharacterSet.letters.isSuperset(of: CharacterSet(charactersIn: self))
    }
    
    /// Checks if the string contains only alphanumeric characters
    var containsOnlyAlphanumerics: Bool {
        guard !self.isEmpty else { return false }
        return CharacterSet.alphanumerics.isSuperset(of: CharacterSet(charactersIn: self))
    }
    
    // MARK: - Cryptography
    
    /// Returns the MD5 hash of the string
    var md5: String {
        let data = Data(self.utf8)
        let hash = data.withUnsafeBytes { (bytes: UnsafeRawBufferPointer) -> [UInt8] in
            var hash = [UInt8](repeating: 0, count: Int(CC_MD5_DIGEST_LENGTH))
            CC_MD5(bytes.baseAddress, CC_LONG(data.count), &hash)
            return hash
        }
        
        return hash.map { String(format: "%02x", $0) }.joined()
    }
    
    /// Returns the SHA-256 hash of the string
    var sha256: String {
        let data = Data(self.utf8)
        let hash = data.withUnsafeBytes { (bytes: UnsafeRawBufferPointer) -> [UInt8] in
            var hash = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
            CC_SHA256(bytes.baseAddress, CC_LONG(data.count), &hash)
            return hash
        }
        
        return hash.map { String(format: "%02x", $0) }.joined()
    }
    
    /// Returns the Base64 encoded representation of the string
    var base64Encoded: String? {
        return data(using: .utf8)?.base64EncodedString()
    }
    
    /// Returns the Base64 decoded string
    var base64Decoded: String? {
        guard let data = Data(base64Encoded: self) else { return nil }
        return String(data: data, encoding: .utf8)
    }
    
    // MARK: - String Manipulation
    
    /// Returns a new string with whitespace and newlines trimmed from both ends
    var trimmed: String {
        return self.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    /// Returns a truncated version of the string with an optional suffix
    func truncated(length: Int, suffix: String = "...") -> String {
        if self.count <= length {
            return self
        }
        return String(self.prefix(length)) + suffix
    }
    
    /// Returns a new string with the first letter capitalized
    var capitalizingFirstLetter: String {
        guard !self.isEmpty else { return "" }
        return prefix(1).capitalized + dropFirst()
    }
    
    // MARK: - Emoji Handling
    
    /// Checks if the string contains any emoji characters
    var containsEmoji: Bool {
        for scalar in unicodeScalars {
            switch scalar.value {
            case 0x1F600...0x1F64F, // Emoticons
                 0x1F300...0x1F5FF, // Misc Symbols and Pictographs
                 0x1F680...0x1F6FF, // Transport and Map
                 0x1F700...0x1F77F, // Alchemical Symbols
                 0x1F780...0x1F7FF, // Geometric Shapes
                 0x1F800...0x1F8FF, // Supplemental Arrows-C
                 0x1F900...0x1F9FF, // Supplemental Symbols and Pictographs
                 0x1FA00...0x1FA6F, // Chess Symbols
                 0x1FA70...0x1FAFF, // Symbols and Pictographs Extended-A
                 0x2600...0x26FF,   // Misc symbols
                 0x2700...0x27BF,   // Dingbats
                 0xFE00...0xFE0F,   // Variation Selectors
                 0x1F000...0x1F02F, // Mahjong
                 0x1F0A0...0x1F0FF, // Playing Cards
                 127000...127600,   // Various asian characters
                 65024...65039,     // Variation selector
                 9100...9300,       // Misc items
                 8400...8447:       // Combining Diacritical Marks for Symbols
                return true
            default:
                continue
            }
        }
        return false
    }
    
    /// Returns a new string with all emoji characters removed
    var removingEmoji: String {
        return String(self.unicodeScalars.filter { scalar in
            switch scalar.value {
            case 0x1F600...0x1F64F, // Emoticons
                 0x1F300...0x1F5FF, // Misc Symbols and Pictographs
                 0x1F680...0x1F6FF, // Transport and Map
                 0x1F700...0x1F77F, // Alchemical Symbols
                 0x1F780...0x1F7FF, // Geometric Shapes
                 0x1F800...0x1F8FF, // Supplemental Arrows-C
                 0x1F900...0x1F9FF, // Supplemental Symbols and Pictographs
                 0x1FA00...0x1FA6F, // Chess Symbols
                 0x1FA70...0x1FAFF, // Symbols and Pictographs Extended-A
                 0x2600...0x26FF,   // Misc symbols
                 0x2700...0x27BF,   // Dingbats
                 0xFE00...0xFE0F,   // Variation Selectors
                 0x1F000...0x1F02F, // Mahjong
                 0x1F0A0...0x1F0FF, // Playing Cards
                 127000...127600,   // Various asian characters
                 65024...65039,     // Variation selector
                 9100...9300,       // Misc items
                 8400...8447:       // Combining Diacritical Marks for Symbols
                return false
            default:
                return true
            }
        })
    }
    
    // MARK: - Type Conversion
    
    /// Converts the string to a Date using the specified format
    func toDate(format: String = "yyyy-MM-dd'T'HH:mm:ssZ") -> Date? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = format
        dateFormatter.locale = Locale.current
        return dateFormatter.date(from: self)
    }
    
    /// Converts the string to a URL
    var toURL: URL? {
        return URL(string: self)
    }
    
    /// Converts the string to an Int
    var toInt: Int? {
        return Int(self)
    }
    
    /// Converts the string to a Double
    var toDouble: Double? {
        return Double(self)
    }
    
    /// Converts the string to a Bool
    var toBool: Bool? {
        let lowercased = self.lowercased()
        if ["true", "yes", "1", "y"].contains(lowercased) {
            return true
        } else if ["false", "no", "0", "n"].contains(lowercased) {
            return false
        }
        return nil
    }
    
    // MARK: - Content Extraction
    
    /// Returns the number of words in the string
    var wordCount: Int {
        let chararacterSet = CharacterSet.whitespacesAndNewlines.union(.punctuationCharacters)
        let components = self.components(separatedBy: chararacterSet)
        let words = components.filter { !$0.isEmpty }
        return words.count
    }
    
    /// Extracts all URLs from the string
    var extractURLs: [URL] {
        var urls: [URL] = []
        do {
            let detector = try NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
            let matches = detector.matches(in: self, options: [], range: NSRange(location: 0, length: self.utf16.count))
            
            for match in matches {
                if let url = match.url {
                    urls.append(url)
                }
            }
        } catch {
            print("Error extracting URLs: \(error.localizedDescription)")
        }
        return urls
    }
    
    /// Extracts all email addresses from the string
    var extractEmails: [String] {
        var emails: [String] = []
        do {
            let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
            let emailDetector = try NSRegularExpression(pattern: emailRegex, options: [])
            let matches = emailDetector.matches(in: self, options: [], range: NSRange(location: 0, length: self.utf16.count))
            
            for match in matches {
                if let range = Range(match.range, in: self) {
                    emails.append(String(self[range]))
                }
            }
        } catch {
            print("Error extracting emails: \(error.localizedDescription)")
        }
        return emails
    }
    
    /// Extracts all phone numbers from the string
    var extractPhoneNumbers: [String] {
        var phoneNumbers: [String] = []
        do {
            let detector = try NSDataDetector(types: NSTextCheckingResult.CheckingType.phoneNumber.rawValue)
            let matches = detector.matches(in: self, options: [], range: NSRange(location: 0, length: self.utf16.count))
            
            for match in matches {
                if let range = Range(match.range, in: self) {
                    phoneNumbers.append(String(self[range]))
                }
            }
        } catch {
            print("Error extracting phone numbers: \(error.localizedDescription)")
        }
        return phoneNumbers
    }
    
    // MARK: - HTML Processing
    
    /// Converts HTML string to NSAttributedString
    var htmlToAttributedString: NSAttributedString? {
        guard let data = data(using: .utf8) else { return nil }
        do {
            return try NSAttributedString(data: data,
                                         options: [.documentType: NSAttributedString.DocumentType.html,
                                                  .characterEncoding: String.Encoding.utf8.rawValue],
                                         documentAttributes: nil)
        } catch {
            print("Error converting HTML to attributed string: \(error.localizedDescription)")
            return nil
        }
    }
    
    /// Converts HTML string to plain text
    var htmlToString: String {
        return htmlToAttributedString?.string ?? self
    }
    
    // MARK: - Security
    
    /// Masks sensitive data in the string, such as email addresses or credit card numbers
    func maskSensitiveData(type: SensitiveDataType) -> String {
        switch type {
        case .email:
            // Format: j***@example.com
            let components = self.components(separatedBy: "@")
            guard components.count == 2 else { return self }
            
            let username = components[0]
            let domain = components[1]
            
            if username.count <= 1 {
                return self // Too short to mask effectively
            }
            
            let firstChar = username.prefix(1)
            let masked = firstChar + String(repeating: "*", count: min(3, username.count - 1))
            return "\(masked)@\(domain)"
            
        case .creditCard:
            // Format: 4321 **** **** 1234
            let cleanedString = self.replacingOccurrences(of: "[^0-9]", with: "", options: .regularExpression)
            guard cleanedString.count >= 8 else { return self } // Too short to be a valid card
            
            let firstFour = cleanedString.prefix(4)
            let lastFour = cleanedString.suffix(4)
            let middleStars = String(repeating: "*", count: max(0, cleanedString.count - 8))
            
            return "\(firstFour) \(middleStars.inserting(separator: " ", every: 4)) \(lastFour)".trimmingCharacters(in: .whitespaces)
            
        case .phoneNumber:
            // Format: ***-***-1234
            let cleanedString = self.replacingOccurrences(of: "[^0-9]", with: "", options: .regularExpression)
            guard cleanedString.count >= 4 else { return self }
            
            let lastFour = cleanedString.suffix(4)
            let starsCount = cleanedString.count - 4
            let stars = String(repeating: "*", count: starsCount)
            
            if cleanedString.count == 10 {
                // Format for US number: ***-***-1234
                return "***-***-\(lastFour)"
            } else {
                // Generic format with appropriate number of stars
                return "\(stars)-\(lastFour)"
            }
            
        case .custom(let pattern, let replacement):
            do {
                let regex = try NSRegularExpression(pattern: pattern, options: [])
                let range = NSRange(location: 0, length: self.utf16.count)
                return regex.stringByReplacingMatches(in: self, options: [], range: range, withTemplate: replacement)
            } catch {
                print("Error applying custom mask: \(error.localizedDescription)")
                return self
            }
        }
    }
}

// MARK: - String Utils
private extension String {
    func inserting(separator: String, every n: Int) -> String {
        var result: String = ""
        let characters = Array(self)
        stride(from: 0, to: characters.count, by: n).forEach {
            result += String(characters[$0..<min($0+n, characters.count)])
            if $0+n < characters.count {
                result += separator
            }
        }
        return result
    }
}