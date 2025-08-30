//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2024 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

// swiftlint:disable file_length file_types_order generic_type_name

import ByteCoding
import Foundation
import NIOCore


/// Medical floating point value representation using base 10.
///
/// This type implements MedFloat operations, abstracted over the MedFloat's exponent and mantissa sizes.
///
/// The value of a MedFloat can be calculated using the the following formula, where `**` denotes exponentiation:
///
///     x.mantissa * (10 ** x.exponent)
///
/// ## Topics
/// ### Initializers
@available(iOS 26, macOS 26, macCatalyst 26, watchOS 26, visionOS 26, tvOS 26, *)
public struct MedFloat<
    BitPattern, Exponent, Mantissa,
    let exponentBitWidth: Int, let mantissaBitWidth: Int
>: Codable, Sendable
where BitPattern: FixedWidthInteger & _UnsignedInteger & PrimitiveByteCodable & Codable & Sendable,
      Exponent: FixedWidthInteger & _SignedInteger & Codable & Sendable,
      Mantissa: FixedWidthInteger & _SignedInteger & Codable & Sendable {
    /// The MedFloat's underlying type.
    /// - Note: This type must be large enough to be able to store both the exponent as well as the mantissa,
    ///     i.e., it must hold that `MemoryLayout<BitPattern>.size * 8 >= Self.exponentBitWidth + Self.mantissaBitWidth`.
    public typealias BitPattern = BitPattern
    /// The type to be used for representing the MedFloat's exponent values.
    public typealias Exponent = Exponent
    /// The type to be used for representing the MedFloat's mantissa values.
    public typealias Mantissa = Mantissa
    
    /// The size of the MedFloat's exponent, in bit.
    /// - Note: This value must compare less than or equal to the bit width of the ``Exponent`` type.
    @inlinable public static var exponentBitWidth: Int { exponentBitWidth }
    /// The size of the MedFloat's mantissa, in bit.
    /// - Note: This value must compare less than or equal to the bit width of the ``Mantissa`` type.
    @inlinable public static var mantissaBitWidth: Int { mantissaBitWidth }
    
    /// The MedFloat's underlying bit pattern.
    public private(set) var bitPattern: BitPattern
    
    /// Creates a new MedFloat value using the spexified bit pattern.
    /// - Note: No normalisation or other input validation is performed.
    public init(bitPattern: BitPattern) {
        self.bitPattern = bitPattern
    }
}


