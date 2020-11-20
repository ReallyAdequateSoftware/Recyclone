//
//  MultipeerViewController.swift
//  Recyclone
//
//  Created by Evan Huang on 11/17/20.
//

import Foundation
import UIKit
import MultipeerConnectivity
import SpriteKit

let timeStarted = Date()

extension Numeric {
    init<D: DataProtocol>(_ data: D) {
        var value: Self = .zero
        let size = withUnsafeMutableBytes(of: &value, { data.copyBytes(to: $0)} )
        assert(size == MemoryLayout.size(ofValue: value))
        self = value
    }
}

extension MultipeerWrangler: MCNearbyServiceBrowserDelegate {

    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {
        print("found peer \(peerID)")
        var runningTime = -timeStarted.timeIntervalSince(Date())
        let context = Data(bytes: &runningTime, count: MemoryLayout<TimeInterval>.size)
        browser.invitePeer(peerID, to: self.mcSession!, withContext: context, timeout: 30)
        
    }
    
    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        print("lost connection to peer \(peerID)")
    }
    
    
    func browser(_ browser: MCNearbyServiceBrowser, didNotStartBrowsingForPeers error: Error) {
        print("error occured while attempting to start browsing")
    }
}

extension MultipeerWrangler: MCNearbyServiceAdvertiserDelegate {
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        print("invitation received from \(peerID)")
        let runningTime = -timeStarted.timeIntervalSince(Date())
        let peerRunningTime = TimeInterval([UInt8](context!))
        
        let isPeerOlder = (peerRunningTime > runningTime)
        print("\(peerID.displayName) older than \(self.peerID.displayName) - \(isPeerOlder)" )
        invitationHandler(isPeerOlder, self.mcSession)
        if isPeerOlder {
            advertiser.stopAdvertisingPeer()
            self.mcNearbyServiceAdvertiser.stopAdvertisingPeer()
        }
    }
}

extension MultipeerWrangler: StreamDelegate {
    func stream(aStream: Stream, handleEvent eventCode: Stream.Event)
    {
        switch(eventCode)
        {
            case Stream.Event.hasBytesAvailable:
            print("--STREAM EVENT HAS BYTES--")
            let input = aStream as! InputStream
            var buffer = [UInt8](repeating: 0, count: 1024) //allocate a buffer. The size of the buffer will depended on the size of the data you are sending.
            let numberBytes = input.read(&buffer, maxLength:1024)
            let dataString = NSData(bytes: &buffer, length: numberBytes)
            let message = NSKeyedUnarchiver.unarchiveObject(with: dataString as Data) as! String //deserializing the NSData
            print("STREAM: ",message)


            case Stream.Event.hasSpaceAvailable:
                print("--STREAM EVENT HAS SPACE AVAILABLE--")
                break

            default:
                print("--STREAM EVENT DEFAULT--")
                break
        }
    }
}


class MultipeerWrangler: NSObject, MCSessionDelegate, UINavigationControllerDelegate {
    
    var peerID = MCPeerID(displayName: UIDevice.current.name)
    var mcSession: MCSession?
    var mcBrowser: MCNearbyServiceBrowser!
    var mcNearbyServiceAdvertiser: MCNearbyServiceAdvertiser!
    var gameScene: GameScene?
    var outputStream = OutputStream()
    var data: Data?
    
    override init() {
        super.init()
        
        mcSession = MCSession(peer: self.peerID, securityIdentity: nil, encryptionPreference: .required)
        mcSession?.delegate = self
        
    }
    
    func startHosting() {
        print("started hosting")
        mcNearbyServiceAdvertiser = MCNearbyServiceAdvertiser(peer: self.peerID, discoveryInfo: nil, serviceType: "recyclone")
        mcNearbyServiceAdvertiser.delegate = self
        mcNearbyServiceAdvertiser.startAdvertisingPeer()
    }

    func joinSession() {
        mcBrowser = MCNearbyServiceBrowser(peer: self.peerID, serviceType: "recyclone")
        mcBrowser.delegate = self
        mcBrowser.startBrowsingForPeers()
        print("started browsing")
    }
    
    func startStream(peer peerID: MCPeerID) {
        
        print("STARTING STREAM IN SESSION...")
        do
        {

           
            if let outputStream = try self.mcSession?.startStream(withName: "stream", toPeer: peerID)
            {
                print("OUTPUT STREAM IN STARTSESSION? ", outputStream)
                outputStream.delegate = self
                outputStream.schedule(in: RunLoop.main, forMode:RunLoop.Mode.default)
                outputStream.open()
                print("STREAM WITH PEER OPENED: ",peerID)
            }
        }
        catch let error {
            print("ERROR STARTING STREAM IN SESSION: \(error)")
        }
    }
    
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        self.data = data
        print("receieved data from \(peerID.displayName) \(String(data: data, encoding: .utf8))")
    }
    
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        switch state {
        case .connected:
            print("Connected: \(peerID.displayName)")

        case .connecting:
            print("Connecting: \(peerID.displayName)")

        case .notConnected:
            print("Not Connected: \(peerID.displayName)")

        @unknown default:
            print("Unknown state received: \(peerID.displayName)")
        }
    }
    
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
        if streamName == "stream" {
            stream.delegate = self
            stream.schedule(in: RunLoop.main, forMode: RunLoop.Mode.default)
            stream.open()
           
            print("STREAM OPENED: ",streamName)
        }
    }

    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {

    }

    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {

    }
}
