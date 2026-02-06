import Foundation

enum TodoFocus: Hashable {
    case input
    case task(UUID)
    case completedPill
    case completedTask(UUID)
}
