import os

enum SkinmaxLog {
    static let config    = Logger(subsystem: "com.skinmax.app", category: "config")
    static let analysis  = Logger(subsystem: "com.skinmax.app", category: "analysis")
    static let dataStore = Logger(subsystem: "com.skinmax.app", category: "dataStore")
    static let skinAPI   = Logger(subsystem: "com.skinmax.app", category: "skinAPI")
    static let foodAPI   = Logger(subsystem: "com.skinmax.app", category: "foodAPI")
}
