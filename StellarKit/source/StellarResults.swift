//
//  StellarResults.swift
//  StellarKit
//
//  Created by Kin Foundation
//  Copyright © 2018 Kin Foundation. All rights reserved.
//

import Foundation

struct TransactionResultCode {
    static let txSUCCESS: Int32 = 0               // all operations succeeded

    static let txFAILED: Int32 = -1               // one of the operations failed (none were applied)

    static let txTOO_EARLY: Int32 = -2            // ledger closeTime before minTime
    static let txTOO_LATE: Int32 = -3             // ledger closeTime after maxTime
    static let txMISSING_OPERATION: Int32 = -4    // no operation was specified
    static let txBAD_SEQ: Int32 = -5              // sequence number does not match source account

    static let txBAD_AUTH: Int32 = -6             // too few valid signatures / wrong network
    static let txINSUFFICIENT_BALANCE: Int32 = -7 // fee would bring account below reserve
    static let txNO_ACCOUNT: Int32 = -8           // source account not found
    static let txINSUFFICIENT_FEE: Int32 = -9     // fee is too small
    static let txBAD_AUTH_EXTRA: Int32 = -10      // unused signatures attached to transaction
    static let txINTERNAL_ERROR: Int32 = -11      // an unknown error occured
}

public struct TransactionResult: XDRCodable, XDREncodableStruct, Encodable {
    let feeCharged: Int64
    let result: Result
    let reserved: Int32 = 0

    enum Result: XDRCodable, Encodable {
        case txSUCCESS ([OperationResult])
        case txFAILED ([OperationResult])
        case txERROR (Int32)

        private enum CodingKeys: String, CodingKey {
            case txSUCCESS = "success"
            case txFAILED = "failed"
            case txERROR = "error"
        }

        init(from decoder: XDRDecoder) throws {
            let discriminant = try decoder.decode(Int32.self)

            switch discriminant {
            case TransactionResultCode.txSUCCESS:
                self = .txSUCCESS(try decoder.decodeArray(OperationResult.self))
            case TransactionResultCode.txFAILED:
                self = .txFAILED(try decoder.decodeArray(OperationResult.self))
            default:
                self = .txERROR(discriminant)
            }
        }

        private func discriminant() -> Int32 {
            switch self {
            case .txSUCCESS: return TransactionResultCode.txSUCCESS
            case .txFAILED: return TransactionResultCode.txFAILED
            case .txERROR (let code): return code
            }
        }

        public func encode(to encoder: XDREncoder) throws {
            try encoder.encode(discriminant())

            switch self {
            case .txSUCCESS (let ops):
                try encoder.encode(ops)
            case .txFAILED (let ops):
                try encoder.encode(ops)
            case .txERROR (let code):
                try encoder.encode(code)
            }
        }

        public func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)

            switch self {
            case .txSUCCESS(let results):
                try container.encode(results, forKey: .txSUCCESS)
            case .txFAILED(let results):
                try container.encode(results, forKey: .txFAILED)
            case .txERROR(let error):
                try container.encode(error, forKey: .txERROR)
            }
        }
    }

    public init(from decoder: XDRDecoder) throws {
        feeCharged = try decoder.decode(Int64.self)
        result = try decoder.decode(Result.self)
        _ = try decoder.decode(Int32.self)
    }

    init(feeCharged: Int64, result: Result) {
        self.feeCharged = feeCharged
        self.result = result
    }
}

struct OperationResultCode {
    static let opINNER: Int32 = 0       // inner object result is valid

    static let opBAD_AUTH: Int32 = -1   // too few valid signatures / wrong network
    static let opNO_ACCOUNT: Int32 = -2 // source account was not found
}

public enum OperationResult: XDRCodable, Encodable {
    case opINNER (Tr)
    case opBAD_AUTH
    case opNO_ACCOUNT

    // Add cases as necessary.
    public enum Tr: XDRCodable, Encodable {
        case CREATE_ACCOUNT (CreateAccountResult)
        case PAYMENT (PaymentResult)
        case PATH_PAYMENT (PathPaymentResult)
        case MANAGE_OFFER (ManageOfferResult)
        case CREATE_PASSIVE_OFFER (ManageOfferResult)
        case SET_OPTIONS (SetOptionsResult)
        case CHANGE_TRUST (ChangeTrustResult)
        case ALLOW_TRUST (AllowTrustResult)
        case ACCOUNT_MERGE (AccountMergeResult)
        case INFLATION (InflationResult)
        case MANAGE_DATA (ManageDataResult)
        case BUMP_SEQUENCE (BumpSequenceResult)
        case unknown

