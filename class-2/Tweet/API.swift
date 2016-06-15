//
//  API.swift
//  Tweet
//
//  Created by Earnest Cain on 6/14/16.
//  Copyright © 2016 Cainco. All rights reserved.
//

import Foundation
import Accounts
import Social

class API {
    
    
    static let shared = API()
    var account: ACAccount?
    
    private func login(completion: (account: ACAccount?) -> ()) {
        
        // set up account store
        let accountStore = ACAccountStore()
        
        // give account store an account type of twitter
        let accountType = accountStore.accountTypeWithAccountTypeIdentifier(ACAccountTypeIdentifierTwitter)
        
        accountStore.requestAccessToAccountsWithType(accountType, options: nil, completion: { (granted, error) -> Void in
            
            if let _ = error {
                
                print("ERROR: Request access to accounts returned an error.")
                completion(account: nil)
                return
            
            }
            
            if granted {
                
                if let account = accountStore.accountsWithAccountType(accountType).first as? ACAccount {
                    completion(account: account)
                    return
                
                }
                
                // if no account was found
                print("ERROR: No twitter accounts were found on this device.")
                completion(account: nil)
                return
           
            }
            
            // if user did not grant access to account store for twitter accounts
            print("Error: This app requires access to the Twitter Accounts.")
            completion(account: nil)
            return
        
        })
        
    }
    
    private func GETOAuthUser(completion: (user: User?) -> ()) {
        
        let request = SLRequest(forServiceType: SLServiceTypeTwitter, requestMethod: .GET, URL: NSURL(string: "https://api.twitter.com/1.1/account/verify_credentials.json"), parameters: nil)
        
        request.account = self.account
        
        request.performRequestWithHandler { (data, response, error) in
            
            if let _ = error {
                
                print("Error: SLRequest type get for credentials could not be completed.")
                completion(user: nil)
                return
            
            }
            
            switch response.statusCode {
                
            case 200...299:
                
                do {
                    
                    if let userJSON = try NSJSONSerialization.JSONObjectWithData(data, options: .MutableContainers) as? [String : AnyObject]{
                        completion(user: User(json: userJSON))
                    
                    }
                
                } catch {
                    
                    print("Error: Count not serialize the JSON")
                    completion(user: nil)
                
                }
                
            case 400...499:
                
                print("Client Error statuscode: \(response.statusCode)")
                completion(user: nil)
            
            case 500...599:
                
                print("Client Error statuscode: \(response.statusCode)")
                completion(user: nil)
            
            default:
                print("Default case on the status code")
                completion(user: nil)
                
            }
            
        }
    }
    
    private func updateTimeLine(completion: (tweets: [Tweet]?) -> ()) {
        
        let request = SLRequest(forServiceType: SLServiceTypeTwitter, requestMethod: .GET, URL: NSURL(string: "https://api.twitter.com/1.1/statuses/home_timeline.json"), parameters: nil)
        
        request.account = self.account
        
        request.performRequestWithHandler { (data, response, error) in
            
            if let _ = error {
                
                print("Error: SLRequest type get for user Timeline could not be completed.")
                completion(tweets: nil)
                return
            
            }
            
            switch response.statusCode {
                
            case 200...299:
                
                JSONParser.tweetJSONFrom(data, completion: { (success, tweets) in
                    dispatch_async(dispatch_get_main_queue(), {
                        completion(tweets: tweets)
                    
                    })
                })
            
            // same cases from GETOAuthUser switch statement for HTTP request codes
            case 400...499:
                
                print("Client Error statuscode: \(response.statusCode)")
                completion(tweets: nil)
            
            case 500...599:
                
                print("Server Error statuscode: \(response.statusCode)")
                completion(tweets: nil)
            
            default:
                
                print("Default case on the status code")
                completion(tweets: nil)
            
            }
        }
    }
    
    func getTweets(completion: (tweets: [Tweet]?) -> ()) {
        
        if let _ = self.account {
            self.updateTimeLine(completion)
        
        } else {
            
            self.login( { (account) in
                
                if let account = account {
                    API.shared.account = account
                    self.updateTimeLine(completion)
                
                } else {
                    
                    print("Account is nil")
                
                }
            })
        }
        
    }
    
}

