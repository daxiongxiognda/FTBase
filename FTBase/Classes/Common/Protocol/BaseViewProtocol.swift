//
//  BaseViewProtocol.swift
//  FTBase
//
//  Created by qqq on 2026/8/30.
//

import Foundation
/**
 NSObjectProtocol 是 Objective-C 运行时的一部分，要求遵循该协议的类型必须是 NSObject 的子类。这保证了 @objc 协议在 Objective-C 运行时能正常工作
 @objc 使得协议只能被 class 遵循，不能被 struct 或 enum 遵循。
 */
// 对外提供一种协议  用于初始化或者更新view
@objc protocol FTBaseViewSetUpFlowProtocol: NSObjectProtocol {
    func ftSetUpUI()
    func ftUpdateUI()
    func ftSetUpViewModel()
}

extension FTBaseViewSetUpFlowProtocol {
    // 有 public，这些默认方法在外部可见
    public func ftSetUpUI() {}
    public func ftUpdateUI() {}
    public func ftSetUpViewModel() {}
}

@objc public protocol FTContentSizeDelegate: NSObjectProtocol {
    func ftContentSizeDidChanged(old: CGSize, new: CGSize)
}

/**
 作用：子类可以根据需要只重写其中一部分方法，而不必全部实现。父类也通过协议定义了可扩展的接口，明确了子类可以在哪些环节插入自定义行为。
 */
extension BaseViewController: FTBaseViewSetUpFlowProtocol {
    open func ftSetUpUI() {}
    open func ftUpdateUI() {}
    open func ftSetUpViewModel() {}
}
