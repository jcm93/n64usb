//
//  Controller.swift
//  n64usb
//
//  Created by jcm on 5/5/24.
//

import Cocoa
import SwiftUI
//serial port functions included via bridging header; see SerialPort.h

enum ControllerInitializeError: Error {
    case SerialPortError
    case EventTapError
}

struct N64Input {
    var inputType: N64InputType
    var binding: CGKeyCode
    var value: Int32
    var pressed: Bool
}

@MainActor
class Controller: ObservableObject {
    
    var inputs: [CGKeyCode : N64Input] = [
        0x24: N64Input(inputType: .A, binding: 0x24, value: 1, pressed: false),
        0x7D: N64Input(inputType: .B, binding: 0x7D, value: 1, pressed: false),
        0x31: N64Input(inputType: .Z, binding: 0x31, value: 1, pressed: false),
        0x0D: N64Input(inputType: .YAxis, binding: 0x0D, value: 90, pressed: false),
        0x13: N64Input(inputType: .YAxis, binding: 0x13, value: 127, pressed: false),
        0x00: N64Input(inputType: .XAxis, binding: 0x00, value: -127, pressed: false),
        0x02: N64Input(inputType: .XAxis, binding: 0x02, value: 127, pressed: false),
        0x01: N64Input(inputType: .YAxis, binding: 0x01, value: -127, pressed: false)
    ]
    
    var fileDescriptor: Int32 = 0
    var eventTap: N64EventTap! = nil
    
    private var _pollInputTimer: DispatchSourceTimer?
    
    private let _pollInputQueue = DispatchQueue(
        label: "inputPollQueue",
        qos: .userInteractive,
        attributes: [],
        autoreleaseFrequency: .workItem,
        target: .global(qos: .userInteractive)
    )
    
    @State var isCapturing = false
    var keys = CharacterSet()
    
    func start() async throws {
        try locateMicrocontroller()
        self.eventTap = try N64EventTap(self.eventTapCallback, controller: self)
        _pollInputTimer = DispatchSource.makeTimerSource(flags: .strict, queue: _pollInputQueue)
        _pollInputTimer!.schedule(
            deadline: .now(),
            repeating: 1.0 / Double(60),
            leeway: .seconds(0)
        )
        _pollInputTimer?.setEventHandler {
            self.sendInput()
        }
        _pollInputTimer?.resume()
    }
    
    func locateMicrocontroller() throws {
        self.fileDescriptor = findControllerModem()
        if self.fileDescriptor == 0 {
            throw ControllerInitializeError.SerialPortError
        }
    }
    
    func sendInput() {
        let mask = createInputMask()
        writeRaw(self.fileDescriptor, mask)
    }
    
    func createInputMask() -> Int32 {
        var packedInputBytes: Int32 = 0
        for (_, input) in inputs {
            if input.pressed {
                print("shifting \(input.value) by \(input.inputType.bitOffset())")
                packedInputBytes |= input.value << input.inputType.bitOffset()
            }
            
        }
        return packedInputBytes
    }
    
    func eventTapCallback(keyCode: CGKeyCode, pressed: Bool) {
        inputs[keyCode]!.pressed = pressed
    }
}
