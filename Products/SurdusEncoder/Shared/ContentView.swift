//
//  ContentView.swift
//  Shared
//
//  Created by 朱睿 on 2020/12/11.
//

import SwiftUI
import Foundation
import AVFoundation

extension Binding {
    func didSet(execute: @escaping (Value) -> Void) -> Binding {
        return Binding(
            get: {
                return self.wrappedValue
            },
            set: {
                self.wrappedValue = $0
                execute($0)
            }
        )
    }
}

struct ContentView: View {
    var numFormatter : NumberFormatter = NumberFormatter()
    var advEncoder : SEAdvancedEncoder = SEAdvancedEncoder()
    
    @State private var toEncode: String = ""
    @State private var rateBps : Double = 640
    @State private var slidePercent : Double = 41.9
    @State private var minRate : Double = 20
    @State private var maxRate : Double = 1500
    @State private var usePhase : Bool = true
    
    init() {
        #if os(iOS)
        UITextView.appearance().backgroundColor = .clear
        #endif
        advEncoder.transmitRateBPS = (640, true)
    }
    
    var body: some View {
        VStack{
            Text("Surdus Encoder")
                .font(.largeTitle)
                .fontWeight(.semibold)
                .padding()
            
            Spacer()
            
            ZStack(alignment: .topLeading){
                #if os(iOS)
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Color(UIColor.secondarySystemBackground))
//                #else
//                RoundedRectangle(cornerRadius: 8, style: .continuous)
//                    .fill(Color(NSColor.windowBackgroundColor))
                #endif
                
                #if os(iOS)
                TextEditor(text: $toEncode)
                    .disableAutocorrection(true)
                    .font(.title2)
                    .padding(8)
                #else
                TextEditor(text: $toEncode)
                    .disableAutocorrection(true)
                    .font(.title2)
                    .padding(8)
                #endif
                
                if toEncode.isEmpty {
                    #if os(iOS)
                    Text("Hello 🐲!")
                        .font(.title2)
                        .foregroundColor(Color(UIColor.placeholderText))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 16)
                    #else
                    Text("Hello 🐲!")
                        .font(.title2)
                        .foregroundColor(Color(NSColor.placeholderTextColor))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                    #endif
                }
            }

            Spacer()
            
            HStack{
                VStack{
                    HStack{
                        Text("Transmission Rate (bps)")
                            .padding(.leading)
                        
                        Slider(value: $slidePercent,
                               in: (0 ... 100),
                               onEditingChanged: {_ in
                                rateBps = slidePercent * (maxRate - minRate) / 100 + minRate
                                advEncoder.transmitRateBPS = (rateBps, usePhase)
                                print("SetBps")
                               }
                        )
                        .padding(.leading)

                        TextField(
                            "240.0",
                            value: $rateBps,
                            formatter: numFormatter,
                            onCommit: {
                                slidePercent = (rateBps - minRate) / (maxRate - minRate) * 100
                                advEncoder.transmitRateBPS = (rateBps, usePhase)
                                print("SetBps")
                            }
                        )
                        .frame(width: 45.0)
                        .disableAutocorrection(true)
                        .padding(.trailing)
                        
                        Spacer()
                    }
                    HStack{
                        Toggle("Use Phase Modulation", isOn: $usePhase.didSet {_ in
                            updateRate()
                            print("SetUsePhase")
                        })
                        .toggleStyle(SwitchToggleStyle())
                        .padding(.horizontal)
                        Spacer()
                    }
                }
                Spacer()
                Button(action: onPlay) {
                    Text("Play")
                }
                .padding()
            }
        }
        .padding()
    }
    
    func encodeMessage(){
        let message = toEncode
        
        advEncoder.clearData()
        var currWord: UInt16 = 0
        
        for i in stride(from: 0, to: message.lengthOfBytes(using: .utf8), by: 2) {
            if i == message.lengthOfBytes(using: .utf8) - 1 {
                currWord = UInt16(message.utf8[message.utf8.index(message.utf8.startIndex, offsetBy: i)]) << 8
            } else {
                currWord = UInt16(message.utf8[message.utf8.index(message.utf8.startIndex, offsetBy: i)]) << 8
                currWord += UInt16(message.utf8[message.utf8.index(message.utf8.startIndex, offsetBy: i+1)])
            }
            advEncoder.addData(of16Bit: currWord)
        }
    }
    
    func onPlay(){
        encodeMessage()
        if let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).last{
            let fileURL = dir.appendingPathComponent("temp.wav")
            print(fileURL)
            do {
                if try fileURL.checkResourceIsReachable() {
                    print("file exist")
                } else {
                    print("file doesnt exist")
                    do {
                        try Data().write(to: fileURL)
                    } catch {
                        print("an error happened while creating the file")
                    }
                }
            } catch {
                print("an error happened while checking for the file")
            }
            let _ = advEncoder.save(toFile: fileURL)
            Sound.playSounds(path: fileURL)
        }
    }
    
    
    func updateRate(){
        if usePhase {
            maxRate = 1500
        } else {
            maxRate = 600
        }
        rateBps = slidePercent * (maxRate - minRate) / 100 + minRate
        rateBps = min(maxRate, rateBps)
        advEncoder.transmitRateBPS = (rateBps, usePhase)
        print("SetBps")
    }
    
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
