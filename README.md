# SegmentSlider
一个分段式的slider。

![slider](https://s19.aconvert.com/convert/p3r68-cdx67/k5gez-iy64e.gif)

## Feature
1. 按照`0`， `0.25`， `0.5`， `0.75`， `1`对 `slider` 进行节点划分；
2. 拖动到节点附近自动吸附。

## Usage
1. 在 Storyboard 中拖入一个 `UIVIew` 控件，将 `CustomClass` 更改为 `SegmentSlider`；
2. 实现 `SegmentSlider` 的代理方法:
```swift
func sliderValue(segmentSlider: SegmentSlider, value: CGFloat)
```
3. Done。
