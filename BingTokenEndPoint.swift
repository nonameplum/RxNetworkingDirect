//
//  BingTokenEndPoint.swift
//  TranslateEverywhere
//
//  Created by Łukasz Śliwiński on 04/09/16.
//  Copyright © 2016 Plum's organization. All rights reserved.
//

import Foundation
import Alamofire
import RxSwift
import SwiftyJSON

struct BingTokenEndpoint: Endpoint, Mapping {

    // MARK: Consts

    static let clientID = ""
    static let clientSecret = ""

    // MARK: Endpoint
    let path = "v2/OAuth2-13"
    let parameters: [String : AnyObject]? = ["grant_type": "client_credentials",
                                             "client_id": clientID,
                                             "client_secret": clientSecret,
                                             "scope": "http://api.microsofttranslator.com"]
    let method: Alamofire.Method = .POST

    // MARK: Mapping

    func mapResponse(response: NSHTTPURLResponse, data: NSData) -> Observable<AdmAccessToken> {
        let json = JSON(data: data)

        if let accessToken = json["access_token"].string,
            tokenType = json["token_type"].string,
            expiresIn = json["expires_in"].string,
            scope = json["scope"].string {
            let admAccessToken = AdmAccessToken(accessToken: accessToken, tokenType: tokenType, expiresIn: expiresIn, scope: scope)

            return Observable.just(admAccessToken)
        } else {
            return Observable.error(Error.InvalidJSON)
        }
    }
}
