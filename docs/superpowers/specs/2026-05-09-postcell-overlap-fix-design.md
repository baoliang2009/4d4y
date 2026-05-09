# PostCell 楼层内容重叠修复设计

## 问题描述

打开帖子时，1 楼和 2 楼内容在首次加载时出现重叠。具体表现为 `post_74218214`（1 楼）和 `post_74218219`（2 楼）的内容在 table view 中渲染位置重叠。

## 根因分析

`PostCell` 中 `statsContainer` 和 `imagesContainer` 在 `setupConstraints()` 中没有设置 `topAnchor` 约束——它们的 Y 轴位置完全依赖 `configure(with:)` 中动态创建并活跃的约束。

当非 1 楼帖子（floor > 1）且无图片时：

- `statsContainer.isHidden = true`，其顶部活性约束被停用，但 `height = 28` 的约束仍活跃，且**没有任何 Y 轴定位约束**
- `imagesContainer.isHidden = true`，同样没有顶部/底部约束

Auto Layout 遇到这种**未终结的约束**时，UITableView 在 `systemLayoutSizeFitting` 计算 self-sizing cell 高度时可能返回不准确的值，导致 cell 高度不足、相邻 cell 内容重叠。

## 修复方案

采用方案 A：始终维持完整约束链，隐藏时高度压缩为 0 而非停用约束。

### 约束链重组

**改前（断裂的链）：**

```
contentLabel → statsContainer.top（仅顶部，无底部）
               statsContainer.height = 28
               [无约束] → replyButton.bottom = containerView.bottom
```

**改后（始终完整的链）：**

```
contentLabel.bottom + 10 → statsContainer.top
statsContainer.height = （1 楼 ? 28 : 0）
statsContainer.bottom + 10 → [imagesContainer →] replyButton.top
replyButton.bottom = containerView.bottom - 12
```

### 具体改动

所有改动在 `Sources/Views/PostCell.swift` 中：

#### 1. 新增属性

```swift
private var statsContainerHeightConstraint: NSLayoutConstraint?
```

#### 2. `setupConstraints()` 改动

将 `statsContainer.heightAnchor` 从 `NSLayoutConstraint.activate([])` batch 中移出，保存为属性：

```swift
statsContainerHeightConstraint = statsContainer.heightAnchor.constraint(equalToConstant: 28)
statsContainerHeightConstraint?.isActive = true
```

#### 3. `configure(with:)` 核心改动

始终激活 `contentLabel → statsContainer` 链：

```swift
contentLabelBottomConstraint = statsContainer.topAnchor.constraint(equalTo: contentLabel.bottomAnchor, constant: 10)
contentLabelBottomConstraint?.isActive = true

statsContainerHeightConstraint?.constant = isFloorOne ? 28 : 0
statsContainer.isHidden = !isFloorOne
```

有图片时插入 `imagesContainer`：

```swift
if hasImages {
    imagesContainer.isHidden = false
    imagesContainerTopConstraint = imagesContainer.topAnchor.constraint(equalTo: statsContainer.bottomAnchor, constant: 10)
    imagesContainerTopConstraint?.isActive = true
    imagesContainerBottomConstraint = imagesContainer.bottomAnchor.constraint(equalTo: replyButton.topAnchor, constant: -10)
    imagesContainerBottomConstraint?.isActive = true
} else {
    imagesContainer.isHidden = true
    replyButtonTopConstraint = replyButton.topAnchor.constraint(equalTo: statsContainer.bottomAnchor, constant: 10)
    replyButtonTopConstraint?.isActive = true
}
```

移除 `statsContainerTopConstraint` 相关代码（与 `contentLabelBottomConstraint` 是同一个约束，不再冗余创建）。

#### 4. `prepareForReuse()` 更新

保留 `statsContainerHeightConstraint`（不销毁），重置常量和可见性：

```swift
statsContainerHeightConstraint?.constant = 28
```

### 改动范围

- 仅 `Sources/Views/PostCell.swift` 一个文件
- 新增 1 个属性，修改约 30 行代码
- 无新增文件，无其他类修改

## 验证方法

1. 打开任意多页帖子，滚动浏览各楼层，确认内容不重叠
2. 测试有图片和无图片的帖子
3. 测试 pull-to-refresh 后布局是否正常
4. 测试深色/浅色主题切换后布局是否正常
