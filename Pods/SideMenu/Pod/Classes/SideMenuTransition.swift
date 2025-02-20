//
//  SideMenuTransition.swift
//  Pods
//
//  Created by Jon Kent on 1/14/16.
//
//

import UIKit

internal class SideMenuTransition: UIPercentDrivenInteractiveTransition, UIViewControllerAnimatedTransitioning, UIViewControllerTransitioningDelegate {
    
    private var presenting = false
    private var interactive = false
    private static weak var originalSuperview: UIView?
    
    internal static let singleton = SideMenuTransition()
    internal static var presentDirection: UIRectEdge = .Left;
    internal static weak var tapView: UIView!
    internal static weak var statusBarView: UIView?
    
    // prevent instantiation
    private override init() {}
    
    private class var viewControllerForPresentedMenu: UIViewController? {
        get {
            return SideMenuManager.menuLeftNavigationController?.presentingViewController != nil ? SideMenuManager.menuLeftNavigationController?.presentingViewController : SideMenuManager.menuRightNavigationController?.presentingViewController
        }
    }
    
    private class var visibleViewController: UIViewController? {
        get {
            return getVisibleViewControllerFromViewController(UIApplication.sharedApplication().keyWindow?.rootViewController)
        }
    }
    
    private class func getVisibleViewControllerFromViewController(viewController: UIViewController?) -> UIViewController? {
        if let navigationController = viewController as? UINavigationController {
            return getVisibleViewControllerFromViewController(navigationController.visibleViewController)
        } else if let tabBarController = viewController as? UITabBarController {
            return getVisibleViewControllerFromViewController(tabBarController.selectedViewController)
        } else if let presentedViewController = viewController?.presentedViewController {
            return getVisibleViewControllerFromViewController(presentedViewController)
        }
        
        return viewController
    }
    
    class func handlePresentMenuPan(pan: UIPanGestureRecognizer) {
        // how much distance have we panned in reference to the parent view?
        if let view = viewControllerForPresentedMenu != nil ? viewControllerForPresentedMenu?.view : pan.view {
            let transform = view.transform
            view.transform = CGAffineTransformIdentity
            let translation = pan.translationInView(pan.view!)
            view.transform = transform
            
            // do some math to translate this to a percentage based value
            if !singleton.interactive {
                if translation.x == 0 {
                    return // not sure which way the user is swiping yet, so do nothing
                }
                
                if let edge = pan as? UIScreenEdgePanGestureRecognizer {
                    SideMenuTransition.presentDirection = edge.edges == .Left ? .Left : .Right
                } else {
                    SideMenuTransition.presentDirection = translation.x > 0 ? .Left : .Right
                }
                
                if let menuViewController: UINavigationController = SideMenuTransition.presentDirection == .Left ? SideMenuManager.menuLeftNavigationController : SideMenuManager.menuRightNavigationController {
                    singleton.interactive = true
                    if let visibleViewController = visibleViewController {
                        visibleViewController.presentViewController(menuViewController, animated: true, completion: nil)
                    }
                }
            }
            
            let direction:CGFloat = SideMenuTransition.presentDirection == .Left ? 1 : -1
            let distance = translation.x / SideMenuManager.menuWidth
            // now lets deal with different states that the gesture recognizer sends
            switch (pan.state) {
            case .Began, .Changed:
                if pan is UIScreenEdgePanGestureRecognizer {
                    singleton.updateInteractiveTransition(min(distance * direction, 1))
                } else if distance > 0 && SideMenuTransition.presentDirection == .Right && SideMenuManager.menuLeftNavigationController != nil {
                    SideMenuTransition.presentDirection = .Left
                    singleton.cancelInteractiveTransition()
                    viewControllerForPresentedMenu?.presentViewController(SideMenuManager.menuLeftNavigationController!, animated: true, completion: nil)
                } else if distance < 0 && SideMenuTransition.presentDirection == .Left && SideMenuManager.menuRightNavigationController != nil {
                    SideMenuTransition.presentDirection = .Right
                    singleton.cancelInteractiveTransition()
                    viewControllerForPresentedMenu?.presentViewController(SideMenuManager.menuRightNavigationController!, animated: true, completion: nil)
                } else {
                    singleton.updateInteractiveTransition(min(distance * direction, 1))
                }
            default:
                singleton.interactive = false
                view.transform = CGAffineTransformIdentity
                let velocity = pan.velocityInView(pan.view!).x * direction
                view.transform = transform
                if velocity >= 100 || velocity >= -50 && abs(distance) >= 0.5 {
                    singleton.finishInteractiveTransition()
                } else {
                    singleton.cancelInteractiveTransition()
                }
            }
        }
    }
    
