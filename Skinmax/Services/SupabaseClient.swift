import Foundation
import Supabase

enum SupabaseManager {
    static let shared: SupabaseClient = {
        guard !Config.supabaseURL.isEmpty,
              !Config.supabaseAnonKey.isEmpty,
              let url = URL(string: Config.supabaseURL) else {
            fatalError("Supabase URL or anon key not configured. Check Secrets.plist.")
        }
        return SupabaseClient(supabaseURL: url, supabaseKey: Config.supabaseAnonKey)
    }()
}
