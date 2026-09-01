import Foundation

enum DistanceFormatter {
    static func string(fromMiles miles: Double) -> String {
        if miles < 0.1 {
            return "< 0.1 mi away"
        }
        return String(format: "%.1f mi away", miles)
    }
}