    class func handleHideMenuPan(pan: UIPanGestureRecognizer) {
        let translation = pan.translationInView(pan.view!)
        let direction:CGFloat = SideMenuTransition.presentDirection == .Left ? -1 : 1
        let distance = translation.x / SideMenuManager.menuWidth * direction
        
        switch (pan.state) {
            
        case .Began:
            singleton.interactive = true
            viewControllerForPresentedMenu?.dismissViewControllerAnimated(true, completion: nil)
        case .Changed:
            singleton.updateInteractiveTransition(max(min(distance, 1), 0))
        default:
            singleton.interactive = false
            let velocity = pan.velocityInView(pan.view!).x * direction
            if velocity >= 100 || velocity >= -50 && distance >= 0.5 {
                singleton.finishInteractiveTransition()
            }
            else {
                singleton.cancelInteractiveTransition()
            }
        }
    }
    
    class func handleHideMenuTap(tap: UITapGestureRecognizer) {
        viewControllerForPresentedMenu?.dismissViewControllerAnimated(true, completion: nil)
    }
    
    internal class func hideMenuStart() {
        let mainViewController = SideMenuTransition.viewControllerForPresentedMenu!
        let menuView = SideMenuTransition.presentDirection == .Left ? SideMenuManager.menuLeftNavigationController!.view : SideMenuManager.menuRightNavigationController!.view
        menuView.transform = CGAffineTransformIdentity
        mainViewController.view.transform = CGAffineTransformIdentity
        mainViewController.view.alpha = 1
        SideMenuTransition.tapView.frame = CGRectMake(0, 0, mainViewController.view.frame.width, mainViewController.view.frame.height)
        menuView.frame.origin.y = 0
        menuView.frame.size.width = SideMenuManager.menuWidth
        menuView.frame.size.height = mainViewController.view.frame.height
        SideMenuTransition.statusBarView?.frame = UIApplication.sharedApplication().statusBarFrame
        SideMenuTransition.statusBarView?.alpha = 0
        
        switch SideMenuManager.menuPresentMode {
            
        case .ViewSlideOut:
            menuView.alpha = 1 - SideMenuManager.menuAnimationFadeStrength
            menuView.frame.origin.x = SideMenuTransition.presentDirection == .Left ? 0 : mainViewController.view.frame.width - SideMenuManager.menuWidth
            mainViewController.view.frame.origin.x = 0
            menuView.transform = CGAffineTransformMakeScale(SideMenuManager.menuAnimationShrinkStrength, SideMenuManager.menuAnimationShrinkStrength)
            
        case .MenuSlideIn:
            menuView.alpha = 1
            menuView.frame.origin.x = SideMenuTransition.presentDirection == .Left ? -menuView.frame.width : mainViewController.view.frame.width
            
        case .MenuDissolveIn:
            menuView.alpha = 0
            menuView.frame.origin.x = SideMenuTransition.presentDirection == .Left ? 0 : mainViewController.view.frame.width - SideMenuManager.menuWidth
            mainViewController.view.frame.origin.x = 0
        }
    }
    
    internal class func hideMenuComplete() {
        let mainViewController = SideMenuTransition.viewControllerForPresentedMenu!
        let menuView = SideMenuTransition.presentDirection == .Left ? SideMenuManager.menuLeftNavigationController!.view : SideMenuManager.menuRightNavigationController!.view
        SideMenuTransition.tapView.removeFromSuperview()
        SideMenuTransition.statusBarView?.removeFromSuperview()
        mainViewController.view.motionEffects.removeAll()
        mainViewController.view.layer.shadowOpacity = 0
        menuView.layer.shadowOpacity = 0
        NSNotificationCenter.defaultCenter().removeObserver(self)
        if let topNavigationController = mainViewController as? UINavigationController {
            topNavigationController.interactivePopGestureRecognizer!.enabled = true
        }
        originalSuperview?.addSubview(mainViewController.view)
    }
    
