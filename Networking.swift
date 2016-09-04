//
//  Networking.swift
//  TranslateEverywhere
//
//  Created by Macbook on 11/08/16.
//  Copyright © 2016 Plum's organization. All rights reserved.
//

import Foundation
import RxSwift
import Alamofire
import RxAlamofire

protocol Endpoint {
    var path: String { get }
    var method: Alamofire.Method { get }
    var encoding: Alamofire.ParameterEncoding { get }
    var parameters: [String: AnyObject]? { get }
    var headers: [String: String]? { get }
    var mockResponse: MockResponse? { get }
}

protocol Mapping {
    associatedtype MapperType
    func mapResponse(response: NSHTTPURLResponse, data: NSData) -> Observable<MapperType>
}

extension Endpoint {
    var method: Alamofire.Method { return Alamofire.Method.GET }
    var encoding: Alamofire.ParameterEncoding { return Alamofire.ParameterEncoding.URL }
    var parameters: [String: AnyObject]? { return nil }
    var headers: [String: String]? { return nil }
    var mockResponse: MockResponse? { return nil }
}

struct MockResponse {
    let mockData: NSData
    var statusCode: Int = 200
}

extension MockResponse {
    func getHttpURLResponse(url: NSURL) -> NSHTTPURLResponse? {
        return NSHTTPURLResponse(URL: url, statusCode: statusCode, HTTPVersion: nil, headerFields: nil)
    }
}

func createEndpointRequest(baseURL: NSURL, endpoint: Endpoint) throws -> NSMutableURLRequest {
    let request = try URLRequest(endpoint.method,
               baseURL.URLByAppendingPathComponent(endpoint.path),
               parameters: endpoint.parameters,
               encoding: endpoint.encoding,
               headers: endpoint.headers)
    return request
}

class RxNetworkClient {

    // MARK: Types

    typealias URLRequestCreator = (NSURL, Endpoint) throws -> NSMutableURLRequest
    typealias ResponseMiddleware = (Endpoint, (NSHTTPURLResponse, NSData)) -> Observable<(NSHTTPURLResponse, NSData)>

    // MARK: Properties

    let baseURL: NSURL
    var manager: Alamofire.Manager
    var requestCreator: URLRequestCreator
    var responseMiddleware: ResponseMiddleware?
    var setupRequest: ((NSMutableURLRequest) -> NSMutableURLRequest)?
    var mockMode: Bool

    // MARK: Initialization

    init(baseURL: NSURL, manager: Alamofire.Manager, requestCreator: URLRequestCreator, mockMode: Bool) {
        self.baseURL = baseURL
        self.manager = manager
        self.requestCreator = requestCreator
        self.mockMode = mockMode
    }

    convenience init(baseURL: NSURL) {
        self.init(baseURL: baseURL, manager: Alamofire.Manager.sharedInstance, requestCreator: createEndpointRequest, mockMode: false)
    }

    // MARK: Public

    func rx_request(endpoint: Endpoint) -> Observable<(NSHTTPURLResponse, NSData)> {
        return flatMapEndpoint(endpoint)
    }

    func rx_mappedRequest<E: protocol<Endpoint, Mapping>>(endpoint: E) -> Observable<E.MapperType> {
        return flatMapEndpoint(endpoint)
            .flatMap { (response, data) -> Observable<E.MapperType> in
                let x = endpoint.mapResponse(response, data: data)
                return x
            }
    }

    // MARK: Helpers

    func flatMapEndpoint(endpoint: Endpoint) -> Observable<(NSHTTPURLResponse, NSData)> {
        return manager
            .rx_request { [unowned self] in
                let request = $0.request(try self.requestCreator(self.baseURL, endpoint))
                debugPrint(request)
                return request
            }
            .flatMap { [unowned self] (request) -> Observable<(NSHTTPURLResponse, NSData)> in
                if let mockResponse = endpoint.mockResponse where self.mockMode,
                    let response = mockResponse.getHttpURLResponse(self.baseURL.URLByAppendingPathComponent(endpoint.path)) {
                    return Observable.just((response, mockResponse.mockData))
                }
                return request.rx_responseData()
            }
            .flatMap { [unowned self] (response) -> Observable<(NSHTTPURLResponse, NSData)> in
                if let responseMiddleware = self.responseMiddleware {
                    return responseMiddleware(endpoint, response)
                } else {
                    return Observable.just(response)
                }
        }
    }
}
