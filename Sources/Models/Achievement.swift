import Foundation

/// Achievements that can be earned through office activity.
public enum Achievement: String, CaseIterable, Sendable {
    case hundredTasks = "hundred_tasks"
    case firstAllNighter = "first_all_nighter"
    case fullHouse = "full_house"
    case firstErrorResolved = "first_error_resolved"
    case speedDemon = "speed_demon"

    public var displayName: String {
        switch self {
        case .hundredTasks: return "Century Club"
        case .firstAllNighter: return "Night Owl"
        case .fullHouse: return "Full House"
        case .firstErrorResolved: return "Bug Squasher"
        case .speedDemon: return "Speed Demon"
        }
    }

    public var trophyTextureName: String {
        switch self {
        case .hundredTasks: return "trophy_cup"
        case .firstAllNighter: return "trophy_moon"
        case .fullHouse: return "trophy_house"
        case .firstErrorResolved: return "trophy_star"
        case .speedDemon: return "trophy_lightning"
        }
    }

    public var description: String {
        switch self {
        case .hundredTasks: return "Complete 100 tasks"
        case .firstAllNighter: return "Work past midnight"
        case .fullHouse: return "Fill all 16 desks"
        case .firstErrorResolved: return "Recover from an error"
        case .speedDemon: return "Complete a task in under 30s"
        }
    }
}
