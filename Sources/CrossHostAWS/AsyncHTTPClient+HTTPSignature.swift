import Foundation

import HTTPSignature
import AsyncHTTPClient

enum HTTPSignatureError: Error {
	case missingNeededFields
}

extension HTTPClientRequest {
	mutating func sign(scheme: String, host: String, path: String, keyId: String, provider: Algorithm.Provider) async throws {
		guard let body else {
			throw HTTPSignatureError.missingNeededFields
		}

		let dateFormatter = DateFormatter.httpDateFormatter

		let dateValue = dateFormatter.string(from: Date.now)
		let digestInput = try await body.collect(upTo: 1024 * 1024)
		let data = Data(buffer: digestInput)

		let signature = HTTPSignatureParameters(
			path: path,
			method: method.rawValue,
			keyId: keyId,
			algorithm: .RS256,
			headers: [
				("host", host),
				("date", dateValue)
			],
			body: data
		)

		let payload = try signature.sign(with: provider)

		headers.replaceOrAdd(name: "Date", value: dateValue)
		headers.replaceOrAdd(name: "Host", value: host)
		headers.replaceOrAdd(name: "Signature", value: payload.signatureHeaderValue)
		headers.replaceOrAdd(name: "Digest", value: payload.digestHeaderValue)
	}
}
