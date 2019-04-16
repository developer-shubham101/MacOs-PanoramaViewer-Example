//
//  ViewController.swift
//  PanoramaViewer
//
//  Created by Shubham Sharma on 15/04/19.
//  Copyright © 2019 devpoint. All rights reserved.
//

import Cocoa

class ViewController: NSViewController, DropDelegares {
    
    @IBOutlet weak var panoramaView: CTPanoramaView!
    @IBOutlet weak var mainDropView: DropView!
    @IBOutlet weak var zoomRange: NSSlider!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        panoramaView.image = NSImage(named: "panorama")
        mainDropView.delegates = self
        
    }
    @IBAction func zoomRange(_ sender: NSSlider) {
        panoramaView.zoom(scale: sender.doubleValue)
    }
    
    func droped(path: String) {
        panoramaView.image = NSImage(contentsOfFile: path)
    }
    
}


