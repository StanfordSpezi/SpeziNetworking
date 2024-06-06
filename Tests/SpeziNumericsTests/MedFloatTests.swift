//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2024 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

@_spi(TestingSupport) import ByteCoding
@testable import SpeziNumerics
import XCTByteCoding
import XCTest


final class MedFloatTests: XCTestCase {
    func testSpecialValues() {
        XCTAssertTrue(MedFloat16.nan.double.isNaN)
        XCTAssertTrue(MedFloat16.nres.double.isNaN)
        XCTAssertTrue(MedFloat16.reserved0.double.isNaN)
        XCTAssertEqual(MedFloat16.infinity.double, .infinity)
        XCTAssertEqual(MedFloat16.negativeInfinity.double, -Double.infinity)
    }

    func testDoubleConversion() {
        XCTAssertTrue(MedFloat16(.nan).isNaN)
        XCTAssertTrue(MedFloat16(.zero).isZero)
        XCTAssertEqual(MedFloat16(.infinity), .infinity)
        XCTAssertEqual(MedFloat16(-.infinity), .negativeInfinity)

        XCTAssertEqual(MedFloat16(123000.0), MedFloat16(exponent: 3, mantissa: 123))
        XCTAssertEqual(MedFloat16(12.34), MedFloat16(exponent: -2, mantissa: 1234))
        XCTAssertEqual(MedFloat16(0.0000012), MedFloat16(exponent: -7, mantissa: 12))

        XCTAssertEqual(MedFloat16(1234.0), MedFloat16(exponent: 0, mantissa: 1234))

        XCTAssertEqual(MedFloat16(-123000.0), MedFloat16(exponent: 3, mantissa: -123))
        XCTAssertEqual(MedFloat16(-12.34), MedFloat16(exponent: -2, mantissa: -1234))
        XCTAssertEqual(MedFloat16(-0.0000012), MedFloat16(exponent: -7, mantissa: -12))
    }