@available(iOS 26, macOS 26, macCatalyst 26, watchOS 26, visionOS 26, tvOS 26, *)
extension MedFloat {
    /// The signed exponent, in two's complement.
    ///
    /// - Note: if the size of the MedFloat's exponent is smaller than the size of the `Exponent` type used to represent the exponent,
    ///     the value is adjusted to the underlying type's two's complement representation.
    public var exponent: Exponent {
        var exponentBitPattern = Exponent._Unsigned(bitPattern >> Self.mantissaBitWidth)
        // We need to correct the exponent two's complement IntN representation (where N is Self.exponentBitWidth)
        // to an IntM two's complement (where M is Self.mantissaBitWidth):
        // If its larger than the largest positive IntN number, we want to make sure that all higher bits are flipped
        // in the IntM representation.
        if exponentBitPattern > Self.exponentMaxValue {
            exponentBitPattern |= .init(bitPattern: ~Self.exponentUsedBitsMask)
        }
        return Exponent(bitPattern: exponentBitPattern)
    }
    
    
    /// The signed mantissa, in two's complement.
    ///
    /// - Note: if the size of the MedFloat's mantissa is smaller than the size of the `Mantissa` type used to represent the mantissa,
    ///     the value is adjusted to the underlying type's two's complement representation.
    public var mantissa: Mantissa {
        var mantissaBitPattern = Mantissa._Unsigned(bitPattern & .bitmask(Self.mantissaBitWidth))
        // See explanation in `exponent`. We need to correct the mantissa two's complement representation
        // as stored in bitPattern into one fitting the actual Mantissa type.
        if mantissaBitPattern > Self.mantissaMaxValue {
            mantissaBitPattern |= .init(bitPattern: ~Self.mantissaUsedBitsMask)
        }
        return Mantissa(bitPattern: mantissaBitPattern)
    }
    
    
    /// Derive a MedFloat from its exponent and mantissa.
    ///
    /// The value of the medfloat can be calculated using the the following formula, where `**` denotes exponentiation:
    ///
    ///     x.mantissa * (10 ** x.exponent)
    ///
    /// - Note: The `exponent` and `mantissa` are constrained to their underlying resolutions
    ///     (as defined by `MedFloat.exponentBitWidth` and `MedFloat.mantissaBitWidth`, respectively).
    ///     Passing values exceeding this ranges will result in a ``nres`` value.
    ///
    /// - Note: Be aware that some exponent-mantissa tuples where the exponent is zero are used to represent special values;
    ///     mantissa values in the range `Self.infinity` – `Self.negativeInfinity` (w.r.t. their underlying bit pattern)
    ///     are used to represent special values like NaN, nRes, or infinity.
    ///
    /// - Parameters:
    ///   - exponent: The signed constrained exponent of the MedFloat.
    ///   - mantissa: The signed constrained exponent of the MedFloat.
    public init(exponent: Exponent, mantissa: Mantissa) {
        // check that exponent and mantissa are not out of range.
        if exponent > Self.exponentMaxValue || mantissa > Self.mantissaMaxValue
            || exponent < Self.exponentMinValue || mantissa < Self.mantissaMinValue {
            self = mantissa >= 0 ? .infinity : .negativeInfinity
            return
        }

        var exponent = exponent
        var mantissa = mantissa

        Self.normalize(exponent: &exponent, mantissa: &mantissa)

        let exponentBitPattern = Exponent._Unsigned(bitPattern: exponent) & .init(bitPattern: Self.exponentUsedBitsMask)
        let mantissaBitPattern = Mantissa._Unsigned(bitPattern: mantissa) & .init(bitPattern: Self.mantissaUsedBitsMask)

        self.init(bitPattern: (BitPattern(exponentBitPattern) << Self.mantissaBitWidth) | BitPattern(mantissaBitPattern))
    }
}


@available(iOS 26, macOS 26, macCatalyst 26, watchOS 26, visionOS 26, tvOS 26, *)
extension MedFloat {
    /// The zero value.
    @inlinable public static var zero: Self {
        Self(bitPattern: 0)
    }
    
    /// Indicates invalid result.
    ///
    /// Indicates a invalid result form a computation step or to indicate missing data due to the hardware's inability to provide a valid measurement.
    /// Visual components should reflect this information by blanking the display or some other appropriate means.
    @inlinable public static var nan: Self {
        Self(bitPattern: (1 << (Self.mantissaBitWidth - 1)) - 1)
    }
    
    /// Positive infinity.
    @inlinable public static var infinity: Self {
        Self(bitPattern: (1 << (Self.mantissaBitWidth - 1)) - 2)
    }
    
    /// Negative infinity.
    @inlinable public static var negativeInfinity: Self {
        let mantissa: Mantissa = -((1 << (Self.mantissaBitWidth - 1)) - 2)
        let bitPattern = BitPattern(truncatingIfNeeded: mantissa) & .bitmask(Self.mantissaBitWidth)
        return Self(bitPattern: bitPattern)
    }
    
    /// Special value indicating that a value cannot be represented with the available range or resolution.
    ///
    /// This situation could result from an overflow or underflow situation.
    @inlinable public static var nres: Self {
        Self(bitPattern: 1 << (Self.mantissaBitWidth - 1))
    }
    
    /// The `reserved0` special value.
    public static var reserved0: Self {
        let mantissa: Mantissa = -((1 << (Self.mantissaBitWidth - 1)) - 1)
        let bitPattern = BitPattern(truncatingIfNeeded: mantissa) & .bitmask(Self.mantissaBitWidth)
        return Self(bitPattern: bitPattern)
    }
    
