import Foundation
import SGKCore

public struct SaveMetadata: Codable, Sendable {
    public var slot: Int
    public var name: String
    public var timestamp: Date
    public var version: Int
    public var playTime: Double

    public init(slot: Int, name: String, version: Int = 1, playTime: Double = 0) {
        self.slot = slot
        self.name = name
        self.timestamp = Date()
        self.version = version
        self.playTime = playTime
    }
}

public enum SaveManager {
    public static var baseDirectory: URL = {
        let urls = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let dir = (urls.first ?? URL(fileURLWithPath: NSTemporaryDirectory())).appendingPathComponent("SwiftGameKitSaves", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }()

    public static func save<T: Codable>(_ data: T, slot: Int, name: String = "Save", version: Int = 1, playTime: Double = 0) throws {
        let meta = SaveMetadata(slot: slot, name: name, version: version, playTime: playTime)
        let wrapper = SaveWrapper(metadata: meta, payload: data)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        let encoded = try encoder.encode(wrapper)
        let url = fileURL(for: slot)
        try encoded.write(to: url, options: .atomic)
        Log.info("Saved slot \(slot) to \(url.path)")
    }

    public static func load<T: Codable>(_ type: T.Type, slot: Int) throws -> (metadata: SaveMetadata, data: T) {
        let url = fileURL(for: slot)
        guard FileManager.default.fileExists(atPath: url.path) else {
            throw SGKError.notFound("Save slot \(slot)")
        }
        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let wrapper = try decoder.decode(SaveWrapper<T>.self, from: data)
        return (wrapper.metadata, wrapper.payload)
    }

    public static func exists(slot: Int) -> Bool {
        FileManager.default.fileExists(atPath: fileURL(for: slot).path)
    }

    public static func delete(slot: Int) throws {
        let url = fileURL(for: slot)
        if FileManager.default.fileExists(atPath: url.path) {
            try FileManager.default.removeItem(at: url)
        }
    }

    public static func listSlots() -> [SaveMetadata] {
        guard let files = try? FileManager.default.contentsOfDirectory(at: baseDirectory, includingPropertiesForKeys: nil) else {
            return []
        }
        var result: [SaveMetadata] = []
        for file in files where file.pathExtension == "json" {
            if let data = try? Data(contentsOf: file),
               let partial = try? JSONDecoder().decode(SaveMetadataOnly.self, from: data) {
                result.append(partial.metadata)
            }
        }
        return result.sorted { $0.slot < $1.slot }
    }

    private static func fileURL(for slot: Int) -> URL {
        baseDirectory.appendingPathComponent("save_\(slot).json")
    }

    private struct SaveWrapper<T: Codable>: Codable {
        var metadata: SaveMetadata
        var payload: T
    }

    private struct SaveMetadataOnly: Codable {
        var metadata: SaveMetadata
    }
}

// MARK: - V2 Migration Support

public protocol SaveMigrator {
    var fromVersion: Int { get }
    var toVersion: Int { get }
    func migrate(data: Data) throws -> Data
}

public enum SaveMigration {
    private static var migrators: [SaveMigrator] = []

    public static func register(_ migrator: SaveMigrator) {
        migrators.append(migrator)
        migrators.sort { $0.fromVersion < $1.fromVersion }
    }

    public static func migrateIfNeeded(data: Data, currentVersion: Int, targetVersion: Int) throws -> Data {
        var data = data
        var version = currentVersion
        while version < targetVersion {
            guard let migrator = migrators.first(where: { $0.fromVersion == version }) else {
                throw SGKError.serialization("No migrator from version \(version) to \(targetVersion)")
            }
            data = try migrator.migrate(data: data)
            version = migrator.toVersion
            Log.info("Migrated save \(migrator.fromVersion) -> \(migrator.toVersion)")
        }
        return data
    }
}

public struct AutosaveConfig: Sendable {
    public var enabled: Bool = true
    public var intervalSeconds: Double = 120
    public var slot: Int = 0
    public init() {}
}
