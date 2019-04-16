//
//  CTPieSliceView.swift
//  CTPanoramaView
//
//  Created by Shubham Sharma on 15/04/19.
//  Copyright © 2019 devpoint. All rights reserved.
//

import Cocoa

@IBDesignable @objcMembers public class CTPieSliceView: NSView {

    @IBInspectable var sliceAngle: CGFloat = .pi/2 {
        didSet {   }
    }

    @IBInspectable var sliceColor: NSColor = .red {
        didSet {   }
    }

    @IBInspectable var outerRingColor: NSColor = .green {
        didSet {   }
    }

    @IBInspectable var bgColor: NSColor = .black {
        didSet {  }
    }

    #if !TARGET_INTERFACE_BUILDER

    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    #endif

    func commonInit() {
        wantsLayer = true
        layer?.backgroundColor = NSColor.clear.cgColor
//        contentMode = .redraw
    }

    public override func draw(_ rect: CGRect) {
        super.draw(rect)
 wantsLayer = true
        guard let ctx = NSGraphicsContext.current?.cgContext else {return}
self.layer?.addSublayer(CALayer())
        // Draw the background
        ctx.saveGState()
        ctx.addEllipse(in: bounds)
        ctx.setFillColor(bgColor.cgColor)
        ctx.fillPath()

        // Draw the outer ring
        ctx.addEllipse(in: bounds.insetBy(dx: 2, dy: 2))
        ctx.setStrokeColor(outerRingColor.cgColor)
        ctx.setLineWidth(2)
        ctx.strokePath()

        let radius = (bounds.width/2)-6
        let localCenter = CGPoint(x: bounds.size.width/2, y: bounds.size.height/2)
        let startAngle = -(.pi/2 + sliceAngle/2)
        let endAngle = startAngle + sliceAngle
        let arcStartPoint = CGPoint(x: localCenter.x + radius * cos(startAngle),
                                    y: localCenter.y + radius * sin(startAngle))

        // Draw the inner slice
        ctx.beginPath()
        ctx.move(to: localCenter)
        ctx.addLine(to: arcStartPoint)
        ctx.addArc(center: localCenter, radius: radius, startAngle: startAngle, endAngle: endAngle, clockwise: false)
        ctx.closePath()
        ctx.setFillColor(sliceColor.cgColor)
        ctx.fillPath()
    }
}

extension CTPieSliceView: CTPanoramaCompass {
    public func updateUI(rotationAngle: CGFloat, fieldOfViewAngle: CGFloat) {
        wantsLayer = true
        sliceAngle = fieldOfViewAngle
        
        
//        self.layer?.transform = CGAffineTransform.identity.rotated(by: rotationAngle)
        self.layer?.transform = CATransform3DMakeRotation(rotationAngle, 0, 0, bounds.size.width/2)
    }
}
