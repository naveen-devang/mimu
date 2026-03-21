import SwiftUI
import MetalKit

struct MetalParticle {
    let startDX: Float
    let startDY: Float
    let r: Float
    let g: Float
    let b: Float
    let angle: Float
    let speed: Float
    let delay: Float
    let lifespan: Float
    let size: Float
    let brightness: Float
    let isBeam: Float
    let flickerRate: Float
    let wobbleFreq: Float
    let wobbleAmp: Float
    let drift: Float
}

struct ParticleUniforms {
    var elapsedTime: Float
    var cx: Float
    var cy: Float
    var islandY: Float
    var screenScale: Float
}

class MetalParticleRenderer: NSObject, MTKViewDelegate {
    private var device: MTLDevice!
    private var commandQueue: MTLCommandQueue!
    private var pipelineState: MTLRenderPipelineState!
    
    private var particleBuffer: MTLBuffer?
    private var particleCount: Int = 0
    
    var startTime: Date?
    var onComplete: (() -> Void)?
    var islandY: CGFloat = 37
    
    init?(metalView: MTKView) {
        super.init()
        guard let device = MTLCreateSystemDefaultDevice(),
              let commandQueue = device.makeCommandQueue() else { return nil }
        
        self.device = device
        self.commandQueue = commandQueue
        
        metalView.device = device
        metalView.delegate = self
        metalView.clearColor = MTLClearColorMake(0, 0, 0, 0)
        metalView.isOpaque = false
        metalView.framebufferOnly = true
        
        setupPipeline(metalView: metalView)
    }
    
    private func setupPipeline(metalView: MTKView) {
        guard let library = device.makeDefaultLibrary() else {
            print("Failed to make default library for Metal Particle Renderer")
            return
        }
        guard let vertexFunction = library.makeFunction(name: "particleVertex"),
              let fragmentFunction = library.makeFunction(name: "particleFragment") else {
            print("Failed to find particleVertex/particleFragment shaders")
            return
        }
        
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.vertexFunction = vertexFunction
        pipelineDescriptor.fragmentFunction = fragmentFunction
        pipelineDescriptor.colorAttachments[0].pixelFormat = metalView.colorPixelFormat
        
        // Setup premultiplied alpha blending
        let attachment = pipelineDescriptor.colorAttachments[0]!
        attachment.isBlendingEnabled = true
        attachment.rgbBlendOperation = .add
        attachment.alphaBlendOperation = .add
        attachment.sourceRGBBlendFactor = .one
        attachment.sourceAlphaBlendFactor = .one
        attachment.destinationRGBBlendFactor = .oneMinusSourceAlpha
        attachment.destinationAlphaBlendFactor = .oneMinusSourceAlpha
        
        do {
            pipelineState = try device.makeRenderPipelineState(descriptor: pipelineDescriptor)
        } catch {
            print("Failed to create pipeline state: \(error)")
        }
    }
    
    func updateParticles(_ particles: [MetalParticle]) {
        self.particleCount = particles.count
        guard particleCount > 0 else { return }
        
        let size = particles.count * MemoryLayout<MetalParticle>.stride
        particleBuffer = device.makeBuffer(bytes: particles, length: size, options: .storageModeShared)
    }
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {}
    
    func draw(in view: MTKView) {
        guard let pipelineState = pipelineState,
              let particleBuffer = particleBuffer,
              let renderPassDescriptor = view.currentRenderPassDescriptor,
              let drawable = view.currentDrawable,
              let commandBuffer = commandQueue.makeCommandBuffer(),
              let start = startTime else { return }
        
        let elapsed = Date().timeIntervalSince(start)
        
        guard let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) else { return }
        
        renderEncoder.setRenderPipelineState(pipelineState)
        
        var uniforms = ParticleUniforms(
            elapsedTime: Float(elapsed),
            cx: Float(view.bounds.width / 2.0),
            cy: Float(view.bounds.height / 2.0),
            islandY: Float(islandY),
            screenScale: Float(UIScreen.main.scale)
        )
        
        renderEncoder.setVertexBuffer(particleBuffer, offset: 0, index: 0)
        renderEncoder.setVertexBytes(&uniforms, length: MemoryLayout<ParticleUniforms>.size, index: 1)
        
        renderEncoder.drawPrimitives(type: .point, vertexStart: 0, vertexCount: particleCount)
        renderEncoder.endEncoding()
        
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
}

struct MetalParticleSystem: UIViewRepresentable {
    var particles: [MetalParticle]
    var startTime: Date?
    var islandY: CGFloat = 37
    
    class Coordinator {
        var renderer: MetalParticleRenderer?
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    func makeUIView(context: Context) -> MTKView {
        let mtkView = MTKView()
        context.coordinator.renderer = MetalParticleRenderer(metalView: mtkView)
        return mtkView
    }
    
    func updateUIView(_ uiView: MTKView, context: Context) {
        if let renderer = context.coordinator.renderer {
            renderer.islandY = islandY
            renderer.startTime = startTime
            renderer.updateParticles(particles)
            uiView.setNeedsDisplay()
        }
    }
}
