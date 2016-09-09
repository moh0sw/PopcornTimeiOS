//
//  WobblyCell
//  PopcornTime
//
//  Created by Alex on 10/09/2016.
//  Copyright © 2016 Popcorn Time. All rights reserved.
//

import UIKit

class WobblyCell: UICollectionViewCell {
    
    var touchdown = false
    var animEnded = false
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        super.touchesBegan(touches, withEvent: event)
        touchdown = true
        self.animateIn()
    }
    

    override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?){
        super.touchesEnded(touches,withEvent:event)
        if touchdown {
            self.animateOut()
            touchdown = false
        }
    }
    
    
    override func touchesCancelled(touches: Set<UITouch>?, withEvent event: UIEvent?){
        super.touchesCancelled(touches,withEvent:event)
        if touchdown {
            self.animateOut()
            touchdown = false
        }
    }
    
    func animateIn() {
        UIView.animateWithDuration(0.12, animations: {
            self.transform = CGAffineTransformMakeScale(0.95, 0.95)
            }, completion: { _ in
                self.animEnded = true
                if !self.touchdown {
                   self.animateOut()
                }
        })
    }
    
    func animateOut() {
        
        guard self.animEnded else {return}
        
        UIView.animateWithDuration(0.3, delay: 0, usingSpringWithDamping: 0.5, initialSpringVelocity: 0.5, options: .AllowAnimatedContent, animations: { 
            self.transform = CGAffineTransformIdentity
            }) { _ in
                self.animEnded = false
        }
    }
}