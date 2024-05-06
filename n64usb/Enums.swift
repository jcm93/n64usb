//
//  Enums.swift
//  n64usb
//
//  Created by jcm on 5/6/24.
//

import Foundation

enum N64InputType: Int {
    case A
    case B
    case Z
    case Start
    case DPadUp
    case DPadDown
    case DPadLeft
    case DPadRight
    case Reset
    case None
    case L
    case R
    case CUp
    case CDown
    case CLeft
    case CRight
    case XAxis
    case YAxis
    func bitOffset() -> Int {
        switch self {
        case .A:
            0
        case .B:
            1
        case .Z:
            2
        case .Start:
            3
        case .DPadUp:
            4
        case .DPadDown:
            5
        case .DPadLeft:
            6
        case .DPadRight:
            7
        case .Reset:
            8
        case .None:
            9
        case .L:
            10
        case .R:
            11
        case .CUp:
            12
        case .CDown:
            13
        case .CLeft:
            14
        case .CRight:
            15
        case .XAxis:
            16
        case .YAxis:
            24
        }
    }
}