    func testBasicRepresentations() { // swiftlint:disable:this function_body_length
        let largeFloat = MedFloat16(exponent: 3, mantissa: 123)
        let smallFloat = MedFloat16(exponent: -2, mantissa: 1234)
        let smallSmallFloat = MedFloat16(exponent: -7, mantissa: 12)

        let zeroExponentFloat = MedFloat16(exponent: 0, mantissa: 1234)

        let negLargeFloat = MedFloat16(exponent: 3, mantissa: -123)
        let negSmallFloat = MedFloat16(exponent: -2, mantissa: -1234)
        let negSmallSmallFloat = MedFloat16(exponent: -7, mantissa: -12)

        XCTAssertEqual(largeFloat.exponent, 2)
        XCTAssertEqual(largeFloat.mantissa, 1230)
        XCTAssertEqual(smallFloat.exponent, -2)
        XCTAssertEqual(smallFloat.mantissa, 1234)
        XCTAssertEqual(smallSmallFloat.exponent, -8)
        XCTAssertEqual(smallSmallFloat.mantissa, 120)

        XCTAssertEqual(zeroExponentFloat.exponent, 0)
        XCTAssertEqual(zeroExponentFloat.mantissa, 1234)

        XCTAssertEqual(negLargeFloat.exponent, 2)
        XCTAssertEqual(negLargeFloat.mantissa, -1230)
        XCTAssertEqual(negSmallFloat.exponent, -2)
        XCTAssertEqual(negSmallFloat.mantissa, -1234)
        XCTAssertEqual(negSmallSmallFloat.exponent, -8)
        XCTAssertEqual(negSmallSmallFloat.mantissa, -120)

        XCTAssertTrue(largeFloat.isFinite)
        XCTAssertTrue(smallFloat.isFinite)
        XCTAssertTrue(smallSmallFloat.isFinite)
        XCTAssertTrue(negLargeFloat.isFinite)
        XCTAssertTrue(negSmallFloat.isFinite)
        XCTAssertTrue(negSmallSmallFloat.isFinite)

        XCTAssertEqual(largeFloat.double, 123000.0)
        XCTAssertEqual(smallFloat.double, 12.34)
        XCTAssertEqual(smallSmallFloat.double, 0.0000012)
        XCTAssertEqual(zeroExponentFloat.double, 1234.0)
        XCTAssertEqual(negLargeFloat.double, -123000.0)
        XCTAssertEqual(negSmallFloat.double, -12.34)
        XCTAssertEqual(negSmallSmallFloat.double, -0.0000012)


        XCTAssertEqual(MedFloat16.nan.description, "nan")
        XCTAssertEqual(MedFloat16.reserved0.description, "nan")
        XCTAssertEqual(MedFloat16.nres.description, "nres")
        XCTAssertEqual(MedFloat16.zero.description, "0.0")
        XCTAssertEqual(MedFloat16.infinity.description, "inf")
        XCTAssertEqual(MedFloat16.negativeInfinity.description, "-inf")

        XCTAssertEqual(largeFloat.description, "123000.0")
        XCTAssertEqual(smallFloat.description, "12.34")
        XCTAssertEqual(smallSmallFloat.description, "0.0000012")
        XCTAssertEqual(zeroExponentFloat.description, "1234.0")
        XCTAssertEqual(negLargeFloat.description, "-123000.0")
        XCTAssertEqual(negSmallFloat.description, "-12.34")
        XCTAssertEqual(negSmallSmallFloat.description, "-0.0000012")

        XCTAssertEqual(MedFloat16(127).description, "127.0")
        XCTAssertEqual(MedFloat16(12).description, "12.0")

        XCTAssertEqual(MedFloat16(exponent: 45, mantissa: 23), .infinity)
        XCTAssertEqual(MedFloat16(exponent: 2, mantissa: 23000), .infinity)
        XCTAssertEqual(MedFloat16(exponent: 2, mantissa: -23000), .negativeInfinity)
        XCTAssertEqual(MedFloat16(exponent: -2, mantissa: 6500), .infinity)
        XCTAssertEqual(MedFloat16(exponent: -9, mantissa: 650), .infinity)
        XCTAssertEqual(MedFloat16(exponent: -2, mantissa: -6500), .negativeInfinity)
        XCTAssertEqual(MedFloat16(exponent: -9, mantissa: -650), .negativeInfinity)
    }

    func testHashable() {
        var values: Set<MedFloat16> = []

        XCTAssertTrue(values.insert(.nan).inserted)
        XCTAssertTrue(values.insert(.nan).inserted)
        XCTAssertTrue(values.insert(.zero).inserted)
        XCTAssertFalse(values.insert(MedFloat16(exponent: -2, mantissa: 0)).inserted)
        XCTAssertTrue(values.insert(2).inserted)
        XCTAssertTrue(values.insert(4).inserted)
        XCTAssertFalse(values.insert(4).inserted)
        XCTAssertTrue(values.insert(.nres).inserted)
        XCTAssertTrue(values.insert(.nres).inserted)
        XCTAssertTrue(values.insert(.reserved0).inserted)
        XCTAssertTrue(values.insert(.reserved0).inserted)

        XCTAssertEqual(MedFloat16.nan.hashValue, MedFloat16.nan.hashValue)
        XCTAssertEqual(MedFloat16.nres.hashValue, MedFloat16.nres.hashValue)
        XCTAssertEqual(MedFloat16.reserved0.hashValue, MedFloat16.reserved0.hashValue)
    }

