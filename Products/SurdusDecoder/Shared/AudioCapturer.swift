//
//  AudioCapturer.swift
//  SurdusDecoder
//
//  Created by 朱睿 on 2020/12/12.
//

import Foundation
import AVFoundation

class SDAudioCapturer : NSObject, AVCaptureAudioDataOutputSampleBufferDelegate {
    
    let capSession = AVCaptureSession()
    
    let dispatchQueue = DispatchQueue(label: "com.Candida.ASAudioCapturer", qos: .userInteractive)
    
    var audioDataHandle : (([Float], Int) -> Void)? = nil
    
    var sampleRate = 96400.0
    
    init(sampleRate: Double = 96000.0) {
        super.init()
        // AVCaptureAudioDataOutput @ iPhone12 Pro (iOS14.2) is default linearPCM_Int16@44100Hz.
        // May not compatible with other devices.
        // TODO: Auto get&set sampleRate
        #if os(iOS)
        self.sampleRate = 44100
        #else
        self.sampleRate = sampleRate
        #endif
        configureCaptureSession()
    }
    
    func configureCaptureSession() {
        capSession.beginConfiguration()

        // Configure the input device
        let audioDev = AVCaptureDevice.default(for: .audio)!
        let audioInput = try! AVCaptureDeviceInput(device: audioDev)

        if(capSession.canAddInput(audioInput)) {
            capSession.addInput(audioInput)
        }
        
        // Configure the output
        let dataOutput = AVCaptureAudioDataOutput()
        #if os(macOS)
        dataOutput.audioSettings = [
            AVSampleRateKey : NSNumber(floatLiteral: sampleRate),   // Sample rate
            AVNumberOfChannelsKey : NSNumber(integerLiteral: 1),    // Channle number
            AVFormatIDKey : kAudioFormatLinearPCM,                  // Output format

            AVLinearPCMBitDepthKey : NSNumber(integerLiteral: 32),  // Bit depth
            AVLinearPCMIsBigEndianKey : false,                      // Endian
            AVLinearPCMIsFloatKey : true,                           // Float data
            AVLinearPCMIsNonInterleaved : false,                    // Useless when only 1 channel
        ]
        #endif
        dataOutput.setSampleBufferDelegate(self, queue: dispatchQueue)

        if(capSession.canAddOutput(dataOutput)) {
            capSession.addOutput(dataOutput)
        }
        
        capSession.commitConfiguration()
    }
    
    // Delegate function, called when an audio buffer is generated
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        #if os(iOS)
        // dataBuffer for analytics
        var dataBufferInt16 = [Int16](repeating: 0, count: 8192)
        // Copy the raw PCM data
        CMBlockBufferCopyDataBytes(sampleBuffer.dataBuffer!, atOffset: sampleBuffer.dataBuffer!.startIndex, dataLength: sampleBuffer.dataBuffer!.dataLength, destination: UnsafeMutableRawPointer(&dataBufferInt16))
        // Call the data handle function
        dispatchQueue.async {
            self.audioDataHandle?(dataBufferInt16.map{ (int16) -> Float in
                return Float(int16) / 32768.0
            }, sampleBuffer.numSamples)
        }
        #elseif os(macOS)
        // dataBuffer for analytics
        var dataBuffer = [Float](repeating: 0, count: 8192)
        // Copy the raw PCM data
        CMBlockBufferCopyDataBytes(sampleBuffer.dataBuffer!, atOffset: sampleBuffer.dataBuffer!.startIndex, dataLength: sampleBuffer.dataBuffer!.dataLength, destination: UnsafeMutableRawPointer(&dataBuffer))
        // Call the data handle function
        dispatchQueue.async {
            self.audioDataHandle?(dataBuffer, sampleBuffer.numSamples)
        }
        #endif
        
    }
    
    func start() {
        capSession.startRunning()
    }
    
    func stop() {
        capSession.stopRunning()
    }
}
