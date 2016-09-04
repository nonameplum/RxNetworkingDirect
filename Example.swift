//
//  MainViewModel.swift
//  TranslateEverywhere
//
//  Created by Macbook on 19/06/16.
//  Copyright © 2016 Plum's organization. All rights reserved.
//

import Foundation
import RxSwift

BingTranslationClient.sharedClient
    .rx_mappedRequest(BingTranslationEndpoint(text: sourceText, from: fromLangAuto, to: toLang))
    .subscribeNext { [weak self] (translation) in
        guard let strongSelf = self, translatedText = translation.translation else { return }

        strongSelf.translatedText = translatedText
        if let detectedLang = translation.detectedLang {
            strongSelf.fromLang = detectedLang
        }

        strongSelf.delegate?.textTranslated(strongSelf.fromLang, toLang: strongSelf.toLang, fromText: strongSelf.sourceText, toText: strongSelf.translatedText)
    }
    .addDisposableTo(disposeBag)
