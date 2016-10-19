//
//  ViewController.swift
//  alarm5
//
//  Created by olderor on 19.10.16.
//  Copyright © 2016 olderor. All rights reserved.
//


import UIKit

extension Int {
    func toTimeString() -> String {
        if self < 10 {
            return "0\(self)"
        }
        return "\(self)"
    }
}

func degree2radian(a:CGFloat)->CGFloat {
    let b = CGFloat(M_PI) * a/180
    return b
}

func circleCircumferencePoints(sides:Int,x:CGFloat,y:CGFloat,radius:CGFloat,adjustment:CGFloat=0)->[CGPoint] {
    let angle = degree2radian(a: 360/CGFloat(sides))
    let cx = x // x origin
    let cy = y // y origin
    let r  = radius // radius of circle
    var i = sides
    var points = [CGPoint]()
    while points.count <= sides {
        let xpo = cx - r * cos(angle * CGFloat(i)+degree2radian(a: adjustment))
        let ypo = cy - r * sin(angle * CGFloat(i)+degree2radian(a: adjustment))
        points.append(CGPoint(x: xpo, y: ypo))
        i -= 1;
    }
    return points
}

func secondMarkers(ctx:CGContext, x:CGFloat, y:CGFloat, radius:CGFloat, sides:Int, color:UIColor) {
    // retrieve points
    let points = circleCircumferencePoints(sides: sides,x: x,y: y,radius: radius)
    // create path
    let path = CGMutablePath()
    // determine length of marker as a fraction of the total radius
    var divider:CGFloat = 1/16
    var index = 0
    for p in points {
        if index % 5 == 0 {
            divider = 1/8
        }
        else {
            divider = 1/16
        }
        
        let xn = p.x + divider*(x-p.x)
        let yn = p.y + divider*(y-p.y)
        
        path.move(to: CGPoint(x: p.x, y: p.y))
        path.addLine(to: CGPoint(x: xn, y: yn))
        path.closeSubpath()
        ctx.addPath(path)
        
        index += 1
    }
    // set path color
    let cgcolor = color.cgColor
    ctx.setStrokeColor(cgcolor)
    ctx.setLineWidth(3.0)
    ctx.strokePath()
    
}

enum NumberOfNumerals:Int {
    case two = 2, four = 4, twelve = 12
}

func drawText(rect:CGRect, ctx:CGContext, x:CGFloat, y:CGFloat, radius:CGFloat, sides:NumberOfNumerals, color:UIColor) {
    
    ctx.translateBy(x: 0.0, y: rect.height)
    ctx.scaleBy(x: 1.0, y: -1.0)
    
    let inset:CGFloat = radius/3.5
    // An adjustment of 270 degrees to position numbers correctly
    let points = circleCircumferencePoints(sides: sides.rawValue * 2,x: x,y: y,radius: radius-inset,adjustment:270)
    
    // multiplier enables correcting numbering when fewer than 12 numbers are featured, e.g. 4 sides will display 12, 3, 6, 9
    let multiplier = 12/sides.rawValue
    
    var index = 0
    for p in points {
        if index > 0 {
            
            let aFont = UIFont.systemFont(ofSize: radius/5) //UIFont(name: "System", size: radius/5)
            // create a dictionary of attributes to be applied to the string
            let attr = [NSFontAttributeName:aFont,NSForegroundColorAttributeName:UIColor.black]
            // create the attributed string
            let str = String(index*multiplier)
            let text = CFAttributedStringCreate(nil, str as CFString!, attr as CFDictionary!)
            // create the line of text
            let line = CTLineCreateWithAttributedString(text!)
            // retrieve the bounds of the text
            let bounds = CTLineGetBoundsWithOptions(line, CTLineBoundsOptions.useOpticalBounds)
            // set the line width to stroke the text with
            ctx.setLineWidth(1.5)
            ctx.setTextDrawingMode(.stroke)
            // Set text position and draw the line into the graphics context, text length and height is adjusted for
            let xn = p.x - bounds.width/2
            let yn = p.y - bounds.midY
            ctx.textPosition = CGPoint(x: xn, y: yn)
            
            CTLineDraw(line, ctx)
        }
        index += 1
    }
    
}

class ClockView: UIView {
    
    
    override func draw(_ rect:CGRect)
        
    {
        
        // obtain context
        let ctx = UIGraphicsGetCurrentContext()
        
        // decide on radius
        let rad = rect.width/3.5
        
        let endAngle = CGFloat(2*M_PI)
        
        // add the circle to the context
        ctx?.addArc(center: CGPoint(x: rect.midX, y: rect.midY), radius: rad, startAngle: 0, endAngle: endAngle, clockwise: true)
        ctx?.setFillColor(UIColor.white.cgColor)
        
        ctx?.setStrokeColor(UIColor.black.cgColor)
        
        ctx?.setLineWidth(4.0)
        
        ctx?.drawPath(using: .fillStroke)
        
        
        
        secondMarkers(ctx: ctx!, x: rect.midX, y: rect.midY, radius: rad, sides: 120, color: UIColor.black)
        
        drawText(rect:rect, ctx: ctx!, x: rect.midX, y: rect.midY, radius: rad, sides: .four, color: UIColor.black)
        
        
        
        
    }
    
    
    
    
}

