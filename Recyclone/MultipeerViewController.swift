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

extension MultipeerViewController: MCNearbyServiceBrowserDelegate {

    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {
        print("browser delegate called")
        var runningTime = timeStarted.timeIntervalSince(Date())
        let context = Data(bytes: &runningTime, count: MemoryLayout<TimeInterval>.size)
        print(runningTime)
        browser.invitePeer(peerID, to: self.mcSession!, withContext: context, timeout: 30)
        
    }
    
    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        print("lost connection to peer")
    }
    
    
    func browser(_ browser: MCNearbyServiceBrowser, didNotStartBrowsingForPeers error: Error) {
        print("error occured while attempting to start browsing")
    }
}

extension MultipeerViewController: MCNearbyServiceAdvertiserDelegate {
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        print("advertiser delegate called")
        let runningTime = timeStarted.timeIntervalSince(Date())
        let peerRunningTime = TimeInterval([UInt8](context!))
        
        let isPeerOlder = (peerRunningTime > runningTime)
        print(isPeerOlder)
        invitationHandler(isPeerOlder, self.mcSession)
        if isPeerOlder {
            advertiser.stopAdvertisingPeer()
        }
    }
}

class MultipeerViewController: UICollectionViewController, MCSessionDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, MCBrowserViewControllerDelegate {
    
//    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
//        invitationHandler(true, mcSession)
//    }
    
    var images = [UIImage]()
    var peerID = MCPeerID(displayName: UIDevice.current.name)
    var mcSession: MCSession?
    var mcBrowser: MCNearbyServiceBrowser!
    var mcNearbyServiceAdvertiser: MCNearbyServiceAdvertiser!
    
    override func viewDidLoad() {
        
        super.viewDidLoad()

        self.navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .refresh, target: self, action: #selector(retryConnection))
        title = "Selfie Share"
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .camera, target: self, action: #selector(importPicture))
        // because we used custom nav bar items, we need to force the back button to appear
        self.navigationItem.leftItemsSupplementBackButton = true;
        
        mcSession = MCSession(peer: self.peerID, securityIdentity: nil, encryptionPreference: .required)
        mcSession?.delegate = self
        
    }
    
    @objc func retryConnection(alert: UIAlertAction) {
        startHosting()
        joinSession()
    }
    func startHosting() {
        print("started hosting")
        mcNearbyServiceAdvertiser = MCNearbyServiceAdvertiser(peer: self.peerID, discoveryInfo: nil, serviceType: "recyclone")
        mcNearbyServiceAdvertiser.delegate = self
        mcNearbyServiceAdvertiser.startAdvertisingPeer()
    }

    func joinSession() {
        //guard let mcSession = mcSession else { return }
        mcBrowser = MCNearbyServiceBrowser(peer: self.peerID, serviceType: "recyclone")
        mcBrowser.delegate = self
        mcBrowser.startBrowsingForPeers()
        //let mcBrowserVC = MCBrowserViewController(browser: mcBrowser, session: mcSession)
        //mcBrowserVC.browser!.delegate = self
        //mcBrowserVC.browser!.startBrowsingForPeers()
        print("started browsing")

        //present(mcBrowser, animated: true)
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return images.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ImageView", for: indexPath)

        if let imageView = cell.viewWithTag(1000) as? UIImageView {
            imageView.image = images[indexPath.item]
        }

        return cell
    }
    
    @objc func importPicture() {
        let picker = UIImagePickerController()
        picker.allowsEditing = true
        picker.delegate = self
        present(picker, animated: true)
    }

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        guard let image = info[.editedImage] as? UIImage else { return }

        dismiss(animated: true)

        images.insert(image, at: 0)
        collectionView.reloadData()
        // 1
        guard let mcSession = mcSession else { return }

        // 2
        if mcSession.connectedPeers.count > 0 {
            // 3
            if let imageData = image.pngData() {
                // 4
                do {
                    try mcSession.send(imageData, toPeers: mcSession.connectedPeers, with: .reliable)
                } catch {
                    // 5
                    let ac = UIAlertController(title: "Send error", message: error.localizedDescription, preferredStyle: .alert)
                    ac.addAction(UIAlertAction(title: "OK", style: .default))
                    present(ac, animated: true)
                }
            }
        }
    }
    
    
//    @objc func showConnectionPrompt() {
//        let ac = UIAlertController(title: "Connect to others", message: nil, preferredStyle: .alert)
//        ac.addAction(UIAlertAction(title: "Host a session", style: .default, handler: startHosting))
//        ac.addAction(UIAlertAction(title: "Join a session", style: .default, handler: joinSession))
//        ac.addAction(UIAlertAction(title: "Cancel", style: .cancel))
//        present(ac, animated: true)
//    }
    
    
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        DispatchQueue.main.async { [weak self] in
            if let image = UIImage(data: data) {
                self?.images.insert(image, at: 0)
                self?.collectionView.reloadData()
            }
        }
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
    
    override func viewWillAppear(_ animated: Bool) {
        // display the nav bar when we go to the multipeer view
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }
    
    func browserViewControllerDidFinish(_ browserViewController: MCBrowserViewController) {
        dismiss(animated: true)
    }

    func browserViewControllerWasCancelled(_ browserViewController: MCBrowserViewController) {
        dismiss(animated: true)
    }
    
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {

    }

    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {

    }

    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {

    }
}
