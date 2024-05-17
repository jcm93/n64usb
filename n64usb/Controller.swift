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
    var value: Int32
    var pressed: Bool
}

@MainActor
class Controller: ObservableObject {
    
    var inputs: [KeyEquivalent : N64Input] = [
        .return: N64Input(inputType: .A, value: 1, pressed: false),
        .downArrow: N64Input(inputType: .B, value: 1, pressed: false),
        .space: N64Input(inputType: .Z, value: 1, pressed: false),
        "p": N64Input(inputType: .Start, value: 1, pressed: false),
        "w": N64Input(inputType: .YAxis, value: 89, pressed: false),
        "/": N64Input(inputType: .CLeft, value: 1, pressed: false),
        "2": N64Input(inputType: .YAxis, value: 127, pressed: false),
        "a": N64Input(inputType: .XAxis, value: -128, pressed: false),
        "d": N64Input(inputType: .XAxis, value: 127, pressed: false),
        "s": N64Input(inputType: .YAxis, value: -128, pressed: false),
        "r": N64Input(inputType: .R, value: 1, pressed: false)
    ]
    
    var fileDescriptor: Int32 = 0
    
    private var _pollInputTimer: DispatchSourceTimer?
    
    private let _pollInputQueue = DispatchQueue(
        label: "inputPollQueue",
        qos: .userInteractive,
        attributes: [],
        autoreleaseFrequency: .workItem,
        target: .global(qos: .userInteractive)
    )
    
    @State var isCapturing = false
    
    func start() async throws {
        try locateMicrocontroller()
        _pollInputTimer = DispatchSource.makeTimerSource(flags: .strict, queue: _pollInputQueue)
        _pollInputTimer!.schedule(
            deadline: .now(),
            repeating: 1.0 / Double(600),
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
                let value = input.value
                let valueToAdd = value < 0 ? (~value+1) : value
                packedInputBytes |= valueToAdd << input.inputType.bitOffset()
            }
        }
        return packedInputBytes
    }
    
    func keyPressEvent(_ keyPress: KeyPress) {
        //synchronize to ensure no race condition
        _pollInputQueue.sync {
            if keyPress.phase == .down {
                inputs[keyPress.key]?.pressed = true
            } else if keyPress.phase == .up {
                inputs[keyPress.key]?.pressed = false
            }
        }
    }
}
