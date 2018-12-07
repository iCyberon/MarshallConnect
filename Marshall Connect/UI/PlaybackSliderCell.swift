//
//  PlaybackSlider.swift
//  Marshall Connect
//
//  Created by Vahagn Mkrtchyan on 12/8/18.
//  Copyright © 2018 Vahagn Mkrtchyan. All rights reserved.
//

import Cocoa

class PlaybackSliderCell: NSSliderCell {
    override func drawBar(inside rect: NSRect, flipped: Bool) {
        let backgroundColor : NSColor = NSColor(calibratedRed:0.13, green:0.13, blue:0.13, alpha:1.00)
        let elapsedColor : NSColor = NSColor.white
        let barSize : NSRect = rect.insetBy(dx: 0, dy: 1)
        
        let barPath = NSBezierPath(roundedRect: barSize, xRadius: barSize.size.height/2, yRadius: barSize.size.height/2)
        backgroundColor.setFill()
        barPath.fill()
        
        // Knob position
        let progress : Double = (self.doubleValue  - self.minValue) / (self.maxValue - self.minValue);
        let elapsedWidth : CGFloat = CGFloat(progress) * barSize.size.width;
        let elapsedSize : NSRect = NSRect(x: barSize.origin.x, y: barSize.origin.y, width: elapsedWidth, height: barSize.size.height)
        let elapsedBarPath = NSBezierPath(roundedRect: elapsedSize, xRadius: elapsedSize.size.height/2, yRadius: elapsedSize.size.height/2)
        
        elapsedColor.setFill()
        elapsedBarPath.fill()
    }

    override func drawKnob(_ knobRect: NSRect) {
        let barHeight = self.barRect(flipped: false).size.height
        let knobOvalSize = NSSize(width: 2 * barHeight, height: 2 * barHeight)
        let knowOvalOrigin = NSPoint(x: knobRect.origin.x + (knobRect.size.width - knobOvalSize.width) / 2, y: knobRect.origin.y + (knobRect.size.height - knobOvalSize.height) / 2)
        let knobOvalRect = NSRect(origin: knowOvalOrigin, size: knobOvalSize)
        let knobOvalPath = NSBezierPath(ovalIn: knobOvalRect)
        
        let shadow = NSShadow()
        shadow.shadowColor = NSColor.black.withAlphaComponent(0.5)
        shadow.shadowBlurRadius = 2;
        shadow.shadowOffset = NSMakeSize(0, 0);
        shadow.set()
        
        NSColor.white.setFill()
        knobOvalPath.fill()
    }
}

