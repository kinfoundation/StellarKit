//
//  StellarBaseTests.swift
//  StellarKitTests
//
//  Created by Avi Shevin on 08/02/2018.
//  Copyright © 2018 Kin Foundation. All rights reserved.
//

import XCTest
@testable import StellarKit

struct MockStellarAccount: Account {
    var publicKey: String? {
        return KeyUtils.base32(publicKey: keyPair.publicKey)
    }

    let keyPair: Sign.KeyPair

    init(seedStr: String) {
        keyPair = KeyUtils.keyPair(from: seedStr)!
    }

    init() {
        keyPair = KeyUtils.keyPair(from: KeyUtils.seed()!)!
    }

    func sign(message: Data, passphrase: String) throws -> Data {
        return try KeyUtils.sign(message: message,
                                 signingKey: keyPair.secretKey)
    }
}

class StellarBaseTests: XCTestCase {
    let passphrase = "a phrase"
    var endpoint: String { return "override me" }

    lazy var stellar: Stellar =
        Stellar(baseURL: URL(string: endpoint)!,
                asset: Asset(assetCode: "KIN",
                             issuer: "GBSJ7KFU2NXACVHVN2VWQIXIV5FWH6A7OIDDTEUYTCJYGY3FJMYIDTU7"))

    var account: Account!
    var account2: Account!
    var issuer: Account!

    override func setUp() {
        super.setUp()

        account = MockStellarAccount()
        account2 = MockStellarAccount()
        issuer = MockStellarAccount(seedStr: "SAXSDD5YEU6GMTJ5IHA6K35VZHXFVPV6IHMWYAQPSEKJRNC5LGMUQX35")
    }

    override func tearDown() {
        super.tearDown()
    }

    func test_trust() {
        let e = expectation(description: "")

        self.stellar.fund(account: account.publicKey!)
            .then { _ -> Promise<String> in
                return self.stellar.trust(asset: self.stellar.asset,
                                          account: self.account,
                                          passphrase: self.passphrase)
            }
            .then { _ in
                e.fulfill()
            }
            .error { error in
                XCTAssertTrue(false, "Received unexpected error: \(error)!")
                e.fulfill()
        }

        wait(for: [e], timeout: 120.0)
    }

    func test_double_trust() {
        let e = expectation(description: "")

        stellar.fund(account: account.publicKey!)
            .then { _ -> Promise<String> in
                return self.stellar.trust(asset: self.stellar.asset,
                                          account: self.account,
                                          passphrase: self.passphrase)
            }
            .then { txHash -> Promise<String> in
                return self.stellar.trust(asset: self.stellar.asset,
                                          account: self.account,
                                          passphrase: self.passphrase)
            }
            .then { _ in
                e.fulfill()
            }
            .error { error in
                XCTAssertTrue(false, "Failed to trust asset: \(error)")
                e.fulfill()
        }

        wait(for: [e], timeout: 120.0)
    }

    func test_payment_to_untrusting_account() {
        let e = expectation(description: "")

        stellar.payment(source: account,
                        destination: account2.publicKey!,
                        amount: 1,
                        passphrase: self.passphrase)
            .then { txHash -> Void in
                XCTAssertTrue(false, "Expected error!")
                e.fulfill()
            }
            .error { error in
                guard let stellarError = error as? StellarError else {
                    XCTAssertTrue(false, "Received unexpected error: \(error)!")

                    return
                }

                switch stellarError {
                case .missingAccount: break
                case .missingBalance: break
                default:
                    XCTAssertTrue(false, "Received unexpected error: \(error)!")
                }

                e.fulfill()
        }

        wait(for: [e], timeout: 120.0)
    }

    func test_payment_from_unfunded_account() {
        let e = expectation(description: "")

        stellar.fund(account: account2.publicKey!)
            .then { _ -> Promise<String> in
                return self.stellar.trust(asset: self.stellar.asset,
                                          account: self.account2,
                                          passphrase: self.passphrase)
            }
            .then { txHash -> Promise<String> in
                return self.stellar.payment(source: self.account,
                                            destination: self.account2.publicKey!,
                                            amount: 1,
                                            passphrase: self.passphrase)
            }
            .then { txHash -> Void in
                XCTAssertTrue(false, "Expected error!")
                e.fulfill()
            }
            .error { error in
                guard let stellarError = error as? StellarError else {
                    XCTAssertTrue(false, "Received unexpected error: \(error)!")

                    return
                }

                switch stellarError {
                case .missingSequence: break
                default:
                    XCTAssertTrue(false, "Received unexpected error: \(error)!")
                }

                e.fulfill()
        }

        wait(for: [e], timeout: 120.0)
    }

    func test_payment_from_empty_account() {
        let e = expectation(description: "")

        let stellar = self.stellar

        stellar.fund(account: account.publicKey!)
            .then { _ -> Promise<String> in
                return stellar.fund(account: self.account2.publicKey!)
            }
            .then { _ -> Promise<String> in
                return self.stellar.trust(asset: self.stellar.asset,
                                          account: self.account,
                                          passphrase: self.passphrase)
            }
            .then { txHash -> Promise<String> in
                return stellar.trust(asset: stellar.asset,
                                     account: self.account2,
                                     passphrase: self.passphrase)
            }
            .then { txHash -> Promise<String> in
                return stellar.payment(source: self.account,
                                       destination: self.account2.publicKey!,
                                       amount: 1,
                                       passphrase: self.passphrase)
            }
            .then { txHash -> Void in
                XCTAssertTrue(false, "Expected error!")
                e.fulfill()
            }
            .error { error in
                guard let paymentError = error as? PaymentError else {
                    XCTAssertTrue(false, "Received unexpected error: \(error)!")

                    return
                }

                switch paymentError {
                case .PAYMENT_UNDERFUNDED: break
                default:
                    XCTAssertTrue(false, "Received unexpected error: \(error)!")
                }

                e.fulfill()
        }

        wait(for: [e], timeout: 120.0)
    }

    func test_payment_to_trusting_account() {
        let e = expectation(description: "")

        stellar.fund(account: account.publicKey!)
            .then { _ -> Promise<String> in
                return self.stellar.trust(asset: self.stellar.asset,
                                          account: self.account,
                                          passphrase: self.passphrase)
            }
            .then { txHash -> Promise<String> in
                return self.stellar.payment(source: self.issuer,
                                            destination: self.account.publicKey!,
                                            amount: 1,
                                            passphrase: self.passphrase)
            }
            .then { _ in
                e.fulfill()
            }
            .error { error in
                XCTAssertTrue(false, "Received unexpected error: \(error)!")
                e.fulfill()
        }

        wait(for: [e], timeout: 120.0)
    }

    func test_balance() {
        let e = expectation(description: "")

        stellar.fund(account: account.publicKey!)
            .then { txHash -> Promise<String> in
                return self.stellar.trust(asset: self.stellar.asset,
                                          account: self.account,
                                          passphrase: self.passphrase)
            }
            .then { txHash -> Promise<Decimal> in
                return self.stellar.balance(account: self.account.publicKey!)
            }
            .then { _ in
                e.fulfill()
            }
            .error { error in
                XCTAssertTrue(false, "Received unexpected error: \(error)!")
                e.fulfill()
        }

        wait(for: [e], timeout: 120.0)
    }

}