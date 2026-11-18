import SwiftUI

extension Color {
    // Create a color from a hex code (e.g. "FF9230")
    init(hex: String) {
        let value = UInt64(hex, radix: 16) ?? 0
        self.init(
            red: Double((value >> 16) & 0xFF) / 255,
            green: Double((value >> 8) & 0xFF) / 255,
            blue: Double(value & 0xFF) / 255
        )
    }

    // Orange
    static let learnOrange = Color(hex: "FF9230")      // Today circle, main buttons, flame icon
    static let learnOrangeLight = Color(hex: "FFC45E") // Learned day number (dark mode)

    // Blue
    static let freezeBlue = Color(hex: "3CD3FE")       // Freeze button, frozen day background
    static let freezeBlueLight = Color(hex: "6FEBFF")  // Frozen day number, snowflake icon
}
