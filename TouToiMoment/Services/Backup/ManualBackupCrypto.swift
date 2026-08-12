import CommonCrypto
import CryptoKit
import Foundation
import Security

enum ManualBackupCrypto {
    static let algorithmIdentifier = "AES-GCM"
    static let keyDerivationIdentifier = "PBKDF2-HMAC-SHA256"
    static let defaultPBKDF2Iterations = 600_000
    static let maximumPBKDF2Iterations = 2_000_000
    static let saltByteCount = 16
    private static let keyByteCount = 32
    private static let associatedDataPrefix = Data("TouToiMomentManualBackupV1".utf8)

    static func makeSalt() throws -> Data {
        var data = Data(repeating: 0, count: saltByteCount)
        let status = data.withUnsafeMutableBytes { buffer in
            guard let address = buffer.baseAddress else { return errSecParam }
            return SecRandomCopyBytes(kSecRandomDefault, saltByteCount, address)
        }
        guard status == errSecSuccess else { throw ManualBackupError.fileWriteFailed }
        return data
    }

    static func deriveKey(passphrase: String, salt: Data, iterations: Int) throws -> SymmetricKey {
        guard salt.count == saltByteCount,
              iterations > 0,
              iterations <= maximumPBKDF2Iterations,
              let iterationCount = UInt32(exactly: iterations)
        else {
            throw ManualBackupError.invalidFormat
        }

        let password = Data(passphrase.utf8)
        var derived = Data(repeating: 0, count: keyByteCount)
        let status = derived.withUnsafeMutableBytes { derivedBytes in
            salt.withUnsafeBytes { saltBytes in
                password.withUnsafeBytes { passwordBytes in
                    CCKeyDerivationPBKDF(
                        CCPBKDFAlgorithm(kCCPBKDF2),
                        passwordBytes.bindMemory(to: Int8.self).baseAddress,
                        password.count,
                        saltBytes.bindMemory(to: UInt8.self).baseAddress,
                        salt.count,
                        CCPseudoRandomAlgorithm(kCCPRFHmacAlgSHA256),
                        iterationCount,
                        derivedBytes.bindMemory(to: UInt8.self).baseAddress,
                        keyByteCount
                    )
                }
            }
        }
        guard status == kCCSuccess else { throw ManualBackupError.invalidFormat }
        return SymmetricKey(data: derived)
    }

    static func seal(_ plaintext: Data, key: SymmetricKey, associatedData: Data) throws -> Data {
        do {
            let sealed = try AES.GCM.seal(plaintext, using: key, authenticating: associatedData)
            guard let combined = sealed.combined else { throw ManualBackupError.fileWriteFailed }
            return combined
        } catch let error as ManualBackupError {
            throw error
        } catch {
            throw ManualBackupError.fileWriteFailed
        }
    }

    static func open(
        _ ciphertext: Data,
        key: SymmetricKey,
        associatedData: Data,
        wrongPassphraseError: Bool
    ) throws -> Data {
        do {
            let sealedBox = try AES.GCM.SealedBox(combined: ciphertext)
            return try AES.GCM.open(sealedBox, using: key, authenticating: associatedData)
        } catch {
            throw wrongPassphraseError
                ? ManualBackupError.wrongPassphrase
                : ManualBackupError.authenticationFailed
        }
    }

    static func associatedData(header: ManualBackupHeader, entryIdentifier: String) throws -> Data {
        guard header.formatIdentifier == ManualBackupImportPolicy.formatIdentifier,
              header.schemaVersion == ManualBackupImportPolicy.currentSchemaVersion,
              header.algorithm == algorithmIdentifier,
              header.keyDerivation == keyDerivationIdentifier,
              header.salt.count == saltByteCount,
              header.iterations == defaultPBKDF2Iterations
        else {
            throw ManualBackupError.invalidFormat
        }

        var data = associatedDataPrefix
        data.appendLengthPrefixed(header.formatIdentifier)
        data.appendFixedWidthInteger(Int64(header.schemaVersion))
        data.appendFixedWidthInteger(header.createdAt.timeIntervalSince1970.bitPattern)
        data.appendOptionalString(header.appVersion)
        data.appendLengthPrefixed(header.algorithm)
        data.appendLengthPrefixed(header.keyDerivation)
        data.appendFixedWidthInteger(Int64(header.iterations))
        data.appendLengthPrefixed(header.salt)
        data.appendLengthPrefixed(entryIdentifier)
        return data
    }

    static func assetIdentifier(momentID: String, imageID: String) -> String {
        let digest = SHA256.hash(data: Data("\(momentID)\u{0}\(imageID)".utf8))
        return digest.map { String(format: "%02x", $0) }.joined()
    }
}

private extension Data {
    mutating func appendFixedWidthInteger<T: FixedWidthInteger>(_ value: T) {
        var bigEndianValue = value.bigEndian
        Swift.withUnsafeBytes(of: &bigEndianValue) { bytes in
            append(bytes.bindMemory(to: UInt8.self))
        }
    }

    mutating func appendLengthPrefixed(_ value: String) {
        appendLengthPrefixed(Data(value.utf8))
    }

    mutating func appendLengthPrefixed(_ value: Data) {
        appendFixedWidthInteger(UInt64(value.count))
        append(value)
    }

    mutating func appendOptionalString(_ value: String?) {
        guard let value else {
            append(0)
            return
        }
        append(1)
        appendLengthPrefixed(value)
    }
}