        public init(from decoder: XDRDecoder) throws {
            let discriminant = try decoder.decode(Int32.self)

            switch discriminant {
            case OperationType.CREATE_ACCOUNT:
                self = .CREATE_ACCOUNT(try decoder.decode(CreateAccountResult.self))
            case OperationType.PAYMENT:
                self = .PAYMENT(try decoder.decode(PaymentResult.self))
            case OperationType.PATH_PAYMENT:
                self = .PATH_PAYMENT(try decoder.decode(PathPaymentResult.self))
            case OperationType.MANAGE_OFFER:
                self = .MANAGE_OFFER(try decoder.decode(ManageOfferResult.self))
            case OperationType.CREATE_PASSIVE_OFFER:
                self = .CREATE_PASSIVE_OFFER(try decoder.decode(ManageOfferResult.self))
            case OperationType.SET_OPTIONS:
                self = .SET_OPTIONS(try decoder.decode(SetOptionsResult.self))
            case OperationType.CHANGE_TRUST:
                self = .CHANGE_TRUST(try decoder.decode(ChangeTrustResult.self))
            case OperationType.ALLOW_TRUST:
                self = .ALLOW_TRUST(try decoder.decode(AllowTrustResult.self))
            case OperationType.ACCOUNT_MERGE:
                self = .ACCOUNT_MERGE(try decoder.decode(AccountMergeResult.self))
            case OperationType.INFLATION:
                self = .INFLATION(try decoder.decode(InflationResult.self))
            case OperationType.MANAGE_DATA:
                self = .MANAGE_DATA(try decoder.decode(ManageDataResult.self))
            case OperationType.BUMP_SEQUENCE:
                self = .BUMP_SEQUENCE(try decoder.decode(BumpSequenceResult.self))
            default:
                self = .unknown
            }
        }

        private func discriminant() -> Int32 {
            switch self {
            case .CREATE_ACCOUNT: return OperationType.CREATE_ACCOUNT
            case .PAYMENT: return OperationType.PAYMENT
            default: return -1
            }
        }

        public func encode(to encoder: XDREncoder) throws {
            try encoder.encode(discriminant())

            switch self {
            case .CREATE_ACCOUNT (let result):
                try encoder.encode(result)
            case .PAYMENT (let result):
                try encoder.encode(result)
            default:
                break
            }
        }

        public func encode(to encoder: Encoder) throws {
            var container = encoder.singleValueContainer()

            switch self {
            case .ACCOUNT_MERGE(let result):
                try container.encode(result)
            case .ALLOW_TRUST(let result):
                try container.encode(result)
            case .BUMP_SEQUENCE(let result):
                try container.encode(result)
            case .CHANGE_TRUST(let result):
                try container.encode(result)
            case .CREATE_ACCOUNT(let result):
                try container.encode(result)
            case .CREATE_PASSIVE_OFFER(let result):
                try container.encode(result)
            case .INFLATION(let result):
                try container.encode(result)
            case .MANAGE_DATA(let result):
                try container.encode(result)
            case .MANAGE_OFFER(let result):
                try container.encode(result)
            case .PATH_PAYMENT(let result):
                try container.encode(result)
            case .PAYMENT(let result):
                try container.encode(result)
            case .SET_OPTIONS(let result):
                try container.encode(result)
            case .unknown:
                break
            }
        }
    }

    public init(from decoder: XDRDecoder) throws {
        let discriminant = try decoder.decode(Int32.self)

        switch discriminant {
        case OperationResultCode.opINNER:
            self = .opINNER(try decoder.decode(Tr.self))
        case OperationResultCode.opBAD_AUTH:
            self = .opBAD_AUTH
        case OperationResultCode.opNO_ACCOUNT:
            fallthrough
        default:
            self = .opNO_ACCOUNT
        }
    }

    private func discriminant() -> Int32 {
        switch self {
        case .opINNER: return OperationResultCode.opINNER
        case .opBAD_AUTH: return OperationResultCode.opBAD_AUTH
        case .opNO_ACCOUNT: return OperationResultCode.opNO_ACCOUNT
        }
    }