    func testEquality() {
        XCTAssertNotEqual(MedFloat16.nan, .nan)
        XCTAssertNotEqual(MedFloat16.nan, .nres)
        XCTAssertNotEqual(MedFloat16.nan, .infinity)
        XCTAssertNotEqual(MedFloat16.nan, MedFloat16(123))
        XCTAssertNotEqual(MedFloat16.nres, .nres)


        let float0 = MedFloat16(exponent: -1, mantissa: 130)
        let float1 = MedFloat16(exponent: 0, mantissa: 13)
        let float2 = MedFloat16(exponent: -2, mantissa: 1300)

        XCTAssertEqual(float0, float1)
        XCTAssertEqual(float0, float2)
        XCTAssertEqual(float1, float2)
        XCTAssertEqual(float0.description, float1.description)
        XCTAssertEqual(float1.description, float2.description)

        let float3 = MedFloat16(exponent: 1, mantissa: 10)
        let float4 = MedFloat16(exponent: 0, mantissa: 100)

        XCTAssertEqual(float3, float4)
        XCTAssertEqual(MedFloat16.zero, MedFloat16(exponent: 3, mantissa: 0))
    }

    func testComparable() {
        XCTAssertFalse(MedFloat16.nan < .nan)
        XCTAssertFalse(MedFloat16.nan < .nan)
        XCTAssertFalse(MedFloat16.nan < .nres)
        XCTAssertFalse(MedFloat16.nan < .reserved0)
        XCTAssertFalse(MedFloat16.nres < .nres)
        XCTAssertFalse(MedFloat16.nres < .nan)
        XCTAssertFalse(MedFloat16.nres < .reserved0)
        XCTAssertFalse(MedFloat16.reserved0 < .reserved0)
        XCTAssertFalse(MedFloat16.reserved0 < .nan)
        XCTAssertFalse(MedFloat16.reserved0 < .nres)

        XCTAssertFalse(MedFloat16.negativeInfinity < .negativeInfinity)
        XCTAssertFalse(MedFloat16.negativeInfinity < .nan)
        XCTAssertFalse(-503 < MedFloat16.negativeInfinity)
        XCTAssertFalse(.nan < MedFloat16.negativeInfinity)
        XCTAssertLessThan(MedFloat16.negativeInfinity, -503)
        XCTAssertLessThan(MedFloat16.negativeInfinity, .infinity)

        XCTAssertFalse(MedFloat16.infinity < 1234012)
        XCTAssertFalse(MedFloat16.infinity < .nan)
        XCTAssertFalse(MedFloat16.infinity < .infinity)
        XCTAssertFalse(.nan < MedFloat16.infinity)
        XCTAssertLessThan(123123, .infinity)

        XCTAssertFalse(MedFloat16.zero < MedFloat16(exponent: 3, mantissa: 0))
        XCTAssertLessThan(MedFloat16(-3), 0)
        XCTAssertLessThan(MedFloat16(-3), 4)
        XCTAssertLessThan(MedFloat16.zero, 4)
        XCTAssertLessThan(MedFloat16(0.578), 4)
        XCTAssertLessThan(MedFloat16(0.578), 4)
        XCTAssertLessThan(MedFloat16(-0.578), 4)

        XCTAssertLessThan(MedFloat16(-7.58), -0.78)
    }

    func testLiteralInits() {
        XCTAssertEqual(MedFloat16(150000000000), .infinity)
        XCTAssertEqual(MedFloat16(-150000000000), .negativeInfinity)

        print(Float(sign: .plus, exponent: 267, significand: 0.6))
        print(MedFloat16(150000000000).description)
        print(MedFloat16(150000000000).debugDescription)
    }

    func testExactlyConversion() {
        XCTAssertEqual(MedFloat16(exactly: UInt8.max), 255)
        XCTAssertEqual(MedFloat16(exactly: Int8.max), 127)
        XCTAssertEqual(MedFloat16(exactly: 12400), 12400)

        XCTAssertNil(MedFloat16(exactly: Int16.max))
        XCTAssertNil(MedFloat16(exactly: UInt16.max))
        XCTAssertNil(MedFloat16(exactly: Int32.max))
        XCTAssertNil(MedFloat16(exactly: UInt32.max))
        XCTAssertNil(MedFloat16(exactly: Int64.max))
        XCTAssertNil(MedFloat16(exactly: UInt64.max))
    }