    internal class func presentMenuStart(forSize size: CGSize = UIScreen.mainScreen().bounds.size) {
        let mainViewController = SideMenuTransition.viewControllerForPresentedMenu!
        if let menuView = SideMenuTransition.presentDirection == .Left ? SideMenuManager.menuLeftNavigationController?.view : SideMenuManager.menuRightNavigationController?.view {
            menuView.transform = CGAffineTransformIdentity
            mainViewController.view.transform = CGAffineTransformIdentity
            menuView.frame.size.width = SideMenuManager.menuWidth
            menuView.frame.size.height = size.height
            menuView.frame.origin.x = SideMenuTransition.presentDirection == .Left ? 0 : size.width - SideMenuManager.menuWidth
            SideMenuTransition.statusBarView?.frame = UIApplication.sharedApplication().statusBarFrame
            SideMenuTransition.statusBarView?.alpha = 1
            
            switch SideMenuManager.menuPresentMode {
                
            case .ViewSlideOut:
                menuView.alpha = 1
                let direction:CGFloat = SideMenuTransition.presentDirection == .Left ? 1 : -1
                mainViewController.view.frame.origin.x = direction * (menuView.frame.width)
                mainViewController.view.layer.shadowColor = SideMenuManager.menuShadowColor.CGColor
                mainViewController.view.layer.shadowRadius = SideMenuManager.menuShadowRadius
                mainViewController.view.layer.shadowOpacity = SideMenuManager.menuShadowOpacity
                mainViewController.view.layer.shadowOffset = CGSizeMake(0, 0)
                
            case .MenuSlideIn, .MenuDissolveIn:
                menuView.alpha = 1
                menuView.layer.shadowColor = SideMenuManager.menuShadowColor.CGColor
                menuView.layer.shadowRadius = SideMenuManager.menuShadowRadius
                menuView.layer.shadowOpacity = SideMenuManager.menuShadowOpacity
                menuView.layer.shadowOffset = CGSizeMake(0, 0)
                mainViewController.view.frame = CGRectMake(0, 0, size.width, size.height)
                mainViewController.view.transform = CGAffineTransformMakeScale(SideMenuManager.menuAnimationShrinkStrength, SideMenuManager.menuAnimationShrinkStrength)
                mainViewController.view.alpha = 1 - SideMenuManager.menuAnimationFadeStrength
            }
        }
    }
    
    internal class func presentMenuComplete() {
        let mainViewController = SideMenuTransition.viewControllerForPresentedMenu!
        switch SideMenuManager.menuPresentMode {
        case .MenuSlideIn, .MenuDissolveIn:
            if SideMenuManager.menuParallaxStrength != 0 {
                let horizontal = UIInterpolatingMotionEffect(keyPath: "center.x", type: .TiltAlongHorizontalAxis)
                horizontal.minimumRelativeValue = -SideMenuManager.menuParallaxStrength
                horizontal.maximumRelativeValue = SideMenuManager.menuParallaxStrength
                
                let vertical = UIInterpolatingMotionEffect(keyPath: "center.y", type: .TiltAlongVerticalAxis)
                vertical.minimumRelativeValue = -SideMenuManager.menuParallaxStrength
                vertical.maximumRelativeValue = SideMenuManager.menuParallaxStrength
                
                let group = UIMotionEffectGroup()
                group.motionEffects = [horizontal, vertical]
                mainViewController.view.addMotionEffect(group)
            }
        case .ViewSlideOut: break;
        }
        if let topNavigationController = mainViewController as? UINavigationController {
            topNavigationController.interactivePopGestureRecognizer!.enabled = false
        }
    }
    
    // MARK: UIViewControllerAnimatedTransitioning protocol methods
    