    public func encode(to encoder: XDREncoder) throws {
        try encoder.encode(discriminant())

        switch self {
        case .opINNER (let tr):
            try encoder.encode(tr)
        case .opBAD_AUTH:
            break
        case .opNO_ACCOUNT:
            break
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()

        switch self {
        case .opINNER(let tr):
            try container.encode(tr)
        case .opBAD_AUTH:
            try container.encode(discriminant())
        case .opNO_ACCOUNT:
            try container.encode(discriminant())
        }
    }
}

struct CreateAccountResultCode {
    static let CREATE_ACCOUNT_SUCCESS: Int32 = 0        // account was created

    static let CREATE_ACCOUNT_MALFORMED: Int32 = -1     // invalid destination
    static let CREATE_ACCOUNT_UNDERFUNDED: Int32 = -2   // not enough funds in source account
    static let CREATE_ACCOUNT_LOW_RESERVE: Int32 = -3   // would create an account below the min reserve
    static let CREATE_ACCOUNT_ALREADY_EXIST: Int32 = -4 // account already exists
}

public enum CreateAccountResult: XDRCodable, Encodable {
    case success
    case failure (Int32)

    private enum CodingKeys: String, CodingKey {
        case name
        case result
    }

    private func discriminant() -> Int32 {
        switch self {
        case .success:
            return CreateAccountResultCode.CREATE_ACCOUNT_SUCCESS
        case .failure (let code):
            return code
        }
    }

    public func encode(to encoder: XDREncoder) throws {
        try encoder.encode(discriminant())
    }

    public init(from decoder: XDRDecoder) throws {
        let value = try decoder.decode(Int32.self)

        self = value == 0 ? .success : .failure(value)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode("create_account", forKey: .name)

        switch self {
        case .success:
            try container.encode(0, forKey: .result)
        case .failure(let code):
            try container.encode(code, forKey: .result)
        }
    }
}

struct ChangeTrustResultCode {
    static let CHANGE_TRUST_SUCCESS: Int32 = 0

    static let CHANGE_TRUST_MALFORMED: Int32 = -1           // bad input
    static let CHANGE_TRUST_NO_ISSUER: Int32 = -2           // could not find issuer
    static let CHANGE_TRUST_INVALID_LIMIT: Int32 = -3       // cannot drop limit below balance
    static let CHANGE_TRUST_LOW_RESERVE: Int32 = -4         // not enough funds to create a new trust line,
    static let CHANGE_TRUST_SELF_NOT_ALLOWED: Int32 = -5    // trusting self is not allowed
};

public enum ChangeTrustResult: XDRCodable, Encodable {
    case success
    case failure (Int32)

    private enum CodingKeys: String, CodingKey {
        case name
        case result
    }

    private func discriminant() -> Int32 {
        switch self {
        case .success:
            return ChangeTrustResultCode.CHANGE_TRUST_SUCCESS
        case .failure (let code):
            return code
        }
    }

    public func encode(to encoder: XDREncoder) throws {
        try encoder.encode(discriminant())
    }

    public init(from decoder: XDRDecoder) throws {
        let value = try decoder.decode(Int32.self)

        self = value == 0 ? .success : .failure(value)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode("change_trust", forKey: .name)

        switch self {
        case .success:
            try container.encode(0, forKey: .result)
        case .failure(let code):
            try container.encode(code, forKey: .result)
        }
    }
}

struct PaymentResultCode {
    // codes considered as "success" for the operation
    static let PAYMENT_SUCCESS: Int32 = 0 // payment successfuly completed

    // codes considered as "failure" for the operation
    static let PAYMENT_MALFORMED: Int32 = -1          // bad input
    static let PAYMENT_UNDERFUNDED: Int32 = -2        // not enough funds in source account
    static let PAYMENT_SRC_NO_TRUST: Int32 = -3       // no trust line on source account
    static let PAYMENT_SRC_NOT_AUTHORIZED: Int32 = -4 // source not authorized to transfer
    static let PAYMENT_NO_DESTINATION: Int32 = -5     // destination account does not exist
    static let PAYMENT_NO_TRUST: Int32 = -6           // destination missing a trust line for asset
    static let PAYMENT_NOT_AUTHORIZED: Int32 = -7     // destination not authorized to hold asset
    static let PAYMENT_LINE_FULL: Int32 = -8          // destination would go above their limit
    static let PAYMENT_NO_ISSUER: Int32 = -9          // missing issuer on asset
}

public enum PaymentResult: XDRCodable, Encodable {
    case success
    case failure (Int32)

