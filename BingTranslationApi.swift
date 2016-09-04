//
//  BingTranslationService.swift
//  TranslateEverywhere
//
//  Created by Macbook on 03/07/16.
//  Copyright © 2016 Plum's organization. All rights reserved.
//

import Foundation
import RxSwift
import RxAlamofire
import SwiftyJSON
import Alamofire

class BingTranslationClient {

    // MARK: - Properties

    private static let sharedInstance = BingTranslationClient()
    private var bingToken: AdmAccessToken?
    private let oauthClient: RxNetworkClient
    private let bingClient: RxNetworkClient

    static let sharedClient: RxNetworkClient = sharedInstance.bingClient

    // MARK: Init

    init() {
        self.oauthClient = RxNetworkClient(baseURL: NSURL(string: "https://datamarket.accesscontrol.windows.net/")!)
        self.bingClient = RxNetworkClient(baseURL: NSURL(string: "http://api.microsofttranslator.com/v2/Http.svc/")!)

        // Configure bing client
        self.bingClient.requestCreator = { [unowned self] (url, endpoint) throws -> NSMutableURLRequest in
            let request = try createEndpointRequest(url, endpoint: endpoint)
            if let token = self.bingToken?.accessToken {
                request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            }
            return request
        }

        self.bingClient.responseMiddleware = { [unowned self] (endpoint, response) -> Observable<(NSHTTPURLResponse, NSData)> in
            if (400..<401).contains(response.0.statusCode) {
                return self.oauthClient.rx_mappedRequest(BingTokenEndpoint())
                    .flatMap { [unowned self] (token) -> Observable<(NSHTTPURLResponse, NSData)> in
                        self.bingToken = token
                        return self.bingClient.rx_request(endpoint)
                    }
            }

            return Observable.just(response)
        }
    }

}
