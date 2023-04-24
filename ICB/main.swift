import UIKit

class ViewController: UIViewController {
    var device: MTLDevice!
    var defaultLibrary: MTLLibrary!
    var commandQueue: MTLCommandQueue!
    
    var mainRenderPipelineState: MTLRenderPipelineState!
    
    var mainTarget: MTLTexture!
    var colorBuffer: MTLBuffer!
    var argumentBuffer: MTLBuffer!
    
    var indirectCommandBuffer: MTLIndirectCommandBuffer!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        device = MTLCreateSystemDefaultDevice()!
        defaultLibrary = device.makeDefaultLibrary()!
        commandQueue = device.makeCommandQueue()!
        
        mainRenderPipelineState = {
            let descriptor = MTLRenderPipelineDescriptor()
            descriptor.label = "Main"
            descriptor.supportIndirectCommandBuffers = true
            descriptor.vertexFunction = defaultLibrary.makeFunction(name: "main_vertex")
            descriptor.fragmentFunction = defaultLibrary.makeFunction(name: "main_fragment")
            descriptor.colorAttachments[0].pixelFormat = .r16Float
            return try! device.makeRenderPipelineState(descriptor: descriptor)
        }()
        
        mainTarget = {
            let descriptor = MTLTextureDescriptor()
            descriptor.textureType = .type2D
            descriptor.width = 512
            descriptor.height = 512
            descriptor.pixelFormat = .r16Float
            descriptor.storageMode = .private
            descriptor.usage = [.renderTarget]
            return device.makeTexture(descriptor: descriptor)!
        }()
        
        colorBuffer = {
            var colorBytes = Float(0.5)
            return device.makeBuffer(bytes: &colorBytes, length: 4)!
        }()
        
        indirectCommandBuffer = {
            let descriptor = MTLIndirectCommandBufferDescriptor()
            descriptor.commandTypes = [.draw]
            descriptor.inheritBuffers = false
            descriptor.inheritPipelineState = false
            descriptor.maxVertexBufferBindCount = 0
            descriptor.maxFragmentBufferBindCount = 1
            descriptor.maxKernelBufferBindCount = 0
            return device.makeIndirectCommandBuffer(descriptor: descriptor, maxCommandCount: 1, options: .storageModeShared)!
        }()
        
        indirectCommandBuffer.reset(0..<1)
        let command = indirectCommandBuffer.indirectRenderCommandAt(0)
        command.setFragmentBuffer(colorBuffer, offset: 0, at: 0)
        command.setRenderPipelineState(mainRenderPipelineState)
        command.drawPrimitives(.triangle, vertexStart: 0, vertexCount: 6, instanceCount: 1, baseInstance: 0)
        
        render()
    }
    
    func render() {
        let captureDescriptor = MTLCaptureDescriptor()
        captureDescriptor.captureObject = device
        try! MTLCaptureManager.shared().startCapture(with: captureDescriptor)
        
        let commandBuffer = commandQueue.makeCommandBuffer()!

        let mainRenderPassDescriptor = MTLRenderPassDescriptor()
        mainRenderPassDescriptor.colorAttachments[0].texture = mainTarget
        mainRenderPassDescriptor.colorAttachments[0].loadAction = .clear
        mainRenderPassDescriptor.colorAttachments[0].clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 0)
        mainRenderPassDescriptor.colorAttachments[0].storeAction = .store
        
        let mainRenderCommandEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: mainRenderPassDescriptor)!
        mainRenderCommandEncoder.useResources([colorBuffer], usage: [.read], stages: [.fragment])
        mainRenderCommandEncoder.executeCommandsInBuffer(indirectCommandBuffer, range: 0..<1)
        mainRenderCommandEncoder.endEncoding()

        commandBuffer.commit()
        
        MTLCaptureManager.shared().stopCapture()
    }
}

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }

        let window = UIWindow(windowScene: windowScene)
        window.frame = windowScene.coordinateSpace.bounds

        let viewController = ViewController()
        window.rootViewController = viewController

        self.window = window
        self.window?.makeKeyAndVisible()
    }
}

class AppDelegate: UIResponder, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        return true
    }
    
    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
    }
}

UIApplicationMain(
    CommandLine.argc,
    CommandLine.unsafeArgv,
    NSStringFromClass(UIApplication.self),
    NSStringFromClass(AppDelegate.self))