    private enum CodingKeys: String, CodingKey {
        case name
        case result
    }

    private func discriminant() -> Int32 {
        switch self {
        case .success:
            return PaymentResultCode.PAYMENT_SUCCESS
        case .failure (let code):
            return code
        }
    }

    public func encode(to encoder: XDREncoder) throws {
        try encoder.encode(discriminant())
    }

    public init(from decoder: XDRDecoder) throws {
        let value = try decoder.decode(Int32.self)

        self = value == 0 ? .success : .failure(value)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode("payment", forKey: .name)

        switch self {
        case .success:
            try container.encode(0, forKey: .result)
        case .failure(let code):
            try container.encode(code, forKey: .result)
        }
    }
}

struct PathPaymentResultCode {
    // codes considered as "success" for the operation
    static let PATH_PAYMENT_SUCCESS: Int32 = 0 // success

    // codes considered as "failure" for the operation
    static let PATH_PAYMENT_MALFORMED: Int32 = -1          // bad input
    static let PATH_PAYMENT_UNDERFUNDED: Int32 = -2        // not enough funds in source account
    static let PATH_PAYMENT_SRC_NO_TRUST: Int32 = -3       // no trust line on source account
    static let PATH_PAYMENT_SRC_NOT_AUTHORIZED: Int32 = -4 // source not authorized to transfer
    static let PATH_PAYMENT_NO_DESTINATION: Int32 = -5     // destination account does not exist
    static let PATH_PAYMENT_NO_TRUST: Int32 = -6           // dest missing a trust line for asset
    static let PATH_PAYMENT_NOT_AUTHORIZED: Int32 = -7     // dest not authorized to hold asset
    static let PATH_PAYMENT_LINE_FULL: Int32 = -8          // dest would go above their limit
    static let PATH_PAYMENT_NO_ISSUER: Int32 = -9          // missing issuer on one asset
    static let PATH_PAYMENT_TOO_FEW_OFFERS: Int32 = -10    // not enough offers to satisfy path
    static let PATH_PAYMENT_OFFER_CROSS_SELF: Int32 = -11  // would cross one of its own offers
    static let PATH_PAYMENT_OVER_SENDMAX: Int32 = -12      // could not satisfy sendmax
}

public enum PathPaymentResult: XDRDecodable, Encodable {
    case PATH_PAYMENT_SUCCESS (Inner)
    case PATH_PAYMENT_NO_ISSUER (Asset)
    case failure (Int32)

    private enum CodingKeys: String, CodingKey {
        case name
        case success
        case no_issuer
        case failure
    }

    public struct Inner: XDRDecodable, Encodable {
        let offers: [ClaimOfferAtom]
        let last: SimplePaymentResult

        struct SimplePaymentResult: XDRDecodable, Encodable {
            let destination: AccountID
            let asset: Asset
            let amount: Int64

            init(from decoder: XDRDecoder) throws {
                destination = try decoder.decode(AccountID.self)
                asset = try decoder.decode(Asset.self)
                amount = try decoder.decode(Int64.self)
            }
        }

        public init(from decoder: XDRDecoder) throws {
            offers = try decoder.decodeArray(ClaimOfferAtom.self)
            last = try decoder.decode(SimplePaymentResult.self)
        }
    }

    public init(from decoder: XDRDecoder) throws {
        let discriminant = try decoder.decode(Int32.self)

        switch discriminant {
        case PathPaymentResultCode.PATH_PAYMENT_SUCCESS:
            self = .PATH_PAYMENT_SUCCESS(try decoder.decode(Inner.self))
        case PathPaymentResultCode.PATH_PAYMENT_NO_ISSUER:
            self = .PATH_PAYMENT_NO_ISSUER(try decoder.decode(Asset.self))
        default:
            self = .failure(discriminant)
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode("path_payment", forKey: .name)
        
        switch self {
        case .PATH_PAYMENT_SUCCESS(let inner):
            try container.encode(inner, forKey: .success)
        case .PATH_PAYMENT_NO_ISSUER(let asset):
            try container.encode(asset, forKey: .no_issuer)
        case .failure(let code):
            try container.encode(code, forKey: .failure)
        }
    }
}

struct ManageOfferResultCode {
    // codes considered as "success" for the operation
    static let MANAGE_OFFER_SUCCESS: Int32 = 0

