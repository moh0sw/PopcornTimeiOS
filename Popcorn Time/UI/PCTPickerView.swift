

import UIKit

@objc public protocol PCTPickerViewDelegate: class {
    optional func pickerView(pickerView: PCTPickerView, didClose selectedItems: [String: AnyObject])
}

public class PCTPickerView: UIView, UIPickerViewDataSource, UIPickerViewDelegate {
    
    @IBOutlet private var view: UIView!
    @IBOutlet public weak var pickerView: UIPickerView!
    @IBOutlet public weak var toolbar: UIToolbar!
    @IBOutlet public weak var cancelButton: UIBarButtonItem!
    @IBOutlet public weak var doneButton: UIBarButtonItem!
    @IBOutlet public weak var backgroundView: UIView!
    
    public weak var delegate: PCTPickerViewDelegate?
    private var visible: Bool {
        return !hidden
    }
    private var superView: UIView
    private var speed: Double = 0.2
    public private (set) var numberOfComponents: Int = 0
    public private (set) var numberOfRowsInComponets = [Int]()
    public private (set) var selectedItems: [String]
    public private (set) var componentDataSources: [[String: AnyObject]]
    public private (set) var attributesForComponents: [String?]!
    
    /**
     Designated Initialiser. Creates a UIPickerView with toolbar on top to handle dismissal of the view. Also handles hiding and showing animations.
     
     Parameter superview:                   View that the pickerView is a subview of.
     Parameter componentDataSources:        Data source dictionaries of the components in the picker.
     Parameter delegate:                    Register for `PCTPickerViewDelegate` notifications.
     Parameter selectedItems:               Data source keys that the pickerView will start on.
     Parameter attributesForComponenets:    Array of keys for NSAttributedString to customize component text style. Value
                                            for supplied key will be taken from the corresponding componentDataSource value.
     */
    public init(superView: UIView, componentDataSources: [[String: AnyObject]], delegate: PCTPickerViewDelegate?, selectedItems: [String], attributesForComponents: [String?]? = nil) {
        for array in componentDataSources {
            numberOfComponents += 1
            self.numberOfRowsInComponets.append(array.count)
        }
        self.superView = superView
        self.componentDataSources = componentDataSources
        self.delegate = delegate
        self.selectedItems = selectedItems
        super.init(frame: CGRectZero)
        self.attributesForComponents = attributesForComponents ?? [String?](count:numberOfComponents, repeatedValue: nil)
        prepareView()
    }
    /**
     This method of initialisation is not supported.
     */
    @available(iOS, deprecated = 9.0, message="Use initWithSuperView:componentDataSources:delegate:selectedItems:attributesForComponents: instead.") required public init?(coder aDecoder: NSCoder) {
        fatalError("This method of initialisation is not supported. Use initWithSuperView:componentDataSources:delegate:selectedItems:attributesForComponents: instead.")
    }
    /**
     Show pickerView in superView with animation.
     */
    public func show() {
        for component in 0..<numberOfComponents {
            pickerView.selectRow(Array(componentDataSources[component].keys).indexOf(selectedItems[component])!, inComponent: component, animated: true)
        }
        self.hidden = false
        var newFrame = self.frame
        newFrame.origin.y = superView.frame.height - self.frame.height
        UIView.animateWithDuration(speed, delay: 0, options: .CurveEaseInOut, animations: { () -> Void in
            self.frame = newFrame
            }, completion: { (finished) in })
    }
    /**
     Hide pickerView in superView with animation.
     */
    public func hide() {
        if visible {
            var newFrame = self.frame
            newFrame.origin.y = superView.frame.height
            UIView.animateWithDuration(speed, delay: 0, options: .CurveEaseInOut, animations: { () -> Void in
                self.frame = newFrame
                }, completion: { (finished) in
                    self.hidden = true
            })
        }
    }
    /**
     Toggle hiding/showing of pickerView in superView with animation.
     */
    public func toggle() {
        visible ? hide() : show()
    }
    
    // MARK: - UIPickerViewDataSource
    
    public func pickerView(pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusingView view: UIView?) -> UIView {
        var attributes = [String: AnyObject]()
        if let attribute = attributesForComponents[component] {
            attributes[attribute] = Array(componentDataSources[component].values)[row]
        }
        let textLabel = view as? UILabel ?? {
            let label = UILabel()
            label.textColor = UIColor.whiteColor()
            label.textAlignment = .Center
            return label
        }()
        textLabel.text = Array(componentDataSources[component].keys)[row]
        textLabel.attributedText = NSAttributedString(string: Array(componentDataSources[component].keys)[row], attributes: attributes)
        return textLabel
    }
    
    public func pickerView(pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return numberOfRowsInComponets[component]
    }
    
    public func numberOfComponentsInPickerView(pickerView: UIPickerView) -> Int {
        return numberOfComponents
    }
    
    // MARK: Private methods
    
    private func prepareView() {
        loadNib()
        let borderTop = CALayer()
        borderTop.frame = CGRectMake(0.0, toolbar.frame.height - 1, toolbar.frame.width, 0.5);
        borderTop.backgroundColor = UIColor(red:0.17, green:0.17, blue:0.17, alpha:1.0).CGColor
        toolbar.layer.addSublayer(borderTop)
        self.hidden = true
        let height = UIScreen.mainScreen().bounds.height / 2.7
        let frameSelf = CGRect(x: 0, y: UIScreen.mainScreen().bounds.height, width: superView.frame.width, height: height)
        var framePicker = frameSelf
        framePicker.origin.y = 0
        self.frame = frameSelf
        self.view.frame = framePicker
    }
    
    private func loadNib() {
        UINib(nibName: "PCTPickerView", bundle: nil).instantiateWithOwner(self, options: nil)[0] as? UIView
        self.addSubview(self.view)
    }
    
    @IBAction func done() {
        var selected = [String: AnyObject]()
        for component in 0..<numberOfComponents {
            let key = Array(componentDataSources[component].keys)[pickerView.selectedRowInComponent(component)]
            let value = componentDataSources[component][key]
            selected[key] = value
        }
        selectedItems = Array(selected.keys).reverse()
        hide()
        delegate?.pickerView?(self, didClose: selected)
    }
    
    @IBAction func cancel() {
       hide()
    }
}
