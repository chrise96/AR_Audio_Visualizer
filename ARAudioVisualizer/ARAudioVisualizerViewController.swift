//
//  ARAudioVisualizerViewController.swift
//  ARAudioVisualizer
//
//  Created by chrise96 on 20/12/2023.
//  Credits to JonathanRitchey03 for the 3D Audio Visualizer example.
//

import UIKit
import QuartzCore
import SceneKit
import ARKit

class ARAudioVisualizerViewController: UIViewController, ARSCNViewDelegate {
    
    @IBOutlet var sceneView: ARSCNView!
    
    // Array to store all placed assets on the scene
    var gridNode = SCNNode()
    var placedAssets: [SCNNode] = []
    var superpowered: Superpowered?
    let frequencyBands = FrequencyBands()
    var currentGridType: GridType = .spiral  // Initial grid type
    var useMic = true // Initial state

    enum GridType {
        case spiral
        case rectangle
    }
    
    // Add a background container view
    let backgroundContainer: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = UIColor(white: 0.7, alpha: 0.5)  // Gray background with transparency
        view.isUserInteractionEnabled = false  // Allow touches to pass through
        return view
    }()
    
    let visualizerLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Visualizer"
        label.textColor = .black
        label.font = UIFont.boldSystemFont(ofSize: 18)
        return label
    }()
    
    let clearButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.backgroundColor = UIColor(red: 0.18, green: 0.57, blue: 1.00, alpha: 1.00)
        button.layer.cornerRadius = 8
        button.setTitle("Clear", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        return button
    }()

    let switchButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.backgroundColor = UIColor(red: 0.18, green: 0.57, blue: 1.00, alpha: 1.00)
        button.layer.cornerRadius = 8
        button.setTitle("Switch", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        return button
    }()
    
    let toggleAudioButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.backgroundColor = UIColor(red: 0.18, green: 0.57, blue: 1.00, alpha: 1.00)
        button.layer.cornerRadius = 8
        button.setTitle("Use Song", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        return button
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Show feature points tracked by ARKit
        // sceneView.debugOptions = [ARSCNDebugOptions.showFeaturePoints]
        setupAudio()
        
        // Set the view's delegate
        sceneView.delegate = self
        
        // Add default lighting
        sceneView.autoenablesDefaultLighting = true
        
        // Add the background container view to the main view
        view.addSubview(backgroundContainer)
        // Add buttons to view
        view.addSubview(clearButton)
        view.addSubview(switchButton)
        view.addSubview(toggleAudioButton)

        setupBackground()
        setupButtons()
        
        frequencyBands.setup(view: view)
    }
    
    func setupAudio() {
        superpowered = Superpowered()
    }
    
    func renderFrame() {
        let frequencies = UnsafeMutablePointer<Float>.allocate(capacity: FREQ_BANDS)
        superpowered?.getFrequencies(frequencies)
        frequencyBands.render(frequencies, yPosition: view.frame.size.height - 40)
        
        // Make a copy of placedAssets to avoid concurrent modification
        let copiedPlacedAssets = placedAssets
        render(frequencies, frequencyBands: frequencyBands, copiedPlacedAssets: copiedPlacedAssets)
        
        frequencies.deallocate()
    }
    
    @objc func switchGrid() {
        // Toggle between spiral and rectangle grids
        currentGridType = (currentGridType == .spiral) ? .rectangle : .spiral
    }
    
    @objc func toggleAudio() {
        useMic = !useMic // Toggle the state

        if useMic {
            toggleAudioButton.setTitle("Use Song", for: .normal)
            // Add logic for using the microphone
        } else {
            toggleAudioButton.setTitle("Use Mic", for: .normal)
            // Add logic for using a song
            // TODO change the Superpowered.mm file to also read mp3 files in 
        }
    }
    
    func setupBackground() {
        // Layout constraints for the background container view
        backgroundContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        backgroundContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        backgroundContainer.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -view.safeAreaInsets.bottom).isActive = true
        backgroundContainer.heightAnchor.constraint(equalToConstant: 160).isActive = true

        // Add visualizer label to the background container
        backgroundContainer.addSubview(visualizerLabel)
        visualizerLabel.leadingAnchor.constraint(equalTo: backgroundContainer.leadingAnchor, constant: 20).isActive = true
        visualizerLabel.topAnchor.constraint(equalTo: backgroundContainer.topAnchor, constant: 20).isActive = true
    }

    func setupButtons() {
        let spacing: CGFloat = 15.0
        let buttonWidth: CGFloat = 105.0
        let buttonHeight: CGFloat = 40.0
        let bottomMargin: CGFloat = 60.0

        clearButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: spacing).isActive = true
        clearButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -view.safeAreaInsets.bottom - bottomMargin).isActive = true
        clearButton.widthAnchor.constraint(equalToConstant: buttonWidth).isActive = true
        clearButton.heightAnchor.constraint(equalToConstant: buttonHeight).isActive = true
        clearButton.addTarget(self, action: #selector(clearScene), for: .touchUpInside)

        switchButton.leadingAnchor.constraint(equalTo: clearButton.trailingAnchor, constant: spacing).isActive = true
        switchButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -view.safeAreaInsets.bottom - bottomMargin).isActive = true
        switchButton.widthAnchor.constraint(equalToConstant: buttonWidth).isActive = true
        switchButton.heightAnchor.constraint(equalToConstant: buttonHeight).isActive = true
        switchButton.addTarget(self, action: #selector(switchGrid), for: .touchUpInside)
        
        toggleAudioButton.leadingAnchor.constraint(equalTo: switchButton.trailingAnchor, constant: spacing).isActive = true
        toggleAudioButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -view.safeAreaInsets.bottom - bottomMargin).isActive = true
        toggleAudioButton.widthAnchor.constraint(equalToConstant: buttonWidth).isActive = true
        toggleAudioButton.heightAnchor.constraint(equalToConstant: buttonHeight).isActive = true
        toggleAudioButton.addTarget(self, action: #selector(toggleAudio), for: .touchUpInside)
    }
    
    // Remove placed assets
    @objc func clearScene() {
        // Remove the gridNode from the parent node
        gridNode.removeFromParentNode()
        
        if !placedAssets.isEmpty {
            for node in placedAssets {
                node.removeFromParentNode()
            }
            // Clear the placedAssets array
            placedAssets.removeAll()
        }
        
        // Create a new gridNode
        gridNode = SCNNode()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()
        
        // Set horizontal plane detection
        configuration.planeDetection = .horizontal

        // Run the view's session
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = touches.first {
            // Get touch location
            let touchLocation = touch.location(in: sceneView)
            
            // Creates a raycast query that originates from a point on the view, aligned with the center of the camera's field of view
            guard let query = sceneView.raycastQuery(from: touchLocation, allowing: .existingPlaneGeometry, alignment: .horizontal) else {
                print("Raycast query failed")
                return
            }
                    
            // Checks once for intersections between a ray and real-world surfaces.
            let raycastResults = sceneView.session.raycast(query)
            guard let result = raycastResults.first else {
               print("No surface found")
               return
            }

            // Remove any existing placed assets
            clearScene()

            // Configure the grid based on the current type
            switch currentGridType {
            case .spiral:
                createSpiralGrid(result.worldTransform)
            case .rectangle:
                createRectangleGrid(result.worldTransform)
            }
        }
    }
    
    func render(_ frequencies: UnsafeMutablePointer<Float>, frequencyBands: FrequencyBands, copiedPlacedAssets: [SCNNode]) {
        for n in 0..<FREQ_BANDS where n < copiedPlacedAssets.count {
            let amt = Float(frequencies[n] * 200)

            // Adjust the scale of the cube
            copiedPlacedAssets[n].scale = SCNVector3(1, amt, 1)

            // Adjust the y-position based on the audio data
            // copiedPlacedAssets[n].position.y = amt * scaleFactor

            // Adjust color based on audio volume and frequency bands
            let volume = frequencyBands.volumeInBand[n]
            let scaledVolume = volume * 0.8
            let newColor = UIColor(
                red: 0.2 + frequencyBands.colorByBandRed[n] * scaledVolume,
                green: 0.2 + frequencyBands.colorByBandGreen[n] * scaledVolume,
                blue: 0.2 + frequencyBands.colorByBandBlue[n] * scaledVolume,
                alpha: 1.0
            )

            // Apply the new color to the material of the cube
            copiedPlacedAssets[n].geometry?.materials.first?.diffuse.contents = newColor
            copiedPlacedAssets[n].geometry?.materials.first?.emission.contents = newColor
        }
    }
    
    func createSpiralGrid(_ transform: simd_float4x4) {
        let scaleFactor: Float = 0.005
        let radialSpacing: Float = 0.1

        for i in 0..<FREQ_BANDS {
            let radius = Float(i) * radialSpacing
            let height = Float(i) * radialSpacing

            // Create a cube node with the specified side length
            let cubeNode = createCube()

            gridNode.addChildNode(cubeNode)

            // Calculate the position for the spiral with adjusted scaleFactor
            let x = height * cos(radius)
            let z = height * sin(radius)

            // Set the position of the cube node based on the transform and adjusted scaleFactor
            let position = SCNVector3(
                x: transform.columns.3.x + Float(x) * scaleFactor,
                y: transform.columns.3.y, // y-coordinate, vertical position
                z: transform.columns.3.z + Float(z) * scaleFactor
            )
            
            cubeNode.position = position

            // Add the cube node to the gridNode and placedAssets array
            placedAssets.append(cubeNode)
        }

        // Add the gridNode to the scene
        sceneView.scene.rootNode.addChildNode(gridNode)
    }

    func createRectangleGrid(_ transform: simd_float4x4) {
        let gridWidth: Int = 32
        let gridHeight: Int = 40
        let spacing: Float = 0.03

        // Calculate the center position of the grid
        let centerX = Float(gridWidth - 1) * spacing / 2.0
        let centerZ = Float(gridHeight - 1) * spacing / 2.0

        for x in 0..<gridWidth {
            for z in 0..<gridHeight {
                // Create a cube node with the specified side length
                let cubeNode = createCube()

                gridNode.addChildNode(cubeNode)

                // Calculate the position for the grid with adjusted spacing
                let xPos = Float(x) * spacing - centerX
                let zPos = Float(z) * spacing - centerZ

                // Set the position of the cube node based on the transform and adjusted spacing
                let position = SCNVector3(
                    x: transform.columns.3.x + xPos,
                    y: transform.columns.3.y, // y-coordinate, vertical position
                    z: transform.columns.3.z + zPos
                )
                cubeNode.position = position

                // Add the cube node to the gridNode and placedAssets array
                placedAssets.append(cubeNode)
            }
        }

        // Add the gridNode to the scene
        sceneView.scene.rootNode.addChildNode(gridNode)
    }

    // Function to create a cube node with the specified side length
    func createCube(sideLength: CGFloat = 0.02) -> SCNNode {
        let geometry = SCNBox(width: sideLength, height: sideLength, length: sideLength, chamferRadius: 0.005)
        let cubeNode = SCNNode(geometry: geometry)
        return cubeNode
    }
}

