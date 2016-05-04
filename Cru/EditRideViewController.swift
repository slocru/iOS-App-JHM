//
//  EditRideViewController.swift
//  Cru
//
//  Created by Max Crane on 5/3/16.
//  Copyright © 2016 Jamaican Hopscotch Mafia. All rights reserved.
//

import UIKit

class EditRideViewController: UIViewController {
    var event : Event!
    var ride : Ride!
    @IBOutlet weak var eventName: UILabel!
    @IBOutlet weak var address: UILabel!
    @IBOutlet weak var driverName: UITextField!
    @IBOutlet weak var driverNumber: UITextField!
    @IBOutlet weak var timeLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        address.sizeToFit()
        populateLabels()
        // Do any additional setup after loading the view.
    }
    
    
    func populateLabels(){
        eventName.text = event!.name
        address.text = ride!.getCompleteAddress()
        driverName.text = ride!.driverName
        driverNumber.text = ride!.driverNumber
        timeLabel.text = ride!.time
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func editPressed(sender: UIButton) {
        var editChoice = sender.titleLabel!.text
        
        switch editChoice!{
            case "editTime":
                print("editTime")
            case "editAddress":
                print("editAddress")
            case "editName":
                driverName.becomeFirstResponder()
            case "editNumber":
                driverNumber.becomeFirstResponder()
            default:
                print("k")
        }
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
