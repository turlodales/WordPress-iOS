import Foundation
import CoreData

struct XCDataModel: Decodable {
    let currentVersion: String
    let items: [String:[String:Data]]

    var versionNames: [String] {
        items.map { $0.key }
    }

    func versionPaths(relativeTo url: URL) -> [URL] {
        items.map {
            url.appendingPathComponent($0.key).appendingPathExtension("mom")
        }
    }

    private enum CodingKeys : String, CodingKey {
        case items = "NSManagedObjectModel_VersionHashes"
        case currentVersion = "NSManagedObjectModel_CurrentVersionName"
    }
    
    static func fromModelAt(_ url: URL) throws -> XCDataModel {
        let plistDecoder = PropertyListDecoder()
        let data = try Data(contentsOf: url.appendingPathComponent("VersionInfo.plist"))
        return try plistDecoder.decode(Self.self, from: data)
    }
}
