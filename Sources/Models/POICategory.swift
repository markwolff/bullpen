import Foundation

// MARK: - POICategory

/// Categorizes points of interest by the kind of break they offer.
///
/// The idle behavior manager uses categories for variety — it avoids
/// repeating the same category back-to-back. Each world fills these
/// categories with its own themed locations.
public enum POICategory: String, Sendable, CaseIterable, Codable {
    case refreshment   // Water cooler, tea station, coffee bar
    case relaxation    // Couch, hammock, meditation cushion, window gazing
    case creative      // Whiteboard, calligraphy desk, drawing board
    case knowledge     // Bookshelf, bulletin board, scroll library
    case nature        // Plants, koi pond, mushroom grove, wildflowers
    case social        // Ping pong area, chat zone, standup huddle
    case utility       // Printer, supply closet, server rack
    case pet           // Cat, dog — dynamic POIs that move
}
