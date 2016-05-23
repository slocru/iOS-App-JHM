//
//  SummerMissionsTableViewController.swift
//  Cru
//
//  Created by Deniz Tumer on 5/13/16.
//  Copyright © 2016 Jamaican Hopscotch Mafia. All rights reserved.
//

import UIKit

class SummerMissionsTableViewController: UITableViewController {
    
    @IBOutlet weak var menuButton: UIBarButtonItem!
    
    var missions = [SummerMission]()
    private let reuseIdentifier = "missionCell"

    override func viewDidLoad() {
        super.viewDidLoad()
        
        if self.revealViewController() != nil{
            menuButton.target = self.revealViewController()
            menuButton.action = "revealToggle:"
            self.view.addGestureRecognizer(self.revealViewController().panGestureRecognizer())
        }
        
        CruClients.getServerClient().getData(DBCollection.SummerMission, insert: insertMission, completionHandler: reload)
        
        navigationItem.title = "Summer Missions"
        
        self.navigationController!.navigationBar.titleTextAttributes  = [ NSFontAttributeName: UIFont(name: Config.fontBold, size: 20)!, NSForegroundColorAttributeName: UIColor.whiteColor()]
    }

    // Creates and inserts a SummerMission into this collection view from the given dictionary.
    func insertMission(dict : NSDictionary) {
        self.missions.append(SummerMission(dict: dict)!)
    }
    
    // Signals the collection view to reload data.
    func reload(success: Bool) {
        self.tableView.reloadData()
    }

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return missions.count
    }
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        let mission = missions[indexPath.row]
        
        if mission.imageLink == "" {
            return 150.0
        }
        else {
            return 305.0
        }
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(self.reuseIdentifier, forIndexPath: indexPath) as! SummerMissionsTableViewCell
        let mission = missions[indexPath.row]
        
        cell.selectionStyle = UITableViewCellSelectionStyle.None
        cell.mission = mission

        return cell
    }
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "missionDetails" {
            self.navigationItem.backBarButtonItem = UIBarButtonItem(title:"", style:.Plain, target:nil, action:nil)
            let missionDetailViewController = segue.destinationViewController as! SummerMissionDetailController
            let selectedMissionCell = sender as! SummerMissionsTableViewCell
            let indexPath = self.tableView!.indexPathForCell(selectedMissionCell)!
            let selectedMission = missions[indexPath.row]
            missionDetailViewController.uiImage = selectedMissionCell.missionImage?.image
            missionDetailViewController.mission = selectedMission
            missionDetailViewController.dateText = selectedMissionCell.missionDateLabel.text!
            
            
        }
    }
    

}