    /// A Boolean value indicating whether the instance is NaN ("not a number").
    ///
    /// Because NaN is not equal to any value, including NaN, use this property
    /// instead of the equal-to operator (`==`) or not-equal-to operator (`!=`)
    /// to test whether a value is or is not NaN.
    @inlinable public var isNaN: Bool {
        bitPattern == Self.nan.bitPattern
    }
    
    /// Determine if float is zero.
    ///
    /// There are multiple representations of zero (all these, where the mantissa is set to zero, with an arbitrary combination of exponents).
    @inlinable public var isZero: Bool {
        mantissa == 0
    }

    /// A Boolean value indicating whether the instance is nRes ("not at this resolution").
    ///
    /// Because nRes is not equal to any value, including nRes, use this property
    /// instead of the equal-to operator (`==`) or not-equal-to operator (`!=`)
    /// to test whether a value is or is not nRes.
    @inlinable public var isNRes: Bool {
        bitPattern == Self.nres.bitPattern
    }

    /// Reserved special value.
    @inlinable public var isReserved0: Bool {
        bitPattern == Self.reserved0.bitPattern
    }

    /// Any NaN-like value (NaN, NRes, reserved0).
    @inlinable public var isNaNLike: Bool {
        isNaN || isNRes || isReserved0
    }

    /// A Boolean value indicating whether this instance is finite.
    ///
    /// All values other than NaN, nRes and infinity are considered finite, whether
    /// normal or subnormal.  For NaN and nRes, both `isFinite` and ``isInfinite`` are false.
    @inlinable public var isFinite: Bool {
        !isNaN && !isNRes && !isInfinite
    }

    /// A Boolean value indicating whether the instance is infinite.
    ///
    /// For NaN and nRes, both ``isFinite`` and `isInfinite` are false.
    @inlinable public var isInfinite: Bool {
        bitPattern == Self.infinity.bitPattern
            || bitPattern == Self.negativeInfinity.bitPattern
    }

    /// The sign of the floating-point value.
    ///
    /// The sign is `minus` if the mantissa has a negative value and `plus` otherwise.
    @inlinable public var sign: FloatingPointSign {
        if mantissa < 0 {
            .minus
        } else {
            .plus
        }
    }
}


@available(iOS 26, macOS 26, macCatalyst 26, watchOS 26, visionOS 26, tvOS 26, *)
extension MedFloat {
    private static func normalize(exponent: inout Exponent, mantissa: inout Mantissa) {
        while exponent > exponentMinValue,
              !mantissa.multipliedReportingOverflow(by: 10).overflow,
              mantissa * 10 >= medFloatMantissaMin,
              mantissa * 10 <= medFloatMantissaMax {
            mantissa *= 10
            exponent -= 1
        }
    }

    /// Replaces the value with its normalized version.
    @inlinable mutating func normalize() {
        self = normalized()
    }

    /// Returns a MedFloat with the same value as the receiver, but with the exponent and mantissa normalized.
    @inlinable func normalized() -> Self {
        // The initializer will perform normalization.
        Self(exponent: exponent, mantissa: mantissa)
    }
}


@available(iOS 26, macOS 26, macCatalyst 26, watchOS 26, visionOS 26, tvOS 26, *)
extension MedFloat {
    /// ``Double`` approximation of the medfloat.
    public var double: Double {
        // For some reason writing e.g. `Self.nan.bitPattern` in a switch case causes the compiler to reject the code, saying that
        // "'nan' is not a member type of type 'Self'". Writing `type(of: self).nan.bitPattern` instead compiles.
        // (See also https://github.com/swiftlang/swift/issues/77849.)
        // swiftlint:disable prefer_self_type_over_type_of_self
        switch bitPattern {
        case type(of: self).nan.bitPattern, type(of: self).nres.bitPattern, type(of: self).reserved0.bitPattern:
            return .nan
        case type(of: self).infinity.bitPattern:
            return .infinity
        case type(of: self).negativeInfinity.bitPattern:
            return -.infinity
        default:
            let magnitude = pow(10.0, Double(exponent))
            return Double(mantissa) * magnitude
        }
        // swiftlint:enable prefer_self_type_over_type_of_self
    }


