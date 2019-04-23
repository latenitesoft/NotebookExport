import Foundation
import Path

struct DependencyDescription : Hashable {
    let name: String
    let rawSpec: String
    
    var description: String { return rawSpec }
}