extension ARAudioVisualizerViewController: SCNSceneRendererDelegate {
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        renderFrame()
    }
}

extension ARAudioVisualizerViewController {
    class FrequencyBands {
        var volumeInBand: [CGFloat] = [] // 0 to 1.0
        var colorByBand: [UIColor] = []
        var colorByBandRed: [CGFloat] = []
        var colorByBandGreen: [CGFloat] = []
        var colorByBandBlue: [CGFloat] = []
        
        func render(_ frequencies: UnsafeMutablePointer<Float>, yPosition: CGFloat) {
            CATransaction.begin()
            CATransaction.setAnimationDuration(0)
            CATransaction.setDisableActions(true)
            // Set the dimension of every frequency bar.
            for n in 0..<FREQ_BANDS {
                let amt = Float(frequencies[n] * 200)
                
                var volume = CGFloat(amt) / 5.0
                volume = min(1, volume)
                volumeInBand[n] = volume
            }
            CATransaction.commit()
        }
        
        func setup(view: UIView) {
            setupBands()
        }

        func setupBands() {
            for n in 0..<FREQ_BANDS {
                let color = colorForBand(n)
                volumeInBand.append(0)
                colorByBand.append(color)
                colorByBandRed.append(color.components.red)
                colorByBandGreen.append(color.components.green)
                colorByBandBlue.append(color.components.blue)
            }
        }
        
        func colorForBand(_ n: Int) -> UIColor {
            let range = CGFloat(0.8)
            let t = CGFloat(n) / CGFloat(FREQ_BANDS)
            return UIColor(hue: t * range, saturation: 1.0, brightness: 1.0, alpha: 1.0)
        }
    }
}

extension UIColor {
    var components:(red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat) {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        getRed(&r, green: &g, blue: &b, alpha: &a)
        return (r,g,b,a)
    }
}
