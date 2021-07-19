//
//  ContentView.swift
//  Shared
//
//  Created by 朱睿 on 2020/12/11.
//

import SwiftUI

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

class SurdusDecoder : ObservableObject {
    @Published var decodedString : String = ""
    var capturer = SDAudioCapturer(sampleRate: 96000)
    var analytics = SDAudioAnalytics(sampleRate: 96000)
    var audioDataBuffer: [Float] = []
    var advdec = SDAdvancedDecoder()
    var utf8Buffer: [UInt8] = []
    var audioWindowSize : Double = 4096.0
    var isWorking : Bool = false {
        didSet {
            if isWorking {
                capturer.start()
            } else {
                capturer.stop()
            }
            print("Toggled Run.")
        }
    }
    
    init(){
        capturer.audioDataHandle = { (data: [Float], count: Int) in
            self.analytics.batchFeed([Float](data[0..<count]))
        }
        
        analytics.updateHandle = {
            self.advdec.update(anal: $0)
        }
        
        advdec.newFrameHandle = { (data, is16bit) in
            if data != 0 {
                self.utf8Buffer.append(UInt8((data & 0xFF00) >> 8))
                self.utf8Buffer.append(UInt8((data & 0x00FF) >> 0))
            }
            DispatchQueue.main.async {
                if let str = NSString(bytes: &self.utf8Buffer, length: self.utf8Buffer.count, encoding: String.Encoding.utf8.rawValue) {
                    self.decodedString = str as String
                    print(self.decodedString)
                }
            }
        }
    }
}

struct ContentView: View {
    @ObservedObject var surdusDecoder = SurdusDecoder()
    @State private var isWorking : Bool = false
    
    init(){
        #if os(iOS)
        UITextView.appearance().backgroundColor = .clear
        #endif
    }
    
    var body: some View {
        VStack{
            Text("Surdus Decoder")
                .font(.largeTitle)
                .fontWeight(.semibold)
                .padding()
            
            Spacer()
            
            ZStack(alignment: .topLeading){
                #if os(iOS)
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Color(UIColor.secondarySystemBackground))
                #else
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Color(NSColor.windowBackgroundColor))
                #endif
                
                #if os(iOS)
                ScrollView {
                    Text(surdusDecoder.decodedString)
                        .font(.title2)
                        .padding(8)
                }.padding()
                #else
                ScrollView {
                    Text(surdusDecoder.decodedString)
                        .font(.title2)
                        .padding(8)
                }.padding()
                #endif
                
                if surdusDecoder.decodedString.isEmpty {
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
                Button(action: onClear) {
                    Text("Clear")
                }
                .padding()
                
                Spacer()
                #if os(iOS)
                HStack{
                    Text("Run")
                    Toggle("Run", isOn: $isWorking.didSet {_ in
                        surdusDecoder.isWorking = isWorking
                        print("Toggled Run.")
                    }).labelsHidden()
                }.padding(.horizontal)
                
                #else
                Toggle("Run", isOn: $isWorking.didSet {_ in
                    surdusDecoder.isWorking = isWorking
                    print("Toggled Run.")
                })
                .toggleStyle(SwitchToggleStyle())
                .padding(.horizontal)
                #endif
            }
        }
        .padding()
    }
    
    func onClear(){
        surdusDecoder.decodedString = ""
        surdusDecoder.utf8Buffer.removeAll()
        print("Clear.")
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
