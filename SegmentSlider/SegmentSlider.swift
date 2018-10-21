//
//  SegmentSlider.swift
//  iCoin
//
//  Created by mac on 2018/9/26.
//  Copyright © 2018 yunkuai. All rights reserved.
//

import UIKit

protocol SegmentSliderDelegate: class {
    func sliderValue(segmentSlider: SegmentSlider, value: CGFloat)
}

class SegmentSlider: UIControl {
    
    weak var delegate: SegmentSliderDelegate?
    
    /// 未被选中情况下的半径
    @objc var normalRadius: CGFloat = 5 {
        didSet {
            self.drawThumb(self.percent)
        }
    }
    
    /// 选中情况下的半径
    @objc var selectedRadius: CGFloat = 6 {
        didSet {
            self.drawThumb(self.percent)
        }
    }
    
    /// 未选中情况下的颜色
    @objc var normalColor: UIColor = #colorLiteral(red: 0.7294117647, green: 0.7294117647, blue: 0.7294117647, alpha: 1)  {
        didSet {
            self.drawThumb(self.percent)
        }
    }
    
    /// 选中情况下的颜色
    @objc var selectedColor: UIColor = #colorLiteral(red: 0.2431372549, green: 0.6823529412, blue: 0.2274509804, alpha: 1) {
        didSet {
            self.drawThumb(self.percent)
        }
    }
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.initializeSomeSettings()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.initializeSomeSettings()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        self.initializeSomeSettings()
    }
    
    
    private func initializeSomeSettings() {
        self.percent = 0
        
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(panAction(_:)))
        self.addGestureRecognizer(panGesture)
    }
    
    
    @objc func panAction(_ sender: UIPanGestureRecognizer) {
        let location = sender.location(in: self)
        
        
        guard self.isOutOfBoundary(location) else {
            self.delegate?.sliderValue(segmentSlider: self, value: self.percent)
            return
        }
        
        // 计算范围
        self.percent = self.calculatePercent(location.x)
        
        // 手势结束后判断吸附
        if sender.state == .ended {
            self.automaticAdsorption()
        }
        
        self.delegate?.sliderValue(segmentSlider: self, value: self.percent)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touchPoint = touches.first?.location(in: self) else { return }
        
        guard self.isOutOfBoundary(touchPoint) else {
            self.delegate?.sliderValue(segmentSlider: self, value: self.percent)
            return
        }
        
        // 计算范围
        self.percent = self.calculatePercent(touchPoint.x)
        
        // 判断吸附
        self.automaticAdsorption()
        
        self.delegate?.sliderValue(segmentSlider: self, value: self.percent)
    }
    
    
    
    /// 判断边界
    ///
    /// - Parameter location: 滑动或触摸点的位置
    /// - Returns: 返回是否越界
    private func isOutOfBoundary(_ location: CGPoint) -> Bool {
        
        if location.x < selectedRadius {
            self.percent = 0
            return false
        }
        
        
        if location.x > self.bounds.width - selectedRadius {
            self.percent = 1
            return false
        }
        
        return true
    }
    
    /// 添加吸附效果
    func automaticAdsorption() {
        
        self.separatorRounds.forEach { (roundShape) in
            if (roundShape.path?.boundingBoxOfPath.intersects(self.thumb.path!.boundingBoxOfPath))! {
                
                let centerX = roundShape.path?.boundingBoxOfPath.midX
                
                self.percent = self.calculatePercent(centerX!)
            }
        }
    }
    
    
    var percent: CGFloat = 0.0 {
        didSet {
            self.drawThumb(percent)
        }
    }
    
    
    /// 计算指定的x在view当中的百分比
    ///
    /// - Parameter position: 横坐标
    /// - Returns: 返回x坐标的百分比
    private func calculatePercent(_ position: CGFloat) -> CGFloat {
        return (position - selectedRadius) / (self.bounds.width - selectedRadius * 2)
    }
    
    /// 计算某个百分比的实际位置
    ///
    /// - Parameter percent: 指定百分比
    /// - Returns: 返回精确的x坐标
    private func calculateAccuracyX(_ percent: CGFloat) -> CGFloat {
        return percent * (self.bounds.width - selectedRadius * 2) + selectedRadius
    }
    
    /// 绘制指示器
    ///
    /// - Parameter percent: 指示器所在位置的百分比
    private func drawThumb(_ percentage: CGFloat = 0) {
        
        assert((percentage <= 1 && percentage >= 0), "Percent value should between 0 and 1")
        
        // 先重绘基础的显示layer
        self.drawBasicLayers(percentage)
        
        // 再重新绘制 thumb
        let center = CGPoint(x: self.calculateAccuracyX(percentage), y: self.bounds.midY)
        let path = UIBezierPath(arcCenter: center, radius: selectedRadius, startAngle: 0, endAngle: CGFloat.pi * 2, clockwise: true)
        self.thumb.path = path.cgPath
        self.thumb.strokeColor = selectedColor.cgColor
    }
    
    lazy var normalLine: CAShapeLayer! = {
        let lineShape = self.shapeLayer()
        lineShape.strokeColor = normalColor.cgColor
        return lineShape
    }()
    
    lazy var selectedLine: CAShapeLayer! = self.shapeLayer()
    
    lazy var thumb: CAShapeLayer = {
        let thumbShape = self.shapeLayer()
        thumbShape.fillColor = #colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0).cgColor
        return thumbShape
    }()
    
    
    /// 根据圆心生成贝塞尔曲线
    ///
    /// - Parameters:
    ///   - centers: 所有的分隔圆心
    ///   - current: 指示器圆心
    /// - Returns: 返回生成的贝塞尔曲线
    private func getLinePath(_ centers: [CGPoint], current: CGPoint, isSelected: Bool = false) -> UIBezierPath {
        
        let linePath = UIBezierPath()
        
        // Filter all points that build the path
        var filterCenters = centers
        
        // If thumb point exists then filter all points that build selected line
        if isSelected {
            filterCenters = centers.filter({ (point) -> Bool in
                return point.x < current.x
            })
        }
        filterCenters.append(current)
        // Sort
        filterCenters = filterCenters.sorted { (point1, point2) -> Bool in
            return point1.x < point2.x
        }
        
        // Return if there is less than 2 points
        if filterCenters.count < 2 { return linePath }
        
        
        var starts = [CGPoint]()
        
        var ends = [CGPoint]()
        
        for i in 0..<filterCenters.count {
            
            let centerPoint = filterCenters[i]
            
            // 如果不是最后一个点，则该点的右边就是路径的开始点
            if i != filterCenters.count - 1 {
                let start = CGPoint(x: centerPoint.x + normalRadius + 2, y: centerPoint.y)
                starts.append(start)
            }
            
            // 如果不是第一个点，则该点的左边就是路径的结束点
            if i != 0 {
                let end = CGPoint(x: centerPoint.x - normalRadius - 2, y: centerPoint.y)
                ends.append(end)
            }
        }
        
        
        for j in 0..<starts.count {
            let path = UIBezierPath()
            path.move(to: starts[j])
            path.addLine(to: ends[j])
            linePath.append(path)
        }
        
        return linePath
    }
    
    
    
    
    lazy var separatorRounds = [CAShapeLayer]()
    
    /// 绘制分隔圆点和连线
    ///
    /// - Parameter position: 指示器所处的位置，用来标记圆圈的填充颜色
    private func drawBasicLayers(_ percentage: CGFloat) {
        
        let y = self.bounds.midY
        
        let x1 = self.calculateAccuracyX(0)
        let x2 = self.calculateAccuracyX(0.25)
        let x3 = self.calculateAccuracyX(0.5)
        let x4 = self.calculateAccuracyX(0.75)
        let x5 = self.calculateAccuracyX(1)
        
        let center1 = CGPoint(x: x1, y: y)
        let center2 = CGPoint(x: x2, y: y)
        let center3 = CGPoint(x: x3, y: y)
        let center4 = CGPoint(x: x4, y: y)
        let center5 = CGPoint(x: x5, y: y)
        
        let centers = [center1, center2, center3, center4, center5]
        
        // 第一次添加分隔的圆圈
        if self.separatorRounds.count == 0 {
            self.separatorRounds = centers.map { (center) -> CAShapeLayer in
                let roundShape = self.shapeLayer()
                return roundShape
            }
        }
        
        for i in 0..<self.separatorRounds.count {
            self.separatorRounds[i].path = UIBezierPath(arcCenter: centers[i], radius: normalRadius, startAngle: 0, endAngle: CGFloat.pi * 2, clockwise: true).cgPath
            
            if centers[i].x <= self.calculateAccuracyX(percentage) {
                self.separatorRounds[i].fillColor = selectedColor.cgColor
                self.separatorRounds[i].strokeColor = selectedColor.cgColor
            } else {
                self.separatorRounds[i].fillColor = normalColor.cgColor
                self.separatorRounds[i].strokeColor = normalColor.cgColor
            }
        }
        
        
        self.normalLine.path = self.getLinePath(centers, current: CGPoint(x: self.calculateAccuracyX(percentage), y: y)).cgPath
        self.selectedLine.path = self.getLinePath(centers, current: CGPoint(x: self.calculateAccuracyX(percentage), y: y), isSelected: true).cgPath
        self.selectedLine.strokeColor = selectedColor.cgColor
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.percent = 0
    }
    
    
    private func shapeLayer() -> CAShapeLayer {
        let shapeLayer = CAShapeLayer()
        shapeLayer.lineWidth = 1
        self.layer.addSublayer(shapeLayer)
        return shapeLayer
    }

}