    /// Creates a new instance that approximates the given value.
    ///
    /// The value of `other` is rounded to a representable value, if necessary.
    /// A NaN passed as `other` results in medfloat NaN.
    /// Values that are larger or smaller than what a MedFloat can represent results in positive or negative infinity.
    ///
    /// - Parameter other: The value to use for the new instance.
    public init(_ other: Double) {
        if other.isNaN {
            self = .nan
        } else if other > Self.maxDoubleValue {
            self = .infinity
        } else if other < Self.minDoubleValue {
            self = .negativeInfinity
        } else if other >= -Self.epsilon && other <= Self.epsilon {
            self = .zero
        } else {
            var exponent: Exponent = 0 // to base 10
            var mantissaTemp = abs(other) // we slowly scale up/down the exponent to have mantissa fit into mantissaBitWidth-bit two's complement

            // scale up if number is too big
            while mantissaTemp > Double(Self.mantissaMaxValue) {
                mantissaTemp /= 10
                exponent += 1

                if exponent > Self.exponentMaxValue {
                    preconditionFailure("Precondition check didn't properly check for infinity, \(Self.self) from double \(other)")
                }
            }

            // scale down if number is to small
            while mantissaTemp < 1 {
                mantissaTemp *= 10
                exponent -= 1

                if exponent < Self.exponentMinValue {
                    preconditionFailure("Precondition check didn't properly check for epsilon, \(Self.self) from double \(other)")
                }
            }

            // scale down if number needs more precision
            var mantissaDiff = Self.mantissaPrecisionDiff(mantissaTemp)
            while mantissaDiff > 0.5 && exponent > Self.exponentMinValue && (mantissaTemp * 10 <= Double(Self.mantissaMaxValue)) {
                mantissaTemp *= 10
                exponent -= 1

                mantissaDiff = Self.mantissaPrecisionDiff(mantissaTemp)
            }

            let mantissa = Mantissa(round((other.sign == .minus ? -1 : 1) * mantissaTemp))

            self.init(exponent: exponent, mantissa: mantissa)
            assert(self.isFinite, "Double initialization failed and resulted in \(description)")
        }
    }

    
    private static func mantissaPrecisionDiff(_ mantissa: Double) -> Double {
        let smantissa = round(mantissa * Self.precision)
        let rmantissa = round(mantissa) * Self.precision
        return abs(smantissa - rmantissa)
    }
}


// MARK: Comparable

@available(iOS 26, macOS 26, macCatalyst 26, watchOS 26, visionOS 26, tvOS 26, *)
extension MedFloat: Comparable {
    public static func < (lhs: Self, rhs: Self) -> Bool {
        if lhs.isNaNLike || rhs.isNaNLike {
            return false // any nan-like does never compare
        }
        switch (lhs.bitPattern, rhs.bitPattern) {
        case let (self.negativeInfinity.bitPattern, rhsBits):
            // `-infinity` compares less than all values except for itself and NaN-like values
            return rhsBits != self.negativeInfinity.bitPattern && !rhs.isNaNLike
        case let (lhsBits, self.infinity.bitPattern):
            // every value except for NaN and `+infinity` compares less than
            return lhsBits != Self.infinity.bitPattern && !lhs.isNaNLike
        case (_, self.negativeInfinity.bitPattern):
            return false // nothing is ever smaller than negative infinity
        case (self.infinity.bitPattern, _):
            return false // nothing is ever greater than positive infinity
        default:
            break
        }

        if lhs.isZero {
            return 0 < rhs.mantissa
        } else if rhs.isZero {
            return lhs.mantissa < 0
        } else {
            return lhs.double < rhs.double
        }
    }
}


// MARK: Equatable, Hashable

@available(iOS 26, macOS 26, macCatalyst 26, watchOS 26, visionOS 26, tvOS 26, *)
extension MedFloat: Equatable, Hashable {
    public static func == (lhs: Self, rhs: Self) -> Bool {
        if lhs.isNaNLike || rhs.isNaNLike {
            return false // any nan-like is never equal
        }
        if lhs.isZero && rhs.isZero {
            return true
        }
        return lhs.normalized().bitPattern == rhs.normalized().bitPattern
    }
    
