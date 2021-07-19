//
//  AudioAnalytics.swift
//  SurdusDecoder
//
//  Created by 朱睿 on 2020/12/12.
//

import Foundation
import Accelerate

class SDAudioAnalytics {
    var anal = Analytics()
    
    var updateHandle : ((Analytics)->Void)? = nil
    
    init(sampleRate: Float) {
        // SampleRate @ iPhone12 Pro (iOS14.2) is default 44100Hz
        // May not compatible with other devices.
        // TODO: Auto get&set sampleRate
        #if os(iOS)
        AnalticsInit(&anal, 44100)
        #else
        AnalticsInit(&anal, sampleRate)
        #endif
    }
    
    func feed(_ sample: Float) {
        AnalticsPush(&anal, sample)
        if anal.updated == 1 {
            updateHandle?(anal)
            anal.updated = 0
        }
    }
    
    func batchFeed(_ samples: [Float]) {
        for x in samples {
            feed(x)
        }
    }
    
}
