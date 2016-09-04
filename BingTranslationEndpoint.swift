//
//  BingTranslationEndpoint.swift
//  TranslateEverywhere
//
//  Created by Łukasz Śliwiński on 04/09/16.
//  Copyright © 2016 Plum's organization. All rights reserved.
//

import Foundation
import Alamofire
import RxSwift
import SwiftyJSON

struct BingTranslationEndpoint: Endpoint, Mapping {

    // MARK: Endpoint

    let path = "Translate"
    var parameters: [String : AnyObject]? {
        return ["text": text,
                "from": from,
                "to": to]
    }

    // MARK: Parameters

    let text: String
    let from: String
    let to: String

    // MARK: Init

    init(text: String, from: String, to: String) {
        self.text = text
        self.from = from == "auto" ? "" : from
        self.to = to
    }

    // MARK: Mapping

    func mapResponse(response: NSHTTPURLResponse, data: NSData) -> Observable<Translation> {
        if let trans =  NSString(data: data, encoding: NSUTF8StringEncoding),
            regex = try? NSRegularExpression(pattern: "</?(S|s)tring.*?>", options: NSRegularExpressionOptions.DotMatchesLineSeparators) {

            let results = regex.matchesInString(trans as String, options: NSMatchingOptions.WithoutAnchoringBounds, range: NSRange(location: 0, length: trans.length))
            if results.count % 2 == 0 {
                let start = results[0].range.length
                let end = results[1].range.location
                let translatedText = trans.substringWithRange(NSRange(location: start, length: end - start))
                let translation = Translation(detectedLang: "", translation: translatedText)
                return Observable.just(translation)
            }
        }
        return Observable.error(Error.Serialization)
    }

}
