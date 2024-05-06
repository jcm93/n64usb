//
//  KeyEventTap.swift
//  n64usb
//
//  Created by jcm on 5/6/24.
//

import Cocoa

class N64EventTap {
    
    private var controller: Controller
    
    var callback: ((CGKeyCode, Bool) -> Void)
    
    init(_ callback: @escaping (CGKeyCode, Bool) -> Void, controller: Controller) throws {
        
        self.controller = controller
        self.callback = callback
        
        let mask: CGEventMask = (1 << CGEventType.keyDown.rawValue) | (1 << CGEventType.keyUp.rawValue)
        
        let eventTap = CGEvent.tapCreate(tap: CGEventTapLocation.cghidEventTap,
                                         place: CGEventTapPlacement.headInsertEventTap,
                                         options: CGEventTapOptions.listenOnly,
                                         eventsOfInterest: mask,
                                         ///adapted from https://github.com/mickael-menu/ShadowVim/blob/a4fbea4c9322eb9c0db904808c0c54466605c133/Sources/Toolkit/Input/EventTap.swift#L51 (github code search)
                                         callback: { proxy, type, event, refcon in
                                                Unmanaged<N64EventTap>.fromOpaque(refcon!)
                                                    .takeUnretainedValue()
                                                    .eventTapCallback(proxy: proxy, type: type, event: event)
                                                    .map { Unmanaged.passUnretained($0) }
                                                    },
                                         userInfo: Unmanaged.passUnretained(self).toOpaque()
        )
        
        guard let eventTap = eventTap else {
            throw ControllerInitializeError.EventTapError
        }
        
        let runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0)
        CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
        CGEvent.tapEnable(tap: eventTap, enable: true)
    }
    
    @MainActor func eventTapCallback(proxy: CGEventTapProxy, type: CGEventType, event: CGEvent) -> CGEvent? {
        //per documentation, if we are only a passive listener, we can return nil without affecting the event stream

        guard let keyCode = NSEvent(cgEvent: event)?.keyCode else {
            return nil
        }
        
        let interestedKeyCodes = self.controller.inputs.keys
        
        if interestedKeyCodes.contains(keyCode) {
            let pressed = type == .keyDown
            callback(keyCode, pressed)
        }
        return nil
    }
}