    // animate a change from one viewcontroller to another
    internal func animateTransition(transitionContext: UIViewControllerContextTransitioning) {
        
        let statusBarStyle = SideMenuTransition.visibleViewController?.preferredStatusBarStyle()
        
        // get reference to our fromView, toView and the container view that we should perform the transition in
        let container = transitionContext.containerView()!
        if let menuBackgroundColor = SideMenuManager.menuAnimationBackgroundColor {
            container.backgroundColor = menuBackgroundColor
        }
        
        // create a tuple of our screens
        let screens : (from:UIViewController, to:UIViewController) = (transitionContext.viewControllerForKey(UITransitionContextFromViewControllerKey)!, transitionContext.viewControllerForKey(UITransitionContextToViewControllerKey)!)
        
        // assign references to our menu view controller and the 'bottom' view controller from the tuple
        // remember that our menuViewController will alternate between the from and to view controller depending if we're presenting or dismissing
        let menuViewController = (!presenting ? screens.from : screens.to)
        let topViewController = !presenting ? screens.to : screens.from
        
        let menuView = menuViewController.view
        let topView = topViewController.view
        
        // prepare menu items to slide in
        if presenting {
            let tapView = UIView()
            tapView.autoresizingMask = [.FlexibleHeight, .FlexibleWidth]
            let exitPanGesture = UIPanGestureRecognizer()
            exitPanGesture.addTarget(SideMenuTransition.self, action:"handleHideMenuPan:")
            let exitTapGesture = UITapGestureRecognizer()
            exitTapGesture.addTarget(SideMenuTransition.self, action: "handleHideMenuTap:")
            tapView.addGestureRecognizer(exitPanGesture)
            tapView.addGestureRecognizer(exitTapGesture)
            SideMenuTransition.tapView = tapView
            
            SideMenuTransition.originalSuperview = topView.superview
            
            // add the both views to our view controller
            switch SideMenuManager.menuPresentMode {
            case .ViewSlideOut:
                container.addSubview(menuView)
                container.addSubview(topView)
                topView.addSubview(tapView)
            case .MenuSlideIn, .MenuDissolveIn:
                container.addSubview(topView)
                container.addSubview(tapView)
                container.addSubview(menuView)
            }
            
            if SideMenuManager.menuFadeStatusBar {
                let blackBar = UIView()
                if let menuShrinkBackgroundColor = SideMenuManager.menuAnimationBackgroundColor {
                    blackBar.backgroundColor = menuShrinkBackgroundColor
                } else {
                    blackBar.backgroundColor = UIColor.blackColor()
                }
                blackBar.userInteractionEnabled = false
                container.addSubview(blackBar)
                SideMenuTransition.statusBarView = blackBar
            }
            
            SideMenuTransition.hideMenuStart() // offstage for interactive
            
            NSNotificationCenter.defaultCenter().removeObserver(self)
            NSNotificationCenter.defaultCenter().addObserver(SideMenuTransition.singleton, selector:"applicationDidEnterBackgroundNotification", name: UIApplicationDidEnterBackgroundNotification, object: nil)
        }
        
        // perform the animation!
        let duration = transitionDuration(transitionContext)
        let options: UIViewAnimationOptions = interactive ? .CurveLinear : .CurveEaseInOut
        UIView.animateWithDuration(duration, delay: 0, options: options, animations: { () -> Void in
            if self.presenting {
                SideMenuTransition.presentMenuStart() // onstage items: slide in
            }
            else {
                SideMenuTransition.hideMenuStart()
            }
            }) { (finished) -> Void in
                if SideMenuTransition.visibleViewController?.preferredStatusBarStyle() != statusBarStyle {
                    print("Warning: do not change the status bar style while using custom transitions or you risk transitions not properly completing and locking up the UI. See http://www.openradar.me/21961293")
                }
                // tell our transitionContext object that we've finished animating
                if transitionContext.transitionWasCancelled() {
                    if self.presenting {
                        SideMenuTransition.hideMenuComplete()
                    }
                    transitionContext.completeTransition(false)
                } else {
                    if self.presenting {
                        SideMenuTransition.presentMenuComplete()
                        transitionContext.completeTransition(true)
                        switch SideMenuManager.menuPresentMode {
                        case .ViewSlideOut:
                            container.addSubview(topView)
                        case .MenuSlideIn, .MenuDissolveIn:
                            container.insertSubview(topView, atIndex: 0)
                        }
                        if let statusBarView = SideMenuTransition.statusBarView {
                            container.bringSubviewToFront(statusBarView)
                        }
                    } else {
                        SideMenuTransition.hideMenuComplete()
                        transitionContext.completeTransition(true)
                        menuView.removeFromSuperview()
                    }
                }
        }
    }
    
    // return how many seconds the transiton animation will take
    internal func transitionDuration(transitionContext: UIViewControllerContextTransitioning?) -> NSTimeInterval {
        return presenting ? SideMenuManager.menuAnimationPresentDuration : SideMenuManager.menuAnimationDismissDuration
    }
    
    // MARK: UIViewControllerTransitioningDelegate protocol methods
    
    // return the animataor when presenting a viewcontroller
    // rememeber that an animator (or animation controller) is any object that aheres to the UIViewControllerAnimatedTransitioning protocol
    internal func animationControllerForPresentedController(presented: UIViewController, presentingController presenting: UIViewController, sourceController source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        self.presenting = true
        SideMenuTransition.presentDirection = presented == SideMenuManager.menuLeftNavigationController ? .Left : .Right
        return self
    }
    
    // return the animator used when dismissing from a viewcontroller
    internal func animationControllerForDismissedController(dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        presenting = false
        return self
    }
    
    internal func interactionControllerForPresentation(animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        // if our interactive flag is true, return the transition manager object
        // otherwise return nil
        return interactive ? SideMenuTransition.singleton : nil
    }
    
    internal func interactionControllerForDismissal(animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        return interactive ? SideMenuTransition.singleton : nil
    }
    
    internal func applicationDidEnterBackgroundNotification() {
        if let menuViewController: UINavigationController = SideMenuTransition.presentDirection == .Left ? SideMenuManager.menuLeftNavigationController : SideMenuManager.menuRightNavigationController {
            SideMenuTransition.hideMenuStart()
            SideMenuTransition.hideMenuComplete()
            menuViewController.dismissViewControllerAnimated(false, completion: nil)
        }
    }
    
}