    public func hash(into hasher: inout Hasher) {
        if isZero {
            hasher.combine(Self.zero.bitPattern)
        } else {
            hasher.combine(normalized().bitPattern)
        }
    }
}


// MARK: ExpressibleBy{Float,Integer}Literal

@available(iOS 26, macOS 26, macCatalyst 26, watchOS 26, visionOS 26, tvOS 26, *)
extension MedFloat: ExpressibleByFloatLiteral, ExpressibleByIntegerLiteral {
    /// Creates an instance initialized to the specified floating-point value.
    ///
    /// - Parameter value: The value to create.
    @inlinable public init(floatLiteral value: Double) {
        self.init(value)
    }
    
    /// Creates an instance initialized to the specified integer value.
    @inlinable public init(integerLiteral value: Int64) {
        let doubleValue = Double(value) // cheap route here
        self.init(doubleValue)
    }
}


// MARK: {Signed}Numeric, AdditiveArithmetic

@available(iOS 26, macOS 26, macCatalyst 26, watchOS 26, visionOS 26, tvOS 26, *)
extension MedFloat: Numeric, SignedNumeric, AdditiveArithmetic {
    public var magnitude: Self { // basically an abs function
        if isNaNLike || bitPattern == Self.infinity.bitPattern {
            return self
        } else if bitPattern == Self.negativeInfinity.bitPattern {
            return .infinity
        }
        let mantissa = mantissa
        if mantissa >= 0 {
            return self
        }
        // otherwise we are negative
        return -self
    }


    public init?(exactly source: some BinaryInteger) {
        var mantissa = source
        var exponent: Exponent = 0
        while !Self.fitsMantissa(mantissa) {
            if mantissa.isMultiple(of: 10) && exponent + 1 < Self.exponentMaxValue {
                mantissa /= 10
                exponent += 1
            } else {
                return nil // we can't adjust anymore!
            }
        }
        self.init(exponent: exponent, mantissa: Mantissa(mantissa))
    }

    
    private static func fitsMantissa(_ source: some BinaryInteger) -> Bool {
        // words from least significant to most significant
        let words = source.magnitude.words
        guard let first = words.first else {
            return true
        }
        guard words.suffix(from: 1).allSatisfy({ $0 == 0 }) else {
            return false // ensure there aren't any more words that contain ones
        }
        // check that the exponent bytes and the most significant mantissa bit is zero of second word.
        return first & (UInt.max << (Self.mantissaBitWidth - 1)) == 0
    }

    @inlinable public static func + (lhs: Self, rhs: Self) -> Self {
        // We are going the cheap route here! There, is way too much to check for otherwise.
        Self(lhs.double + rhs.double)
    }

    @inlinable public static func - (lhs: Self, rhs: Self) -> Self {
        lhs + (-rhs)
    }
    
    @inlinable public static func * (lhs: Self, rhs: Self) -> Self {
        // We are going the cheap route here! There, is way too much to check for otherwise.
        Self(lhs.double * rhs.double)
    }

    
    @inlinable public static func *= (lhs: inout Self, rhs: Self) {
        lhs = lhs * rhs
    }
    
    
    @inlinable public prefix static func - (operand: Self) -> Self {
        var operand = operand
        operand.negate()
        return operand
    }

    
    @inlinable public mutating func negate() {
        self = negated()
    }
    
    
    /// Returns this value's additive inverse.
    public func negated() -> Self {
        guard !isNaNLike else {
            return self
        }
        if bitPattern == Self.infinity.bitPattern {
            return .negativeInfinity
        } else if bitPattern == Self.negativeInfinity.bitPattern {
            return .infinity
        } else {
            let mantissa = -self.mantissa
            let mantissaBits = Mantissa._Unsigned(bitPattern: mantissa) & Mantissa._Unsigned(bitPattern: Self.mantissaUsedBitsMask)
            var bitPattern = self.bitPattern
            bitPattern &= BitPattern(bitPattern: BitPattern._Signed(~Self.mantissaUsedBitsMask)) // reset mantissa bits
            bitPattern |= BitPattern(mantissaBits)
            return Self(bitPattern: bitPattern)
        }
    }
}