    func testAddition() {
        XCTAssertTrue((MedFloat16.infinity + .negativeInfinity).isNaN)
        XCTAssertTrue((MedFloat16.negativeInfinity + .infinity).isNaN)

        XCTAssertTrue((MedFloat16.nan + .nan).isNaN)
        XCTAssertTrue((MedFloat16.nres + .nres).isNaN)
        XCTAssertTrue((MedFloat16.nan + .nres).isNaN)
        XCTAssertTrue((MedFloat16.nres + .nan).isNaN)
        XCTAssertTrue((MedFloat16.reserved0 + .nan).isNaN)
        XCTAssertTrue((MedFloat16.nan + .reserved0).isNaN)
        XCTAssertTrue((MedFloat16.nres + .reserved0).isNaN)
        XCTAssertTrue((MedFloat16.reserved0 + .nres).isNaN)

        XCTAssertEqual(MedFloat16.infinity + .infinity, .infinity)
        XCTAssertEqual(MedFloat16.infinity + 12, .infinity)
        XCTAssertEqual(MedFloat16.infinity + -12, .infinity)

        XCTAssertEqual(MedFloat16.negativeInfinity + .negativeInfinity, .negativeInfinity)
        XCTAssertEqual(MedFloat16.negativeInfinity + 12, .negativeInfinity)
        XCTAssertEqual(MedFloat16.negativeInfinity + -12, .negativeInfinity)


        XCTAssertEqual(MedFloat16(15) + 12, 27)
        XCTAssertEqual(MedFloat16(15000000000) + 12000000000, .infinity)
        XCTAssertEqual(MedFloat16(1500000000) + 1200000000, 2700000000)
        XCTAssertEqual(MedFloat16(15000000) + 120000, 15120000)
    }

    func testNegate() {
        XCTAssertEqual(-MedFloat16.negativeInfinity, .infinity)
        XCTAssertEqual(-MedFloat16.infinity, .negativeInfinity)
        XCTAssertTrue((-MedFloat16.nan).isNaN)
        XCTAssertTrue((-MedFloat16.nres).isNRes)
        XCTAssertEqual(-MedFloat16(4), -4)
    }

    func testMultiply() {
        var value: MedFloat16 = 2

        value *= 10
        XCTAssertEqual(value, 20)

        value *= 0.25
        XCTAssertEqual(value, 5)
    }

    func testMagnitude() {
        XCTAssertTrue(MedFloat16.nan.magnitude.isNaN)
        XCTAssertTrue(MedFloat16.nres.magnitude.isNRes)
        XCTAssertTrue(MedFloat16.reserved0.magnitude.isReserved0)

        XCTAssertEqual(MedFloat16.infinity.magnitude, .infinity)
        XCTAssertEqual(MedFloat16.negativeInfinity.magnitude, .infinity)

        XCTAssertEqual(MedFloat16.zero.magnitude, .zero)

        XCTAssertEqual(MedFloat16(12.5).magnitude, 12.5)
        XCTAssertEqual(MedFloat16(-12.5).magnitude, 12.5)
    }

    func testByteCoding() throws {
        try testIdentity(from: MedFloat16.infinity)
        try testIdentity(from: MedFloat16.negativeInfinity)
        try testIdentity(from: MedFloat16.zero)
        try testIdentity(from: MedFloat16(12.5))
        try testIdentity(from: MedFloat16(-12.5))

        // nan-like values don't compare, therefore we check for byte-wise equality
        try testIdentity(of: MedFloat16.self, from: XCTUnwrap(Data(hex: "0x07FF")))
        try testIdentity(of: MedFloat16.self, from: XCTUnwrap(Data(hex: "0x0800")))
        try testIdentity(of: MedFloat16.self, from: XCTUnwrap(Data(hex: "0x0801")))
    }
}
