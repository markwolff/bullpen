import Foundation

/// Visual traits that define a unique pixel-art appearance for an agent.
/// Traits are deterministically derived from the session ID so the same
/// agent always looks the same.
public struct CharacterTraits: Sendable, Equatable {
    /// Hoodie main and dark (shadow) colors as hex ints
    public let hoodieColor: Int
    public let hoodieDarkColor: Int

    /// Skin tone main and mouth highlight colors
    public let skinColor: Int
    public let mouthColor: Int

    /// Eye main and dark colors
    public let eyeColor: Int
    public let eyeDarkColor: Int

    /// Hairstyle visible above the hood
    public let hairStyle: HairStyle

    /// Hair color as hex int
    public let hairColor: Int

    /// Optional accessory
    public let accessory: Accessory

    public init(
        hoodieColor: Int, hoodieDarkColor: Int,
        skinColor: Int, mouthColor: Int,
        eyeColor: Int, eyeDarkColor: Int,
        hairStyle: HairStyle, hairColor: Int,
        accessory: Accessory
    ) {
        self.hoodieColor = hoodieColor
        self.hoodieDarkColor = hoodieDarkColor
        self.skinColor = skinColor
        self.mouthColor = mouthColor
        self.eyeColor = eyeColor
        self.eyeDarkColor = eyeDarkColor
        self.hairStyle = hairStyle
        self.hairColor = hairColor
        self.accessory = accessory
    }

    // MARK: - Deterministic Generation

    /// Generates traits by hashing the session ID. Same session always produces
    /// the same visual identity.
    public static func from(sessionID: String, agentType: AgentType) -> CharacterTraits {
        let hash = djb2Hash(sessionID)

        // Pick hoodie color from warm (Claude) or cool (Codex) pool
        let hoodiePair = hoodiePool(for: agentType)[Int(hash % 4)]

        // Skin tone
        let skinPair = skinTones[Int((hash >> 8) % UInt64(skinTones.count))]

        // Eye color
        let eyePair = eyeColors[Int((hash >> 12) % UInt64(eyeColors.count))]

        // Hair style
        let allHairStyles = HairStyle.allCases
        let hairStyle = allHairStyles[Int((hash >> 16) % UInt64(allHairStyles.count))]

        // Hair color
        let hairCol = hairColors[Int((hash >> 20) % UInt64(hairColors.count))]

        // Accessory
        let allAccessories = Accessory.allCases
        let accessory = allAccessories[Int((hash >> 24) % UInt64(allAccessories.count))]

        return CharacterTraits(
            hoodieColor: hoodiePair.main, hoodieDarkColor: hoodiePair.dark,
            skinColor: skinPair.main, mouthColor: skinPair.mouth,
            eyeColor: eyePair.main, eyeDarkColor: eyePair.dark,
            hairStyle: hairStyle, hairColor: hairCol,
            accessory: accessory
        )
    }

    // MARK: - Color Pools

    private static func hoodiePool(for agentType: AgentType) -> [(main: Int, dark: Int)] {
        switch agentType {
        case .claudeCode:
            return [
                (main: 0xE87830, dark: 0xC05820), // Orange (original)
                (main: 0xE85050, dark: 0xC03030), // Coral Red
                (main: 0xE8C040, dark: 0xC8A020), // Golden
                (main: 0xD06890, dark: 0xB04870), // Rose Pink
            ]
        case .codexCLI:
            return [
                (main: 0x40A850, dark: 0x308838), // Green (original)
                (main: 0x4088D0, dark: 0x3068B0), // Ocean Blue
                (main: 0x6868C8, dark: 0x4848A8), // Indigo
                (main: 0x40B0B0, dark: 0x309090), // Teal
            ]
        }
    }

    private static let skinTones: [(main: Int, mouth: Int)] = [
        (main: 0xF5D0A8, mouth: 0xE0B090), // Light
        (main: 0xD4A876, mouth: 0xC09060), // Medium
        (main: 0xB07840, mouth: 0x9A6830), // Warm Brown
        (main: 0x8B5E3C, mouth: 0x784E2C), // Deep Brown
    ]

    private static let eyeColors: [(main: Int, dark: Int)] = [
        (main: 0x40E8D0, dark: 0x30B098), // Cyan (original Claude)
        (main: 0x60B0FF, dark: 0x4090D0), // Bright blue
        (main: 0x80D060, dark: 0x60A840), // Green
        (main: 0xC090E0, dark: 0xA070C0), // Lavender
    ]

    private static let hairColors: [Int] = [
        0x302018, // Dark brown
        0x604020, // Brown
        0xA07030, // Light brown
        0xE0C060, // Blonde
        0xD04020, // Red
        0x202020, // Black
    ]

    // MARK: - Hash

    /// Simple DJB2 hash — fast, deterministic, good distribution for short strings.
    private static func djb2Hash(_ string: String) -> UInt64 {
        var hash: UInt64 = 5381
        for byte in string.utf8 {
            hash = ((hash << 5) &+ hash) &+ UInt64(byte)
        }
        return hash
    }
}

/// Hairstyle visible as pixels above the hood.
public enum HairStyle: String, Sendable, CaseIterable {
    case spiky
    case long
    case curly
    case bun
    case buzzcut
}

/// Optional accessory drawn on the character sprite.
public enum Accessory: String, Sendable, CaseIterable {
    case glasses
    case headphones
    case none
}