// MARK: Custom{Debug}StringConvertible

@available(iOS 26, macOS 26, macCatalyst 26, watchOS 26, visionOS 26, tvOS 26, *)
extension MedFloat: CustomStringConvertible, CustomDebugStringConvertible {
    private var specialValueString: String? {
        if isNaN || isReserved0 {
            return "nan"
        } else if isNRes {
            return "nres"
        } else if bitPattern == Self.infinity.bitPattern {
            return "inf"
        } else if bitPattern == Self.negativeInfinity.bitPattern {
            return "-inf"
        } else if isZero {
            return "0.0" // map all zeros to same representation
        }
        return nil
    }

    public var description: String {
        if let specialValueString {
            return specialValueString
        }

        let exponent = exponent
        let mantissa = mantissa

        var description = mantissa.description

        if exponent > 0 {
            description.append(String(repeating: "0", count: Int(exponent)))

            description.append(".0")
        } else if exponent == 0 {
            description.append(".0")
        } else { // exponent < 0
            let digitCount = description.count - (sign == .minus ? 1 : 0)

            if -exponent < digitCount {
                let dotIndex = description.index(description.endIndex, offsetBy: Int(exponent))

                description.insert(".", at: dotIndex)
            } else {
                let insertionIndex = sign == .minus
                    ? description.index(after: description.startIndex) // skipping the "-"
                    : description.startIndex

                let zeroPrefix = String(repeating: "0", count: Int(-exponent) - digitCount)
                description.insert(contentsOf: zeroPrefix, at: insertionIndex)

                description.insert(contentsOf: "0.", at: insertionIndex)
            }

            // remove unnecessary trailing zeros
            while description.last == "0" {
                description.removeLast()
            }

            if description.last == "." {
                description.append("0")
            }
        }

        return description
    }
    
    public var debugDescription: String {
        specialValueString ?? "\(mantissa)e\(exponent)"
    }
}


// MARK: PrimitiveByteCodable

@available(iOS 26, macOS 26, macCatalyst 26, watchOS 26, visionOS 26, tvOS 26, *)
extension MedFloat: PrimitiveByteCodable {
    public init?(from byteBuffer: inout ByteBuffer, endianness: Endianness) {
        guard let bitPattern = BitPattern(from: &byteBuffer, endianness: endianness) else {
            return nil
        }
        self.init(bitPattern: bitPattern)
    }
    
    public func encode(to byteBuffer: inout ByteBuffer, endianness: Endianness) {
        bitPattern.encode(to: &byteBuffer, endianness: endianness)
    }
}


// MARK: RawRepresentable

@available(iOS 26, macOS 26, macCatalyst 26, watchOS 26, visionOS 26, tvOS 26, *)
extension MedFloat: RawRepresentable {
    public var rawValue: BitPattern {
        bitPattern
    }

    public init(rawValue: BitPattern) {
        self.init(bitPattern: rawValue)
    }
}


@available(iOS 26, macOS 26, macCatalyst 26, watchOS 26, visionOS 26, tvOS 26, *)
extension MedFloat {
    /// The minimum value the exponent may have.
    @inlinable static var exponentMinValue: Exponent {
        if Self.exponentBitWidth == Exponent.bitWidth {
            // If the exponent uses the full width of its underlying type, the negation would overflow,
            // but we can instead simply return .min (which we can do bc of the fact that the sizes are equal).
            Exponent.min
        } else {
            -Exponent(bitPattern: 1 << (Self.exponentBitWidth - 1))
        }
    }
    
    /// The maximum value the exponent may have.
    @inlinable static var exponentMaxValue: Exponent {
        Exponent(bitPattern: (1 << (Self.exponentBitWidth - 1)) - 1)
    }
    
    /// A bitmask intended for selecting the bits of an ``Exponent`` value that are actually used.
    @inlinable static var exponentUsedBitsMask: Exponent {
        .bitmask(Self.exponentBitWidth)
    }
    
    /// The minimum value the mantissa may have.
    @inlinable static var mantissaMinValue: Mantissa {
        -Mantissa(bitPattern: 1 << (Self.mantissaBitWidth - 1))
    }
    
