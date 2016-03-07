

import Foundation
import Alamofire

class LoginUtils {
    class func login(username: String, password :String, completionHandler : (success : Bool) -> Void) {
        
        let params = ["username":username, "password":password]
        let url = Config.serverUrl + "api/signin"
        Alamofire.request(.POST, url, parameters: params)
            .responseJSON { response in
                var success : Bool = false
                if let body = response.result.value as! NSDictionary? {
                    if (body["success"] as! Bool) {
                        GlobalUtils.saveString(Config.leaderApiKey, value: body[Config.leaderApiKey] as! String)
                        GlobalUtils.saveString(Config.username, value: username)
                        success = true
                    }
                }
                
                completionHandler(success: success)
        }
    }

    class func logout() {
        let url = Config.serverUrl + "api/signout"
        GlobalUtils.saveString(Config.leaderApiKey, value: "")
        Alamofire.request(.POST, url, parameters: nil)
            .responseJSON { response in }
    }
}
