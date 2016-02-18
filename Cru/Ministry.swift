//
//  Campus.swift
//  Cru
//
//  Created by Max Crane on 11/29/15.
//  Copyright © 2015 Jamaican Hopscotch Mafia. All rights reserved.
//

import Foundation

class Ministry: NSObject, NSCoding, Comparable{
    var name: String!
    var id: String!
    var campusIds: [String]
    var feedEnabled: Bool!
    var imageUrl: String!
    var imageData: NSData?
    
    required init?(coder aDecoder: NSCoder) {
        name = aDecoder.decodeObjectForKey("name") as! String
        id = aDecoder.decodeObjectForKey("id") as! String
        campusIds = aDecoder.decodeObjectForKey("campusIds") as! [String]
        feedEnabled = aDecoder.decodeObjectForKey("feedEnabled") as! Bool
        imageUrl = aDecoder.decodeObjectForKey("imgUrl") as! String
    }
    
    func encodeWithCoder(aCoder: NSCoder) {
        aCoder.encodeObject(name, forKey: "name")
        aCoder.encodeObject(id, forKey: "id")
        aCoder.encodeObject(campusIds, forKey: "campusIds")
        aCoder.encodeObject(feedEnabled, forKey: "feedEnabled")
        aCoder.encodeObject(imageUrl, forKey: "imgUrl")
    }
    
    init(dict: NSDictionary) {
        self.name = dict["name"] as! String
        self.id = dict["_id"] as! String
        self.campusIds = dict["campuses"] as! [String]
        self.feedEnabled = false // crashes without this shit
        self.imageUrl = "http://res.cloudinary.com/dcyhqxvmq/image/upload/v1453505468/sxgmbetwbbvozk385a7j.jpg"
        if (dict["image"] != nil){
            let image = dict["image"] as! NSDictionary
            
            if(image["url"] != nil){
                self.imageUrl = image["url"] as! String
            }
        }
    }
    
    init(name: String, id: String, campusIds: [String], feedEnabled: Bool, imgUrl: String){
        self.name = name
        self.id = id
        self.campusIds = campusIds
        self.feedEnabled = feedEnabled
        self.imageUrl = imgUrl
    }
    
    init(name: String, id: String, campusIds: [String], imgUrl: String){
        self.name = name
        self.id = id
        self.campusIds = campusIds
        self.feedEnabled = false
        self.imageUrl = imgUrl
    }
    
    override func isEqual(object: AnyObject?) -> Bool {
        if let obj = object as? Ministry{
            //return obj.name == self.name
            return obj.id == self.id
        }
        else{
            return false
        }
    }
    
}

func  <(lCampus: Ministry, rCampus: Ministry) -> Bool{
    return lCampus.name < rCampus.name
}