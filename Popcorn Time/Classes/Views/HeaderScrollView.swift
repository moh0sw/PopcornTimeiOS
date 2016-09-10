

import UIKit

public protocol HeaderScrollViewDelegate {
    func headerDidScroll(headerView: UIView, progressiveness: Float)
}

private enum ScrollDirection {
    case Down
    case Up
}

@IBDesignable public class HeaderScrollView: UIScrollView {
    @IBInspectable var headerView: UIView = UIView() {
        didSet {
            if let heightConstraint = headerView.constraints.filter({$0.firstAttribute == .Height}).first {
                headerHeightConstraint = heightConstraint
            } else {
                headerHeightConstraint = NSLayoutConstraint(item: headerView, attribute: .Height, relatedBy: .Equal, toItem: nil, attribute: .NotAnAttribute, multiplier: 1.0, constant: maximumHeaderHeight)
            }
        }
    }
    
    @IBInspectable var maximumHeaderHeight: CGFloat = 230
    
    @IBInspectable var minimumHeaderHeight: CGFloat = 22
    
    @IBOutlet private var headerHeightConstraint: NSLayoutConstraint! {
        didSet {
            guard !headerView.constraints.contains(headerHeightConstraint) else {return}
            headerView.addConstraint(headerHeightConstraint)
        }
    }
    
    public var programaticScrollEnabled = false
    
    private var scrollViewScrollingProgress: CGFloat {
        return (contentOffset.y + contentInset.top) / (contentSize.height + contentInset.top + contentInset.bottom - bounds.size.height)
    }
    private var overallScrollingProgress: CGFloat {
        return headerScrollingProgress * scrollViewScrollingProgress
    }
    private var headerScrollingProgress: CGFloat {
        get {
            return 1.0 - (headerHeightConstraint.constant - minimumHeaderHeight)/(maximumHeaderHeight - minimumHeaderHeight)
        }
    }
    
    private var lastTranslation: CGFloat = 0.0
//    private var scrollingIndicator: UIView
//    
//    public required init?(coder aDecoder: NSCoder) {
//        scrollingIndicator = UIView()
//        super.init(coder: aDecoder)
//        addSubview(scrollingIndicator)
//    }
    
    
    override public var contentOffset: CGPoint {
        didSet {
            if !programaticScrollEnabled {
                super.contentOffset = CGPointZero
            }
        }
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        if programaticScrollEnabled == true && headerHeightConstraint.constant != minimumHeaderHeight {
            headerHeightConstraint.constant = minimumHeaderHeight
        } else if isOverScrollingTop {
            headerHeightConstraint.constant = maximumHeaderHeight
        } else if isOverScrollingBottom {
            scrollToEnd(true)
        }
    }
    
    @IBAction func handleGesture(sender: UIPanGestureRecognizer) {
        var translation = sender.translationInView(sender.view!.superview!)
        isOverScrolling ? translation.y /= isOverScrollingBottom ? overScrollingBottomFraction : overScrollingTopFraction : ()
        let offset = translation.y - lastTranslation
        let scrollDirection: ScrollDirection = offset > 0 ? .Up : .Down
        
        if sender.state == .Changed || sender.state == .Began {
            if (headerHeightConstraint.constant + offset) >= minimumHeaderHeight && programaticScrollEnabled == false {
                if ((headerHeightConstraint.constant + offset) - minimumHeaderHeight) <= 8.0 // Stops scrolling from sticking just before we transition to scroll view input.
                {
                    headerHeightConstraint.constant = minimumHeaderHeight
                    updateScrolling(true)
                } else {
                    headerHeightConstraint.constant += offset
                    updateScrolling(false)
                }
            }
            if headerHeightConstraint.constant == minimumHeaderHeight && isAtTop
            {
                if scrollDirection == .Up {
                    programaticScrollEnabled = false
                } else // If header is fully collapsed and we are not at the end of scroll view, hand scrolling to scroll view
                {
                    programaticScrollEnabled = true
                }
            }
            lastTranslation = translation.y
        } else if sender.state == .Ended {
            if isOverScrollingTop {
                headerHeightConstraint.constant = maximumHeaderHeight
                updateScrolling(true)
            } else if isOverScrollingBottom {
                scrollToEnd(true)
            }
            lastTranslation = 0.0
        }
    }
    
    func updateScrolling(animated: Bool) {
        guard animated else {return}
        UIView.animateWithDuration(0.45, delay: 0.0, usingSpringWithDamping: 0.9, initialSpringVelocity: 0.3, options: [.AllowUserInteraction, .CurveEaseOut], animations: {
            self.superview?.layoutIfNeeded()
            }, completion: nil)
    }
    
    func scrollToEnd(animated: Bool) {
        headerHeightConstraint.constant -= verticalOffsetForBottom
        
        if headerHeightConstraint.constant > maximumHeaderHeight { headerHeightConstraint.constant = maximumHeaderHeight }
        
        if headerHeightConstraint.constant >= minimumHeaderHeight // User does not go over the "bridge area" so programmatic scrolling has to be explicitly disabled
        {
            programaticScrollEnabled = false
        }
        updateScrolling(animated)
    }
    
    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWithGestureRecognizer otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return gestureRecognizers!.contains(gestureRecognizer) && gestureRecognizers!.contains(otherGestureRecognizer)
    }

}

// MARK: - Scroll View Helper Variables

extension HeaderScrollView {
    var isOverScrollingBottom: Bool {
        return bounds.height > contentSize.height + contentInset.bottom
    }
    
    var isOverScrollingTop: Bool {
        return headerHeightConstraint.constant > maximumHeaderHeight
    }
    
    var isOverScrolling: Bool {
        return isOverScrollingTop || isOverScrollingBottom
    }
    
    var overScrollingBottomFraction: CGFloat {
        return (contentInset.bottom + contentSize.height)/bounds.height
    }
    
    var overScrollingTopFraction: CGFloat {
        return maximumHeaderHeight/headerHeightConstraint.constant
    }
}