    // codes considered as "failure" for the operation
    static let MANAGE_OFFER_MALFORMED: Int32 = -1     // generated offer would be invalid
    static let MANAGE_OFFER_SELL_NO_TRUST: Int32 = -2 // no trust line for what we're selling
    static let MANAGE_OFFER_BUY_NO_TRUST: Int32 = -3  // no trust line for what we're buying
    static let MANAGE_OFFER_SELL_NOT_AUTHORIZED: Int32 = -4 // not authorized to sell
    static let MANAGE_OFFER_BUY_NOT_AUTHORIZED: Int32 = -5  // not authorized to buy
    static let MANAGE_OFFER_LINE_FULL: Int32 = -6      // can't receive more of what it's buying
    static let MANAGE_OFFER_UNDERFUNDED: Int32 = -7    // doesn't hold what it's trying to sell
    static let MANAGE_OFFER_CROSS_SELF: Int32 = -8     // would cross an offer from the same user
    static let MANAGE_OFFER_SELL_NO_ISSUER: Int32 = -9 // no issuer for what we're selling
    static let MANAGE_OFFER_BUY_NO_ISSUER: Int32 = -10 // no issuer for what we're buying

    // update errors
    static let MANAGE_OFFER_NOT_FOUND: Int32 = -11 // offerID does not match an existing offer

    static let MANAGE_OFFER_LOW_RESERVE: Int32 = -12 // not enough funds to create a new Offer
}

public struct ClaimOfferAtom: XDRDecodable, Encodable {
    let sellerID: AccountID
    let offerID: UInt64
    let assetSold: Asset
    let amountSold: Int64
    let assetBought: Asset
    let amountBought: Int64

    public init(from decoder: XDRDecoder) throws {
        sellerID = try decoder.decode(AccountID.self)
        offerID = try decoder.decode(UInt64.self)
        assetSold = try decoder.decode(Asset.self)
        amountSold = try decoder.decode(Int64.self)
        assetBought = try decoder.decode(Asset.self)
        amountBought = try decoder.decode(Int64.self)
    }
}

public struct ManageOfferSuccessResult: XDRDecodable, Encodable {
    let offersClaimed: [ClaimOfferAtom]
    let effect: ManageOfferEffect

    public init(from decoder: XDRDecoder) throws {
        offersClaimed = try decoder.decodeArray(ClaimOfferAtom.self)
        effect = try decoder.decode(ManageOfferEffect.self)
    }
    
    enum ManageOfferEffect: XDRDecodable {
        struct ManageOfferEffect
        {
            static let MANAGE_OFFER_CREATED: Int32 = 0
            static let MANAGE_OFFER_UPDATED: Int32 = 1
            static let MANAGE_OFFER_DELETED: Int32 = 2
        }

        init(from decoder: XDRDecoder) throws {
            let discriminant = try decoder.decode(Int32.self)
            
            switch discriminant {
            case ManageOfferEffect.MANAGE_OFFER_CREATED:
                self = .MANAGE_OFFER_CREATED(try decoder.decode(OfferEntry.self))
            default:
                self = .MANAGE_OFFER_UPDATED(try decoder.decode(OfferEntry.self))
            }
        }
        
        case MANAGE_OFFER_CREATED (OfferEntry)
        case MANAGE_OFFER_UPDATED (OfferEntry)
    }

    public func encode(to encoder: Encoder) throws {
    }
}

public enum ManageOfferResult: XDRDecodable, Encodable {
    case MANAGE_OFFER_SUCCESS (ManageOfferSuccessResult)
    case failure (Int32)

    private func discriminant() -> Int32 {
        switch self {
        case .MANAGE_OFFER_SUCCESS:
            return ManageOfferResultCode.MANAGE_OFFER_SUCCESS
        case .failure (let code):
            return code
        }
    }
    
    public init(from decoder: XDRDecoder) throws {
        let discriminant = try decoder.decode(Int32.self)
        
        switch discriminant {
        case ManageOfferResultCode.MANAGE_OFFER_SUCCESS:
            self = .MANAGE_OFFER_SUCCESS(try decoder.decode(ManageOfferSuccessResult.self))
        default:
            self = .failure(discriminant)
        }
    }

