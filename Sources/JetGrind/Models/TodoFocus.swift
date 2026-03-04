import Foundation

enum TodoFocus: Hashable {
    case input
    case task(UUID)
    case completedTask(UUID)
    case actionEdit(UUID)
    case actionComplete(UUID)
    case actionDelete(UUID)
    case editing(UUID)
    case editingDescription(UUID)

    var actionTaskId: UUID? {
        switch self {
        case .actionEdit(let id), .actionComplete(let id), .actionDelete(let id):
            return id
        default:
            return nil
        }
    }

    var actionIndex: Int? {
        switch self {
        case .actionEdit: return 0
        case .actionComplete: return 1
        case .actionDelete: return 2
        default: return nil
        }
    }

    static func action(index: Int, taskId: UUID) -> TodoFocus {
        switch index {
        case 0: return .actionEdit(taskId)
        case 1: return .actionComplete(taskId)
        case 2: return .actionDelete(taskId)
        default: return .actionEdit(taskId)
        }
    }
}
