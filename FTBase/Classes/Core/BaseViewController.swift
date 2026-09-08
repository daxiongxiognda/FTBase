//
//  BaseViewController.swift
//  FTBase
//
//  Created by qqq on 2026/8/28.
//

import Foundation
import RxSwift
import FTResource
import FTTool

// 使用 open 修饰符，允许其他模块（如壳工程）继承此类。
open class BaseViewController: UIViewController {
    //disposeBag：用于管理 RxSwift 订阅的生命周期，确保在页面销毁时自动取消所有订阅，避免内存泄漏。
    public lazy var disposeBag: DisposeBag = .init()
    
    // 导航条返回按钮样式: 当值改变时，自动更新导航栏返回按钮。
    public var backType: NavBackType = .back {
        didSet {
            setDefaultNavBackItem()
        }
    }
    
    // push是否隐藏底部tabbar
    public var hideTabbarWhenPush: Bool?
    
    // canSwipeBack：控制当前页面是否允许滑动返回。当值改变时，实时更新导航控制器的手势状态。
    public var canSwipeBack: Bool = true{
        didSet {
            self.navigationController?.interactivePopGestureRecognizer?.isEnabled = canSwipeBack
        }
    }
    
    // 用于在滑动返回时，是否忽略当前控制器的其他手势（避免手势冲突），由子类根据需要重写。
    open var ignoreOtherGesture = false
    
    // 控制状态栏的显示/隐藏，切换时有 0.25 秒的淡入淡出动画。
    public var hideStatusBar = false {
        didSet {
            UIView.animate(withDuration: 0.25) {
                self.setNeedsStatusBarAppearanceUpdate()
            }
        }
    }
    
    // 标识 popGestureDidEnd 只允许调用一次
    // 标识 popGestureDidEnd() 是否已被调用，用于防止滑动返回结束回调被重复触发。
    open var isPopGestureHandled = false
    
    public init() {
        super.init(nibName: nil, bundle: nil)
    }
    //用 @available(*, unavailable) 标记，禁止通过 Storyboard 或 Nib 初始化，强制子类使用纯代码方式创建。
    @available(*, unavailable, message: "We don't support init view controller from a nib.")
    public override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    //同样禁止通过 storyboard 加载，如果触发则直接崩溃，进一步确保纯代码开发模式。
    @available(*, unavailable, message: "We don't support init view controller from a nib.")
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    deinit {
        log("✅\(NSStringFromClass(type(of: self))) 释放了✅")
    }
    /**
     允许子类重写此方法，同时保留父类的行为。
     */
    open override func viewDidLoad() {
        super.viewDidLoad()
        //固定顺序调用三个协议方法（由协议扩展提供默认空实现），将页面初始化拆解为三个清晰的步骤：UI 构建 → UI 更新 → ViewModel 绑定，方便子类按需重写。
        ftSetUpUI()
        ftUpdateUI()
        ftSetUpViewModel()
    }
    
    @objc open func backPrevious(){
        if let viewCtrs = self.navigationController?.viewControllers, viewCtrs.count > 1{
            self.navigationController?.popViewController(animated: true)
        }else{
            self.dismiss(animated: true)
        }
    }
    
    // 提供两个空方法，供子类重写，用于在滑动返回开始和结束时执行自定义逻辑（如重置界面状态、取消选中、暂停视频等）。
    // 滑动返回开始
    open func popGestureDidBegin(){
        
    }
    
    // 滑动返回结束
    open func popGestureDidEnd(){
        
    }
    
    // mark 系统属性重写
    open override var prefersStatusBarHidden: Bool {
        return hideStatusBar
    }
    open override var preferredStatusBarStyle: UIStatusBarStyle {
        return .default
    }
    
    open override var shouldAutorotate: Bool {
        return false
    }
    
    open override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }
    
    open override var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation {
        return .portrait
    }
}



public extension BaseViewController {
    func setDefaultNavBackItem() {
        navigationItem.leftBarButtonItem = makeBackBarButtonItem()
    }
    /// 创建返回按钮
    private func makeBackBarButtonItem() -> UIBarButtonItem {
        switch backType {
        case .back:
            return makeBaseButtonItem(image: FTResourceR.image.resource_MAIN_BACK)
        case .cancel:
            return makeBaseButtonItem(title: "取消")
        case .close:
            return makeBaseButtonItem(title: "关闭")
        case .customImage(let image):
            return makeBaseButtonItem(image: image)
        case .customText(let text):
            return makeBaseButtonItem(title: text)
        case .customView(let view):
            return makeCustomViewBarButtonItem(view)
        }
    }
    
    /// 创建基础按钮（统一处理文字和图片）
    private func makeBaseButtonItem(title: String? = nil, image: UIImage? = nil) -> UIBarButtonItem {
        let button = UIButton(type: .custom)
        button.frame = CGRect(x: 0, y: 0, width: 44, height: 44)
        button.contentHorizontalAlignment = .left
        
        if let title = title {
            button.setTitle(title, for: .normal)
            button.setTitleColor(.black, for: .normal)
            button.titleLabel?.font = UIFont.systemFont(ofSize: 16)
        }
        if let image = image {
            button.setImage(image, for: .normal)
        }
        
        button.addTarget(self, action: #selector(backPrevious), for: .touchUpInside)
        return UIBarButtonItem(customView: button)
    }
    
    /// 创建自定义视图按钮
    private func makeCustomViewBarButtonItem(_ view: UIView) -> UIBarButtonItem {
        view.ttclickClosure = { [weak self] in
            self?.backPrevious()
        }
        return UIBarButtonItem(customView: view)
    }
    
}

//支持默认返回、取消、关闭、自定义图片/文字/视图
public enum NavBackType{
    case back
    case cancel
    case close
    case customImage(image: UIImage)
    case customText(text: String)
    case customView(view: UIView)
}

func log(
    _ items: Any...,
    separator: String = " ",
    terminator: String = "\n",
    file: String = #file,
    method: String = #function,
    line: Int = #line
) {
#if DEBUG
    let sss = items.map { String(describing: $0) }
    let aItems = "\((file as NSString).lastPathComponent)[\(line)], \(method): \(sss.joined(separator: separator))"
    Swift.print(aItems, terminator: terminator)
#endif
}
