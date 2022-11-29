/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Main view controller for the AR experience.
 
Source:
 https://developer.apple.com/documentation/arkit/content_anchors/tracking_and_visualizing_planes
*/

import UIKit
import SceneKit
import ARKit

class EnvironmentReaderViewController: UIViewController, ARSCNViewDelegate, ARSessionDelegate {
    // MARK: - IBOutlets
    
    var sceneView = ARSCNView()
    var initializeButton = UIButton()
    var soundManager = SoundManager()
    var healthKitManager = HealthKitManager()
    
    private var planes = [UUID: Plane]()
    private var anchors = [UUID: ARAnchor]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.addSubview(sceneView)
        self.view.addSubview(initializeButton)
        
        createInitializeButton()
        addConstraints()
        
        sceneView.delegate = self
    }
    
    // MARK: - View Life Cycle

    /// - Tag: StartARSession
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        // Start the view's AR session with a configuration that uses the rear camera,
        // device position and orientation tracking, and plane detection.
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.vertical]
        configuration.isAutoFocusEnabled = true
        self.sceneView.session.run(configuration)

        // Set a delegate to track the number of plane anchors for providing UI feedback.
        self.sceneView.session.delegate = self
        
        // Prevent the screen from being dimmed after a while as users will likely
        // have long periods of interaction without touching the screen or buttons.
        UIApplication.shared.isIdleTimerDisabled = true
        
        // Show debug UI to view performance metrics (e.g. frames per second).
        self.sceneView.showsStatistics = true
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        // Pause the view's AR session.
        self.sceneView.session.pause()
        self.anchors.removeAll()
        self.planes.removeAll()
    }

    // MARK: - ARSCNViewDelegate
    
    /// - Tag: PlaceARContent
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        // Place content only for anchors found by plane detection.
        guard let planeAnchor = anchor as? ARPlaneAnchor else { return }
        
        if planeAnchor.classification.description != ARPlaneAnchor.Classification.door.description {
            return
        }
        
        if !self.planes.isEmpty || !self.anchors.isEmpty { return }
        
        // Create a custom object to visualize the plane geometry and extent.
        let plane = Plane(anchor: planeAnchor, in: self.sceneView)
        
        self.planes[anchor.identifier] = plane
        self.anchors[anchor.identifier] = anchor
        
        // Add the visualization to the ARKit-managed node so that it tracks
        // changes in the plane anchor as plane estimation continues.
        node.addChildNode(plane)
    }

    /// - Tag: UpdateARContent
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        // Update only anchors and nodes set up by `renderer(_:didAdd:for:)`.
        guard let planeAnchor = anchor as? ARPlaneAnchor,
            let plane = node.childNodes.first as? Plane
            else { return }
        
        if planeAnchor.classification.description != ARPlaneAnchor.Classification.door.description
        { return }
        
        // Update ARSCNPlaneGeometry to the anchor's new estimated shape.
        if let planeGeometry = plane.meshNode.geometry as? ARSCNPlaneGeometry {
            planeGeometry.update(from: planeAnchor.geometry)
        }

        // Update extent visualization to the anchor's new bounding rectangle.
        if let extentGeometry = plane.extentNode.geometry as? SCNPlane {
            extentGeometry.width = CGFloat(planeAnchor.planeExtent.width)
            extentGeometry.height = CGFloat(planeAnchor.planeExtent.height)
            plane.extentNode.simdPosition = planeAnchor.center
        }
        
        // Update the plane's distance and the text position
        if let distanceNode = plane.distanceNode,
           let distanceGeometry = distanceNode.geometry as? SCNText {
            let currentDistance = simd_distance(node.simdTransform.columns.3, (sceneView.session.currentFrame?.camera.transform.columns.3)!)
            let currentSteps = healthKitManager.calToStepCount(meter: Double(currentDistance))
            // print(currentDistance)
            if let oldSteps = distanceGeometry.string as? String, oldSteps != String(currentSteps) {
                distanceGeometry.string = String(currentSteps)
                
                if let pointOfView = sceneView.pointOfView {
                    // 화면상에 문이 보이지 않는 경우 TTS를 출력하지 않습니다.
                    let isMaybeVisible = renderer.isNode(plane.presentation, insideFrustumOf: pointOfView)
                    if(isMaybeVisible) {
                        switch currentSteps
                        {
                        case 0:
                            soundManager.speak("근처에 문이 있습니다")
                        default:
                            soundManager.speak("문으로 부터 약 \(currentSteps) 걸음 떨어져 있습니다")
                        }
                    }
                }
                distanceNode.centerAlign()
            }
        }
    }

    // MARK: - ARSessionDelegate

    func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
        guard let frame = session.currentFrame else { return }
        updateSessionInfoAndSpeak(for: frame, trackingState: frame.camera.trackingState)
    }

    func session(_ session: ARSession, didRemove anchors: [ARAnchor]) {
        guard let frame = session.currentFrame else { return }
        updateSessionInfoAndSpeak(for: frame, trackingState: frame.camera.trackingState)
    }

    func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
        updateSessionInfoAndSpeak(for: session.currentFrame!, trackingState: camera.trackingState)
    }

    // MARK: - ARSessionObserver

    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay.
        print("Session was interrupted")
    }

    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required.
        print("Session interruption ended")
        resetTracking()
    }
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        print("Session failed: \(error.localizedDescription)")
        guard error is ARError else { return }
        
        let errorWithInfo = error as NSError
        let messages = [
            errorWithInfo.localizedDescription,
            errorWithInfo.localizedFailureReason,
            errorWithInfo.localizedRecoverySuggestion
        ]
        
        // Remove optional error messages.
        let errorMessage = messages.compactMap({ $0 }).joined(separator: "\n")
        
        DispatchQueue.main.async {
            // Present an alert informing about the error that has occurred.
            let alertController = UIAlertController(title: "The AR session failed.", message: errorMessage, preferredStyle: .alert)
            let restartAction = UIAlertAction(title: "Restart Session", style: .default) { _ in
                alertController.dismiss(animated: true, completion: nil)
                self.resetTracking()
            }
            alertController.addAction(restartAction)
            self.present(alertController, animated: true, completion: nil)
        }
    }

    // MARK: - Private methods

    private func updateSessionInfoAndSpeak(for frame: ARFrame, trackingState: ARCamera.TrackingState) {
        // Update the UI to provide feedback on the state of the AR experience.
        let message: String

        switch trackingState {
        case .normal where frame.anchors.isEmpty:
            // No planes detected; provide instructions for this app's AR interactions.
            message = "스마트폰을 좌우, 위아래로 천천히 움직여주세요."
            
        case .notAvailable:
            message = "환경 인식 기능에 문제가 발생했습니다."
            
        case .limited(.excessiveMotion):
            message = "디바이스를 천천히 움직여주세요."
            
        case .limited(.insufficientFeatures):
            message = "환경 인식을 할 수 없습니다."
            
        case .limited(.initializing):
            message = "환경 인식 기능을 초기화 중입니다."
            
        default:
            // No feedback needed when tracking is normal and planes are visible.
            // (Nor when in unreachable limited-tracking states.)
            message = ""

        }
        if message != "" {
            soundManager.speak(message)
        }
    }
/*
    private func resetTracking() {
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.vertical]
        self.planes.removeAll()
        self.anchors.removeAll()
        self.sceneView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
    }
 */
    
    func createInitializeButton() {
        initializeButton.addTarget(self, action: #selector(resetTracking), for: .touchUpInside)
        initializeButton.setTitle("문 인식 초기화", for: .normal)
        initializeButton.setTitle("", for: .selected)
    }
    
    func addConstraints() {
        
        sceneView.translatesAutoresizingMaskIntoConstraints = false
        initializeButton.translatesAutoresizingMaskIntoConstraints = false
        
        sceneView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor).isActive = true
        sceneView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor).isActive = true
        sceneView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor).isActive = true
        sceneView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor).isActive = true
        
        initializeButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor).isActive = true
        initializeButton.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor).isActive = true
        initializeButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor).isActive = true
        initializeButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor).isActive = true
        
        sceneView.subviews.forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
        }
    }
    
    @objc private func resetTracking() {
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.vertical]
        self.planes.removeAll()
        self.anchors.removeAll()
        self.sceneView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
    }
}
