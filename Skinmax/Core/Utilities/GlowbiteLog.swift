import os

enum GlowbiteLog {
    static let config    = Logger(subsystem: "com.glowbite.app", category: "config")
    static let analysis  = Logger(subsystem: "com.glowbite.app", category: "analysis")
    static let dataStore = Logger(subsystem: "com.glowbite.app", category: "dataStore")
    static let skinAPI   = Logger(subsystem: "com.glowbite.app", category: "skinAPI")
    static let foodAPI   = Logger(subsystem: "com.glowbite.app", category: "foodAPI")
}
