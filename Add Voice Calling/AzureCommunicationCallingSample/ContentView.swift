// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.

import SwiftUI
import AzureCommunicationCalling
import AVFoundation

struct ContentView: View {
    @State var callee: String = ""
    @State var status: String = ""
    @State var message: String = ""
    @State var callClient: CallClient?
    @State var callAgent: CallAgent?
    @State var call: Call?
    @State var callObserver: CallObserver?
    @State var deviceManager: DeviceManager?
    @State var callHandler: CallHandler?
    
    // items for incoming  call
  // @State var incomingCall: Call?
   // @State var incomingCallHandler: IncomingCallHandler?
    
    //end items for incoming call
    

    var body: some View {
        NavigationView {
            Form {
                Section {
                    TextField("Who would you like to call?", text: $callee)
                    Button(action: startCall) {
                        Text("Start Call")
                    }.disabled(callAgent == nil)
                    Button(action: endCall) {
                        Text("End Call")
                    }.disabled(call == nil)
                    Button(action: answerCall) {
                        Text("Answer Call")
                    }.disabled(callAgent == nil)
                    Text(status)
                    Text(message)
                }
            }
            .navigationBarTitle("Calling Quickstart")
        }.onAppear {
//Create a usercredential object to store the user token

           var userCredential: CommunicationTokenCredential?
            do {
                userCredential = try CommunicationTokenCredential(token: "<YOUR ACS TOKEN FOR USER 2>")
            } catch {
                print("ERROR: It was not possible to create user credential.")
                self.message = "Please enter your token in source code"
                return
            }
            
                     
 //Initialize the callclient which allows you to call the method to  create a call agent using the user token
            self.callClient = CallClient()

// Creates the call agent
            self.callClient?.createCallAgent(userCredential: userCredential) { (agent, error) in
                if error == nil {
                    guard let agent = agent else {
                        self.message = "Failed to create CallAgent"
                        return
                    }
                    
                    self.callAgent = agent
                    self.callHandler = CallHandler(self)
                    callAgent?.delegate = self.callHandler
                    self.message = "Call agent successfully created."
                } else {
                    self.message = "Failed to create CallAgent with error"
                }
            }
            
            
     }
    }
    
 //Use the callAgent to start a call using the startCall method which creates a "call" which adds it to the call list
    func startCall() {
// Ask for audio/microphone access permissions
        AVAudioSession.sharedInstance().requestRecordPermission { (granted) in
            if granted {
                let callees:[CommunicationIdentifier] = [CommunicationUserIdentifier(identifier: self.callee)]

                guard let call = self.callAgent?.call(participants: callees, options: nil) else {
                    self.message = "Failed to place outgoing call"
                    return
                }

                self.call = call
                self.callObserver = CallObserver(self)
                self.call!.delegate = self.callObserver
                self.message = "Outgoing call placed successfully"
               
            }
        }
    }

    
    //Use the callAgent to end a call using the startCall method which creates a "call" which removes it from the call list
    func endCall() {
        if let call = call {
            call.hangup(options: nil, completionHandler: { (error) in
                if error == nil {
                    self.message = "Hangup was successfull"
                } else {
                    self.message = "Hangup failed"
                }
            })
        } else {
            self.message = "No active call to hangup"
        }
    }
  
    
   
    //Introducing the callHandler or call delegate who is listening to events
    //Incoming call triggers the callHandler
    func answerCall() {
        AVAudioSession.sharedInstance().requestRecordPermission { (granted) in
        if granted {
            if let call = self.callHandler?.incomingCall {
            let acceptCallOptions = AcceptCallOptions()
             
           call.accept(options: acceptCallOptions) { (error) in
                       if error == nil {
                        self.call = call
                        self.callObserver = CallObserver(self)
                        self.call!.delegate = self.callObserver
                        self.message = "Incoming call accepted"
                       } else {
                        self.message = "Failed to accept incoming call"
                       }
                   }
        
        } else {
            self.message = "No incoming call found to accept"
        }
        }
        else {
            self.message = "Call Permissions not granted, chancge in settings or reset applicatioon"
        }
        }

    }
    
}

class CallObserver : NSObject, CallDelegate {
    private var owner:ContentView
    init(_ view:ContentView) {
        owner = view
    }

    public func onCallStateChanged(_ call: Call!,
                                   args: PropertyChangedEventArgs!) {
        owner.status = CallObserver.callStateToString(state: call.state)
        if call.state == .disconnected {
            owner.call = nil
            owner.message = "Call ended"
        } else if call.state == .connected {
            owner.message = "Call connected !!"
        }
    }

    private static func callStateToString(state: CallState) -> String {
        switch state {
        case .connected: return "Connected"
        case .connecting: return "Connecting"
        case .disconnected: return "Disconnected"
        case .disconnecting: return "Disconnecting"
        case .earlyMedia: return "EarlyMedia"
        case .hold: return "Hold"
        case .incoming: return "Incoming"
        case .none: return "None"
        case .ringing: return "Ringing"
        default: return "Unknown"
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

//See Accept an incoming call from Quickstart for source
    
final class CallHandler: NSObject, CallAgentDelegate{
    //customer variable to give the CallHandler access to the ContentView
    private var owner:ContentView
    init(_ view:ContentView) {
        owner = view
    }
    public var incomingCall: Call?
 
    public func onCallsUpdated(_ callAgent: CallAgent!, args: CallsUpdatedEventArgs!) {
        if let incomingCall = args.addedCalls?.first(where: { $0.isIncoming }) {
            self.incomingCall = incomingCall
            
            //should  create  push notification toaster  pop  here  but  for  now  accept  call
            owner.status = "Incoming";
            owner.message = "Incoming Call: Please Answer"
            
        }
    }
}