    public func encode(to encoder: Encoder) throws {
    }
}

public enum SetOptionsResult: XDRDecodable, Encodable {
    case result (Int32)

    private enum CodingKeys: String, CodingKey {
        case name
        case result
    }

    public init(from decoder: XDRDecoder) throws {
        self = .result(try decoder.decode(Int32.self))
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode("set_options", forKey: .name)

        switch self {
        case .result(let code):
            try container.encode(code, forKey: .result)
        }
    }
}

public enum AllowTrustResult: XDRDecodable, Encodable {
    case result (Int32)

    private enum CodingKeys: String, CodingKey {
        case name
        case result
    }

    public init(from decoder: XDRDecoder) throws {
        self = .result(try decoder.decode(Int32.self))
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode("allow_trust", forKey: .name)

        switch self {
        case .result(let code):
            try container.encode(code, forKey: .result)
        }
    }
}

public enum ManageDataResult: XDRDecodable, Encodable {
    case result (Int32)

    private enum CodingKeys: String, CodingKey {
        case name
        case result
    }

    public init(from decoder: XDRDecoder) throws {
        self = .result(try decoder.decode(Int32.self))
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode("manage_data", forKey: .name)

        switch self {
        case .result(let code):
            try container.encode(code, forKey: .result)
        }
    }
}

public enum BumpSequenceResult: XDRDecodable, Encodable {
    case result (Int32)

    private enum CodingKeys: String, CodingKey {
        case name
        case result
    }

    public init(from decoder: XDRDecoder) throws {
        self = .result(try decoder.decode(Int32.self))
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode("bump_sequence", forKey: .name)

        switch self {
        case .result(let code):
            try container.encode(code, forKey: .result)
        }
    }
}

struct AccountMergeResultCode {
    // codes considered as "success" for the operation
    static let ACCOUNT_MERGE_SUCCESS: Int32 = 0
    // codes considered as "failure" for the operation
    static let ACCOUNT_MERGE_MALFORMED: Int32 = -1       // can't merge onto itself
    static let ACCOUNT_MERGE_NO_ACCOUNT: Int32 = -2      // destination does not exist
    static let ACCOUNT_MERGE_IMMUTABLE_SET: Int32 = -3   // source account has AUTH_IMMUTABLE set
    static let ACCOUNT_MERGE_HAS_SUB_ENTRIES: Int32 = -4 // account has trust lines/offers
    static let ACCOUNT_MERGE_SEQNUM_TOO_FAR: Int32 = -5  // sequence number is over max allowed
};

public enum AccountMergeResult: XDRDecodable, Encodable {
    case ACCOUNT_MERGE_SUCCESS (Int64)
    case failure (Int32)

    public init(from decoder: XDRDecoder) throws {
        let discriminant = try decoder.decode(Int32.self)

        switch discriminant {
        case AccountMergeResultCode.ACCOUNT_MERGE_SUCCESS:
            self = .ACCOUNT_MERGE_SUCCESS(try decoder.decode(Int64.self))
        default:
            self = .failure(discriminant)
        }
    }

    public func encode(to encoder: Encoder) throws {
    }
}

struct InflationResultCode {
    // codes considered as "success" for the operation
    static let INFLATION_SUCCESS: Int32 = 0
    // codes considered as "failure" for the operation
    static let INFLATION_NOT_TIME: Int32 = -1
}

public struct InflationPayout: XDRDecodable, Encodable {
    let destination: AccountID
    let amount: Int64

    public init(from decoder: XDRDecoder) throws {
        destination = try decoder.decode(AccountID.self)
        amount = try decoder.decode(Int64.self)
    }
}

public enum InflationResult: XDRDecodable, Encodable {
    case INFLATION_SUCCESS ([InflationPayout])
    case INFLATION_NOT_TIME

    public init(from decoder: XDRDecoder) throws {
        let discriminant = try decoder.decode(Int32.self)

        switch discriminant {
        case InflationResultCode.INFLATION_SUCCESS:
            self = .INFLATION_SUCCESS(try decoder.decodeArray(InflationPayout.self))
        default:
            self = .INFLATION_NOT_TIME
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()

        switch self {
        case .INFLATION_SUCCESS(let payout):
            try container.encode(payout)
        case .INFLATION_NOT_TIME:
            try container.encode(InflationResultCode.INFLATION_NOT_TIME)
        }
    }
}
