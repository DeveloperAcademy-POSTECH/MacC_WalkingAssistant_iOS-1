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
    //var healthKitManager = HealthKitManager()

    // Node의 위치를 구분하기 위해 화면의 크기를 가져옵니다.
    var sceneWidth:CGFloat = 0

    // 방향에 대한 안내를 할 경우, TTS 출돌 현상을 방지하기 위해 Flag를 만들었습니다.
    var alreadySpoke = false

    // 하나의 문만 인식하고 안내하기 위해 plane과 anchor를 담는 array
    private var planes = [UUID: Plane]()
    private var anchors = [UUID: ARAnchor]()

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.addSubview(sceneView)
        self.view.addSubview(initializeButton)

        createInitializeButton()
        addConstraints()

        sceneView.delegate = self
        let environmentReaderRotor = self.environmentReaderRotor()
        self.accessibilityCustomRotors = [environmentReaderRotor]
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

        self.sceneWidth = self.sceneView.frame.width
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

        if let pointOfView = sceneView.pointOfView {
            // 화면상에 문이 보이지 않는 경우 방향을 안내압니다.
            let isMaybeVisible = renderer.isNode(plane.presentation, insideFrustumOf: pointOfView)
            if (!isMaybeVisible) {
                getIfHeIsLookingNew(sceneWidth: sceneWidth, nodePosition: self.sceneView.projectPoint(plane.position))
                return
            } else {
                if alreadySpoke {
                    soundManager.speak(translate("문이 다시 감지되었습니다"))
                    alreadySpoke = false
                }
            }
        }

        // Update the plane's distance and the text position
        if let distanceNode = plane.distanceNode,
           let distanceGeometry = distanceNode.geometry as? SCNText {
            let currentDistance = simd_distance(node.simdTransform.columns.3, (sceneView.session.currentFrame?.camera.transform.columns.3)!)
            //var currentSteps = healthKitManager.calToStepCount(meter: Double(currentDistance))
            var currentSteps = Int(Double(currentDistance)/0.7)
            if (currentSteps > 10) { currentSteps = 10 }
            if let oldSteps = distanceGeometry.string as? String, oldSteps != String(currentSteps) {
                distanceGeometry.string = String(currentSteps)

                if let pointOfView = sceneView.pointOfView {
                    // 화면상에 문이 보이지 않는 경우 TTS를 출력하지 않습니다.
                    let isMaybeVisible = renderer.isNode(plane.presentation, insideFrustumOf: pointOfView)

                    if (isMaybeVisible) {
                        var stringToSpeak = ""
                        switch currentSteps
                        {
                        case 0:
                            stringToSpeak = "근처에 문이 있습니다"
                        case 1:
                            stringToSpeak = "문으로부터 약 한 걸음 떨어져 있습니다"
                        case 2:
                            stringToSpeak = "문으로부터 약 두 걸음 떨어져 있습니다"
                        case 3:
                            stringToSpeak = "문으로부터 약 세 걸음 떨어져 있습니다"
                        case 4:
                            stringToSpeak = "문으로부터 약 네 걸음 떨어져 있습니다"
                        case 5:
                            stringToSpeak = "문으로부터 약 다섯 걸음 떨어져 있습니다"
                        case 6:
                            stringToSpeak = "문으로부터 약 여섯 걸음 떨어져 있습니다"
                        case 7:
                            stringToSpeak = "문으로부터 약 일곱 걸음 떨어져 있습니다"
                        case 8:
                            stringToSpeak = "문으로부터 약 여덟 걸음 떨어져 있습니다"
                        case 9:
                            stringToSpeak = "문으로부터 약 아홉 걸음 떨어져 있습니다"
                        default:
                            stringToSpeak = "문으로부터 멀리 떨어져 있습니다. 화면을 눌러 인식을 초기화 해주세요"
                        }
                        if stringToSpeak != "" {
                            soundManager.speak(translate(stringToSpeak))
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

    private func environmentReaderRotor () -> UIAccessibilityCustomRotor {
        // Create a custor Rotor option, it has a name that will be read by voice over, and
        // a action that is a action called when this rotor option is interacted with.
        // The predicate gives you info about the state of this interaction
        let propertyRotor = UIAccessibilityCustomRotor.init(name: "메인 화면으로") { (predicate) -> UIAccessibilityCustomRotorItemResult? in

            // Get the direction of the movement when this rotor option is enablade
            let forward = predicate.searchDirection == UIAccessibilityCustomRotor.Direction.next

            // You can do any kind of business logic processing here
            if forward {
                // 홈 화면으로 돌아감
                self.dismiss(animated: true)
            }
            // Return the selection of voice over to the element rotorPropertyValueLabel
            // Use this return to select the desired selection that fills the purpose of its logic
            return UIAccessibilityCustomRotorItemResult.init()
        }
        return propertyRotor
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
            soundManager.speak(translate(message))
        }
    }

    func createInitializeButton() {
        initializeButton.addTarget(self, action: #selector(resetTracking), for: .touchUpInside)
        initializeButton.setTitle(Language(rawValue: "Reset door recognition")?.localized, for: .normal)
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

    // source: https://stackoverflow.com/questions/41579755/how-to-determine-if-an-scnnode-is-left-or-right-of-the-view-direction-of-a-camer
    func getIfHeIsLookingNew(sceneWidth: CGFloat, nodePosition: SCNVector3) {
        if alreadySpoke {
            return
        }
        if (nodePosition.z < 1) {
            if ( nodePosition.x > (Float(sceneWidth)) ) {
                soundManager.speak(translate("문이 오른쪽에 있습니다"))
            } else if (nodePosition.x < 0) {
                soundManager.speak(translate("문이 왼쪽에 있습니다"))
            }
        } else if (nodePosition.x < 0) {
            soundManager.speak(translate("문이 오른쪽에 있습니다"))
        } else {
            soundManager.speak(translate("문이 왼쪽에 있습니다"))
        }
        alreadySpoke = true
    }
}