class ViewController: UIViewController, CAAnimationDelegate {
    
    
    @IBOutlet weak var progressView: KDCircularProgress!
    
    
    @IBOutlet weak var startProgressView: UIView!
    @IBOutlet weak var endProgressView: UIView!
    
    
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var sleepingLabel: UILabel!
    
    
    
    
    @IBAction func onSetUpAlarmButtonTouchUpInside(_ sender: UIButton) {
        
        let alert = UIAlertController(title: "Done", message: "You have set an alarm at \(endTime.toString())", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        self.present(alert, animated: true, completion: nil)
        
    }
    
    
    
    
    
    
    func ctime ()-> Time {
        var t = time_t()
        time(&t)
        let x = localtime(&t) // returns UnsafeMutablePointer
        
        return Time(h:Int(x!.pointee.tm_hour),m:Int(x!.pointee.tm_min))
    }
    
    class Time {
        var h = 0
        var m = 0
        
        init(h: Int, m: Int) {
            self.h = h
            self.m = m
        }
        
        func toString() -> String {
            return h.toTimeString() + ":" + m.toTimeString()
        }
    }
    
    var startTime: Time! = nil
    var endTime: Time! = nil
    
    func  timeCoords(x:Double,y:Double,radius:Double,adjustment:Double=90, time: Time)->CGPoint {
        let cx = x // x origin
        let cy = y // y origin
        var r  = radius // radius of circle
        var points = [CGPoint]()
        var angle = 6.0 * M_PI / 180.0
        func newPoint (t:Double) {
            let xpo = cx - r * cos(angle * t + adjustment * M_PI / 180.0)
            let ypo = cy - r * sin(angle * t + adjustment * M_PI / 180.0)
            points.append(CGPoint(x: xpo, y: ypo))
        }
        
        let hoursInSeconds = (time.h*3600 + time.m*60) / 2
        newPoint(t: Double(hoursInSeconds)*5.0/3600.0)
        
        return points[0]
    }
    
    func getAngle(location: CGPoint) -> Double {
        var angle = Double(atan(abs(location.x - self.view.frame.midX)/abs(location.y - self.view.frame.midY))) * 180.0 / M_PI
        if location.y > self.view.frame.midY {
            angle = 180.0 - angle
        }
        if location.x < self.view.frame.midX {
            angle = 360.0 - angle
        }
        return angle
    }
    
    func getTime(location: CGPoint) -> Time {
        let angle = getAngle(location: location)
        let minutes = Int(angle / 3.0)
        var hour = minutes / 5
        var minute = (minutes % 5) * 15
        if minute == 60 {
            minute = 0
            hour = hour + 1
        }
        if hour > 23 {
            hour = 0
        }
        return Time(h: hour, m: minute)
    }
    
    
    
    
    
    func handlePanForStart(_ gestureRecognizer: UIPanGestureRecognizer) {
        
        let location = gestureRecognizer.location(in: self.view)
        startTime = getTime(location: location)
        
        let timec = timeCoords(x: Double(self.view.frame.midX), y: Double(self.view.frame.midY), radius: 125, time: startTime)
        startProgressView.frame = CGRect(x: timec.x - 25, y: timec.y - 25, width: 50, height: 50)
        let prevAngle = progressView.startAngle
        progressView.startAngle = getAngle(location: location) - 90
        progressView.angle = progressView.angle - (progressView.startAngle - prevAngle)
        
        timeLabel.text = startTime.toString() + " - " + endTime.toString()
        sleepingLabel.text = "sleeping \((endTime.h - startTime.h + 24 - ((endTime.m - startTime.m) >= 0 ? 0 : 1)) % 24) hours and \((endTime.m - startTime.m + 60) % 60) minutes"
    }
    
    func handlePanForEnd(_ gestureRecognizer: UIPanGestureRecognizer) {
        
        let location = gestureRecognizer.location(in: self.view)
        endTime = getTime(location: location)
        
        let timec = timeCoords(x: Double(self.view.frame.midX), y: Double(self.view.frame.midY), radius: 125, time: endTime)
        endProgressView.frame = CGRect(x: timec.x - 25, y: timec.y - 25, width: 50, height: 50)
        progressView.angle = (getAngle(location: location) - 90.0 - progressView.startAngle + 360.0).truncatingRemainder(dividingBy: 360)
        
        timeLabel.text = startTime.toString() + " - " + endTime.toString()
        sleepingLabel.text = "sleeping \((endTime.h - startTime.h + 24 - ((endTime.m - startTime.m) >= 0 ? 0 : 1)) % 24) hours and \((endTime.m - startTime.m + 60) % 60) minutes"
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.bringSubview(toFront: startProgressView)
        self.view.bringSubview(toFront: endProgressView)
        
        let startGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(handlePanForStart))
        let endGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(handlePanForEnd))
        startProgressView.addGestureRecognizer(startGestureRecognizer)
        endProgressView.addGestureRecognizer(endGestureRecognizer)
        
        startTime = Time(h: 21, m: 0)
        endTime = Time(h: 9, m: 0)
        
        var timec = timeCoords(x: Double(self.view.frame.midX), y: Double(self.view.frame.midY), radius: 125, time: startTime)
        startProgressView.frame = CGRect(x: timec.x - 25, y: timec.y - 25, width: 50, height: 50)
        progressView.startAngle = getAngle(location: CGPoint(x: timec.x, y: timec.y)) - 90
        
        timec = timeCoords(x: Double(self.view.frame.midX), y: Double(self.view.frame.midY), radius: 125, time: endTime)
        endProgressView.frame = CGRect(x: timec.x - 25, y: timec.y - 25, width: 50, height: 50)
        progressView.angle = (getAngle(location: CGPoint(x: timec.x, y: timec.y)) - 90.0 - progressView.startAngle + 360.0).truncatingRemainder(dividingBy: 360)
        
    }
}


