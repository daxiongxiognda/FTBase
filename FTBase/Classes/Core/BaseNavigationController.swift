//
//  BaseNavigationController.swift
//  FTBase
//
//  Created by qqq on 2026/8/28.
//

import UIKit
import FTResource

open class BaseNavigationController: UINavigationController {
    // 控制是否启用全屏滑动返回。当前设为 false，即使用系统默认的边缘滑动手势。设为 true 可启用全屏返回。
    public let useFullPopGesture = false
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        configureNavigationGestures()
    }
    
    open func setupUI() {
        // 禁用大标题模式，使用传统的小标题。
        navigationBar.prefersLargeTitles = false
        
        // 通过全局外观代理设置所有导航栏的按钮颜色（包括返回按钮、系统按钮等）。
        let navBar = UINavigationBar.appearance()
        navBar.tintColor = Resources._131314.color
        navBar.titleTextAttributes = titleAttributes
        
        // 全局设置导航栏文字按钮（如“取消”、“保存”）的样式，由 rightAttributes 提供。
        let barItem = UIBarButtonItem.appearance()
        barItem.setTitleTextAttributes(rightAttributes, for: .normal)
        
        //创建一个自定义外观对象，将阴影颜色设为透明（即移除导航栏底部分割线），
        //并同时应用到标准状态和滚动边缘状态，确保在所有情况下都无分割线。
        let navBarAppearance = UINavigationBarAppearance()
        navBarAppearance.shadowColor = .clear
        navBar.scrollEdgeAppearance = navBarAppearance
        navBar.standardAppearance = navBarAppearance
    }
    
    open func configureNavigationGestures(){
        // 获取系统边缘滑动手势的代理对象（即 _UINavigationInteractiveTransition 内部对象），用于复用系统的转场动画逻辑。
        let target = self.interactivePopGestureRecognizer?.delegate
        
        if useFullPopGesture{ //如果启用全屏返回：创建一个全屏 UIPanGestureRecognizer，绑定系统内部转场方法，实现全屏滑动返回。
            let sel = Selector(("handleNavigationTransition:"))
            let pan = UIPanGestureRecognizer(target: target, action: sel)
            pan.delegate = self
            self.view.addGestureRecognizer(pan)
        }else{ //否则：将系统边缘手势的代理设置为当前类，以便通过代理方法控制其启用/禁用。
            self.interactivePopGestureRecognizer?.delegate = self
        }
        
        //将导航控制器的代理设置为当前类，用于在页面切换时接收回调（如手势完成通知）。
        self.delegate = self
    }
        
    public override func pushViewController(_ viewController: UIViewController, animated: Bool) {
        viewController.hidesBottomBarWhenPushed = viewControllers.count >= 1
        if let pushCtr = viewController as? BaseViewController {
            if let hideFlag = pushCtr.hideTabbarWhenPush {
                viewController.hidesBottomBarWhenPushed = hideFlag
            }
            pushCtr.setDefaultNavBackItem()
        }else{
            //如果是其他类型的控制器，且不是根控制器，则设置一个默认的返回按钮（使用 FTResourceR 中的返回图片）。
            if !viewControllers.isEmpty {
                viewController.navigationItem.leftBarButtonItem =  UIBarButtonItem(image: FTResourceR.image.resource_MAIN_BACK, style: .plain, target: self, action: #selector(back))
            }
        }
        
        //调用父类方法执行实际的 Push 操作。
        super.pushViewController(viewController, animated: animated)
        
        // 滑动返回手势处理
        if useFullPopGesture{ // 如果启用全屏返回，禁用系统边缘手势（因为全屏手势已覆盖）。
            self.interactivePopGestureRecognizer?.isEnabled = false
        }else{ //否则，根据 BaseViewController 的 canSwipeBack 属性决定是否启用系统边缘手势。
            if let baseCtr = viewController as? BaseViewController{
                self.interactivePopGestureRecognizer?.isEnabled = baseCtr.canSwipeBack
            }else{
                self.interactivePopGestureRecognizer?.isEnabled = true
            }
        }
    }

    @objc private func back() {
        popViewController(animated: true)
    }
    
    private lazy var titleAttributes: [NSAttributedString.Key: Any] = {
        var temp: [NSAttributedString.Key: Any] = [:]
        temp[.font] = PingFang.semibold.font(size: 18)
        temp[.foregroundColor] = Resources._131314.color
        return temp
    }()
    
    private lazy var rightAttributes: [NSAttributedString.Key: Any] = {
        var temp: [NSAttributedString.Key: Any] = [:]
        temp[.font] = PingFang.regular.font(size: 14)
        temp[.foregroundColor] = Resources._131314.color
        return temp
    }()
}

extension BaseNavigationController: UINavigationControllerDelegate{
    /**
     在页面切换时，向转场协调器注册回调，监听手势交互完成事件。
     如果手势未被取消（即返回成功），且来源控制器是 BaseViewController，则调用其 popGestureDidEnd() 方法，并标记 isPopGestureHandled 防止重复调用。
     */
    public func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {
        viewController.transitionCoordinator?.notifyWhenInteractionChanges({ context in
            if !context.isCancelled, let fromCtr = context.viewController(forKey: .from) as? BaseViewController{
                guard !fromCtr.isPopGestureHandled else {
                    // 标识 popGestureDidEnd 只允许调用一次
                    return
                }
                fromCtr.isPopGestureHandled = true
                fromCtr.popGestureDidEnd()
            }
        })
    }
}

extension BaseNavigationController: UIGestureRecognizerDelegate {
    public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        //如果导航栈中控制器少于 2 个或当前显示的是根控制器，则禁用手势。
        if viewControllers.count < 2 || visibleViewController == viewControllers.first { return false }
        //获取栈顶控制器，如果是 BaseViewController，则调用 popGestureDidBegin()，并根据 canSwipeBack 决定是否允许手势，同时更新其 ignoreOtherGesture 属性（用于避免与其他手势冲突）。
        var flag = self.interactivePopGestureRecognizer?.isEnabled ?? true
        if let topCtr = topViewController as? BaseViewController{
            topCtr.popGestureDidBegin()
            flag = topCtr.canSwipeBack
            topCtr.ignoreOtherGesture = flag
        }
        return flag
    }
}

//屏幕旋转控制
extension BaseNavigationController {
    //将屏幕旋转的决策权完全交给栈顶控制器
    open override var shouldAutorotate: Bool {
        return topViewController?.shouldAutorotate ?? false
    }

    // 如果栈顶控制器未实现这些属性，则默认使用竖屏
    open override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return topViewController?.supportedInterfaceOrientations ?? .portrait
    }

    open override var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation {
        return topViewController?.preferredInterfaceOrientationForPresentation ?? .portrait
    }
}
