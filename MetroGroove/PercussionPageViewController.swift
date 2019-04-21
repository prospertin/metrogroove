//
//  DrumSetPageViewController.swift
//  XGroove
//
//  Created by Thinh Nguyen on 12/22/16.
//  Copyright © 2016 Prospertin. All rights reserved.
//

import UIKit

class PercussionPageViewController: UIPageViewController, UIPageViewControllerDataSource, UIPageViewControllerDelegate {

    var pageArray:Array<PercussionCollectionViewController> = []
    var mainViewController:MainViewController!
    
    let drumSetLabels = [
        "Opn Hh",
        "Cls Hh",
        "Ride",
        "Crash",
        "Tom 1",
        "Tom 2",
        "Snare",
        "Kick",
        "Tom 3"
    ]
    
    let percussionLabels = [
        "Rimshot",
        "HiBong",
        "LwBong",
        "MuteCong",
        "HiCong",
        "LwCong",
        "HiTimb", 
        "LwTimb", 
        "Cowbell",
    ]
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        initializeDrumSetPages()
        self.dataSource = self
        self.delegate = self

        self.setViewControllers([pageArray.first!], direction: UIPageViewController.NavigationDirection.forward, animated: true, completion: nil)
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    private func initializeDrumSetPages() {
        
        let storyboard = UIStoryboard(name: "iPadMain", bundle: nil)
        
        let vc1 = storyboard.instantiateViewController(withIdentifier: "percussionCollectionViewController") as! PercussionCollectionViewController
        vc1.labels = drumSetLabels
        vc1.pageViewController = self
        vc1.pageIndex = 0
        pageArray.append(vc1)
        
        let vc2 = storyboard.instantiateViewController(withIdentifier: "percussionCollectionViewController") as! PercussionCollectionViewController
        vc2.labels = percussionLabels
        vc2.pageViewController = self
        vc2.pageIndex = 1
        pageArray.append(vc2)
    }
    
    // MARK: - Paging
    //Called before a gesture-driven transition begins.
    func pageViewController(_ pageViewController: UIPageViewController,
                            willTransitionTo pendingViewControllers: [UIViewController]) {
    }
    
    //Called after a gesture-driven transition completes.
    func pageViewController(_ pageViewController: UIPageViewController,
                            didFinishAnimating finished: Bool,
                            previousViewControllers: [UIViewController],
                            transitionCompleted completed: Bool) {
    }
    
    func pageViewController(_ pageViewController: UIPageViewController,
                            viewControllerBefore viewController: UIViewController) -> UIViewController? {
        let index = (viewController as! PercussionCollectionViewController).pageIndex
        return viewControllerAtIndex(index - 1)
    }
    
    func pageViewController(_ pageViewController: UIPageViewController,
                            viewControllerAfter viewController: UIViewController) -> UIViewController? {
        let index = (viewController as! PercussionCollectionViewController).pageIndex
        return viewControllerAtIndex(index + 1)
    }
    
    func viewControllerAtIndex(_ index: Int) -> PercussionCollectionViewController! {
        if index < 0 || index >= self.pageArray.count {
            return nil
        }
        else {
            return pageArray[index]
        }
    }

    func slideToPage(_ pageIndex:Int, animation:Bool) {
        if pageIndex >=  self.pageArray.count || pageIndex < 0 {
            return
        }
        let destPage = viewControllerAtIndex(pageIndex)
        
        let direction = pageIndex == 0 ? UIPageViewController.NavigationDirection.forward : UIPageViewController.NavigationDirection.reverse
        let visiblePages:Array<UIViewController> = [destPage!]
        setViewControllers(visiblePages, direction:direction, animated:animation, completion: nil);
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
