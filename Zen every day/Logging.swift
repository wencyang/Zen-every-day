#if DEBUG
import Foundation
@inline(__always) func debugLog(_ message: String) {
    print(message)
}
#else
@inline(__always) func debugLog(_ message: String) {}
#endif
