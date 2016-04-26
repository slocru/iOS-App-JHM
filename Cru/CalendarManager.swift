//
//  CalendarManager.swift
//  Cru
//
//  Created by Deniz Tumer on 3/9/16.
//  Copyright © 2016 Jamaican Hopscotch Mafia. All rights reserved.
//

import Foundation
import EventKit

class CalendarManager: CalendarServices {
    /*
    This function is the public access function for adding an event to
    the native calendar.
    
    Creates the event and adds it to the calendar if it is not already there.
    */
    func addEventToCalendar(event: Event, completionHandler: (error: NSError?, eventIdentifier: String?) -> ()) {
        var errors: NSError? = nil
        var eventIdentifier: String? = nil
        
        //Get authorization to native calendar
        switch EKEventStore.authorizationStatusForEntityType(EKEntityType.Event) {
        //If the user has authorized access to the calendar
        case .Authorized:
            addEvent(event, completionHandler: { error, id in
                errors = error
                eventIdentifier = id
            })
            
        //If the user has denied access to the calendar
        case .Denied:
            errors = createUnauthorizedErrorObject()
            
        //If access tp the calendar has not yet been determined
        case .NotDetermined:
            if requestNativeCalendarAccess() {
                addEvent(event, completionHandler: { error, id in
                    errors = error
                    eventIdentifier = id
                })
            }
            else {
                errors = createUnauthorizedErrorObject()
            }
            
        default:
            print("No Default Case")
            
        }
        
        completionHandler(error: errors, eventIdentifier: eventIdentifier)
    }
    
    func removeEventFromCalendar(eventIdentifier: String, completionHandler: (error: NSError?) -> ()) {
        var errors: NSError? = NSError(domain: "", code: 0, userInfo: nil)
        
        //Get authorization to native calendar
        switch EKEventStore.authorizationStatusForEntityType(EKEntityType.Event) {
            //If the user has authorized access to the calendar
        case .Authorized:
            errors = removeEvent(eventIdentifier)
            
            //If the user has denied access to the calendar
        case .Denied:
            errors = createUnauthorizedErrorObject()
            
            //If access tp the calendar has not yet been determined
        case .NotDetermined:
            if requestNativeCalendarAccess() {
                errors = removeEvent(eventIdentifier)
            }
            else {
                errors = createUnauthorizedErrorObject()
            }
            
        default:
            print("No Default Case")
            
        }
        
        completionHandler(error: errors)
    }
    
    //Creates an unauthorized error object
    private func createUnauthorizedErrorObject() -> NSError {
        let errorInfo: [NSObject : AnyObject] =
        [
            NSLocalizedDescriptionKey :  NSLocalizedString("Unauthorized", value: "Please change the calendar access settings for this application", comment: ""),
            NSLocalizedFailureReasonErrorKey : NSLocalizedString("Unauthorized", value: "Access to the native calendar has not been given to this application", comment: "")
        ]
        
        return NSError(domain: "NativeCalendarAccessError", code: 401, userInfo: errorInfo)
    }
    
    //helper function that actually inserts the event to the calendar
    private func addEvent(event: Event, completionHandler: (errors: NSError?, eventIdentifier: String?) -> ()) {
        let calendarEvent = createCalendarEvent(event)
        var errors: NSError? = nil
        var eventIdentifier: String? = nil
        
        //try to store the event into the calendar
        do {
            try self.calendarStore.saveEvent(calendarEvent, span: EKSpan.ThisEvent, commit: true)
            eventIdentifier = calendarEvent.eventIdentifier
        }
        catch let error as NSError {
            errors = error
        }
        catch {
            fatalError()
        }
        
        completionHandler(errors: errors, eventIdentifier: eventIdentifier)
    }
    
    //helper method for removing event from calendar
    private func removeEvent(eventIdentifier: String) -> NSError? {
        let calendarEvent = self.calendarStore.eventWithIdentifier(eventIdentifier)!
        
        //try to store the event into the calendar
        do {
            try self.calendarStore.removeEvent(calendarEvent, span: EKSpan.ThisEvent, commit: true)
            return nil
        }
        catch let error as NSError {
            return error
        }
        catch {
            fatalError()
        }
    }
    
    //this function tries to get access to the native calendar for the application
    //returns true if success, false otherwise
    private func requestNativeCalendarAccess() -> Bool {
        var isValid = false
        
        calendarStore.requestAccessToEntityType(EKEntityType.Event, completion: {
            granted, error in
            
            if granted && error == nil {
                isValid = true
            }
        })
        
        return isValid
    }
}