    /// The maximum value the mantissa may have.
    @inlinable static var mantissaMaxValue: Mantissa {
        Mantissa(bitPattern: (1 << (Self.mantissaBitWidth - 1)) - 1)
    }
    
    /// A bitmask intended for selecting the bits of an ``Mantissa`` value that are actually used.
    @inlinable static var mantissaUsedBitsMask: Mantissa {
        .bitmask(Self.mantissaBitWidth)
    }
    
    /// `2 ** (mantissaWidth - 1) - 3`
    /// `MedFloat.infinity - 1`
    @inlinable static var medFloatMantissaMax: Mantissa {
        Self.infinity.mantissa - 1
    }
    
    /// `MedFloat.negativeInfinity + 1`
    /// `MedFloat.nres + 3`
    @inlinable static var medFloatMantissaMin: Mantissa {
        Self.negativeInfinity.mantissa + 1
    }
    
    /// Maximum value in Double representation for a MedFloat.
    ///
    /// `(2 ** (mantissaWidth-1) - 3) * 10 ** maxExponent`
    @inlinable static var maxDoubleValue: Double {
        (pow(2 as Double, Double(Self.mantissaBitWidth) - 1) - 3) * pow(10 as Double, Double(Self.exponentMaxValue))
    }
    
    /// Minimum value in Double representation for a MedFloat.
    ///
    /// `-(2 ** (mantissaWidth-1) - 3) * 10 ** maxExponent`
    /// `-maxDoubleValue`
    @inlinable static var minDoubleValue: Double {
        -maxDoubleValue
    }
    
    /// The minimum precision of a MedFloat.
    ///
    /// `10 ** -bias`
    @inlinable static var epsilon: Double {
        pow(10 as Double, Double(-(BitPattern.bitWidth / 2)))
    }
    
    /// `10 ** upper((mantissaWidth-1) * log(2) / log(10))`
    @inlinable static var precision: Double {
        pow(10 as Double, ceil(Double(Self.mantissaBitWidth) * log(2) / log(10)))
    }
}


// MARK: Internal Helpers and Utilities

extension FixedWidthInteger {
    /// Constructs a value with the lowest `numBits` bits set to `1`, and everything else set to `0`.
    @inlinable @inline(__always)
    static func bitmask(_ numBits: Int) -> Self {
        (1 << numBits) - 1
    }
}


/// Helper protocol used for associating an `UnsignedInteger` type with its `SignedInteger` counterpart.
/// This is required for us to be able to implement the `MedFloat`,
/// and for the protocol to have access to the `init(bitPattern:)` initializers.
public protocol _UnsignedInteger: UnsignedInteger { // swiftlint:disable:this type_name
    associatedtype _Signed: _SignedInteger where _Signed._Unsigned == Self // swiftlint:disable:this type_name
    init(bitPattern: _Signed)
}

/// Helper protocol used for associating a `SignedInteger` type with its `UnsignedInteger` counterpart.
/// This is required for us to be able to implement the `MedFloat`,
/// and for the protocol to have access to the `init(bitPattern:)` initializers.
public protocol _SignedInteger: SignedInteger { // swiftlint:disable:this type_name
    associatedtype _Unsigned: _UnsignedInteger where _Unsigned._Signed == Self // swiftlint:disable:this type_name
    init(bitPattern: _Unsigned)
}


extension Int8: _SignedInteger {
    public typealias _Unsigned = UInt8 // swiftlint:disable:this type_name
}
extension UInt8: _UnsignedInteger {
    public typealias _Signed = Int8 // swiftlint:disable:this type_name
}

extension Int16: _SignedInteger {
    public typealias _Unsigned = UInt16 // swiftlint:disable:this type_name
}
extension UInt16: _UnsignedInteger {
    public typealias _Signed = Int16 // swiftlint:disable:this type_name
}

extension Int32: _SignedInteger {
    public typealias _Unsigned = UInt32 // swiftlint:disable:this type_name
}
extension UInt32: _UnsignedInteger {
    public typealias _Signed = Int32 // swiftlint:disable:this type_name
}
