import Foundation

extension Date {
    var relativeFormat: String {
        let calendar = Calendar.current
        let now = Date()

        if calendar.isDateInToday(self) {
            return "today"
        }

        if calendar.isDateInYesterday(self) {
            return "yesterday"
        }

        let components = calendar.dateComponents([.day], from: self, to: now)
        if let days = components.day, days > 0 {
            return "\(days)d ago"
        }

        return "today"
    }
}
