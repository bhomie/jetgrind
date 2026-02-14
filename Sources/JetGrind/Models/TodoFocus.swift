import Foundation

enum TodoFocus: Hashable {
    case input
    case task(UUID)
    case completedPill
    case completedTask(UUID)
    case actionEdit(UUID)
    case actionDelete(UUID)
    case editing(UUID)
    case editingDescription(UUID)

    var actionTaskId: UUID? {
        switch self {
        case .actionEdit(let id), .actionDelete(let id):
            return id
        default:
            return nil
        }
    }

    var actionIndex: Int? {
        switch self {
        case .actionEdit: return 0
        case .actionDelete: return 1
        default: return nil
        }
    }

    static func action(index: Int, taskId: UUID) -> TodoFocus {
        switch index {
        case 0: return .actionEdit(taskId)
        case 1: return .actionDelete(taskId)
        default: return .actionEdit(taskId)
        }
    }
}
