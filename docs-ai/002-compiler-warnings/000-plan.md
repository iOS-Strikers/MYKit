# MYKit 编译警告修复方案 v2

状态：Approved；用户已确认 v2，独立方案复审 clean。
基线：3913b97（已发布 2.0.0）；工作区初始干净。最低系统 iOS 15。

## 需求与调查

用户要求检查剩余 88 条编译警告，能修的都修掉。基线为本次实际执行的 CocoaPods 全子模块 lint 日志。88 条对应 18 个源文件，其中 11 条为公开头文件在导入阶段重复报告。涉及公共 API 的空值契约、窗口选择和平台弃用行为，采用完整 bugfix 流程。

## 目标与范围

修复有可靠替代方式的警告，保留兼容行为；预计消除 53 条，保留 35 条具有明确原因的警告，不通过全局或局部禁用诊断来美化结果。不更改 SafeKit 防护实现，不修改版本号、已发布标签、不自动提交、推送或发布新版本。

## 实施设计

1. NSArray/NSDictionary 两个 Addition.h：逐项按实现补全 nullable/nonnull。plist 输入允许 nil；containsObjectForKey 和 entriesForKeys 允许 nil；JSONString 可返回 nil；确定返回集合的方法 nonnull。不改变运行时序列化行为。
2. NSDate+Addition.m：补全 12 处空的参数/返回值说明，准确说明格式默认值、时间单位和返回结果。
3. UIImage Color/Addition/ImageEffects：5 处枚举组合显式转换为 CGBitmapInfo，保持实际位模式。
4. UIApplication Authority：定位使用 CLLocationManager 实例 authorizationStatus，仅查询不触发授权弹窗；通讯录使用 CNContactStore，移除不可能执行的 iOS 9 以下分支。顺手修正同文件相机查询误用 EventKit，改为 AVCaptureDevice 视频授权查询；不扩展其他权限语义。
5. 三处加载指示器：改用 Medium，并明确设置原来的 white/gray 颜色，保持布局、开始/结束和恢复行为。
6. UIApplication NetworkActivityIndicator：用 C11 stdatomic 替代 OSAtomic，保持计数及 networkActivityIndicatorVisible 属性写入；两处属性弃用警告保留，避免破坏外部读取 getter 的状态行为。文档明确 iOS 15 无状态栏网络指示器 UI，这些方法只保留旧状态副作用，不创建自定义 UI、不新增状态 API。
7. 窗口相关三个分类：引入一个内部窗口选择辅助（proposed: UIKit/UIWindow/MYWindowContextInternal.h，podspec 标记 private）。主线程读取 foregroundActive UIWindowScene 的可见普通级别 key window；唯一候选时返回，多个活跃候选返回 nil，避免从无序集合随机选窗口。无 scene 的旧 AppDelegate 生命周期才回退到有 window getter 的 delegate.window；无窗口返回 nil/0。UIScreen 状态栏在 scene 路径从同一窗口的 windowScene.statusBarManager 读取；无 scene 的旧 AppDelegate 路径保留 statusBarFrame（接受 1 条警告），避免旧生命周期状态栏高度错误变为 0。ClassName 显示的 viewDidAppear 路径优先使用当前实例 view.window；静态入口使用上述规则，关闭时清理各窗口中本分类自己的标签。保持主线程 UIKit 使用前提并文档说明。

## 保留的 35 条警告与理由

- UIButton+ImageTitleStyle.m 24 条：十种布局含独立居中、边缘分离等形式；不能用 UIButtonConfiguration 的 imagePlacement/imagePadding 等价覆盖全部效果。保持旧布局，不用 KVC、动态 selector 或禁用诊断规避警告；文档明确只适用于 configuration=nil 的旧式按钮。
- NSData+YYAdd.m / NSString+Collection.m 7 条：公开方法承诺 MD2/MD4/MD5 摘要。换成 SHA256 会破坏持久化摘要、协议和标识符语义。保留算法，文档说明仅供旧协议兼容，不用于密码/安全校验，推荐已有 SHA256 方法。
- UIApplication+NetworkActivityIndicator.m 2 条及 UIScreen+Addition.m 1 条：保留旧生命周期状态栏高度和网络状态 getter 行为，只有有 scene 时才能可靠迁移到 statusBarManager。
- UIDevice+Addition.m 1 条：运营商接口的替代 serviceSubscriberCellularProviders 也已在 iOS 16 废弃且无替代。保留当前输出，文档说明系统可能不再提供真实值，不伪造现代替代方案。

## 验收与验证

- AC01 必需：同 Xcode 27.2 完整 pod lib lint（Core/UIKit/Foundation/SafeKit 和 import validation），无编译错误；相同规范化计数预计 35 条，逐条记录新增/剩余，禁用警告的构建开关不算修复。
- AC02 必需：新增工具类 XCTest 工程或独立 scheme，与现有 SafeKit 11 模式隔离；覆盖 plist nil/无效/正常、字典 nil key/keys、图片像素/位模式代表用例、权限查询路由、网络平衡 begin/end 与并发计数后 getter 状态、旧生命周期状态栏高度与原生对照。
- AC03 必需：窗口选择策略测试唯一/无候选/多候选/后台/隐藏/非普通级别/旧 delegate，实际模拟器单窗口集成确认 topVC 与状态栏；多 scene 策略以注入的候选数据验证，不冒充真实多 scene E2E。
- AC04 必需：加载指示器的类型/颜色/开始停止/状态恢复测试及模拟器截图，检查布局未出现明显回归。保留按钮旧布局不做重写，不以其 24 条警告已修复作为结论。
- AC05 必需：现有 SafeKit 11 模式 149 次回归通过；新增测试有非零执行、无跳过。新增行为能稳定复现的先 red 再 green；纯类型/注释改动使用编译前后证据。
- AC06 必需：独立两轮完整代码审查，最后 clean；输出逐类处置、警告前后统计与实际验证记录。未执行的真机、iOS 15 runtime、真实双 SIM/多 scene 验证明确列 NOT RUN，不作为本次必需验收。

## 参考

已阅读本机 Xcode 27.2 SDK 头文件的弃用声明以及 Apple 文档：
- https://developer.apple.com/documentation/uikit/uiapplication/keywindow?language=objc
- https://developer.apple.com/documentation/uikit/uibutton/titleedgeinsets
- CoreTelephony SDK 中 serviceSubscriberCellularProviders: Deprecated with no replacement, iOS 16。

## 独立审查与批准

独立 review_runtime 首轮 issues，两项均 ACCEPT：旧生命周期 statusBarHeight 不可静默降为 0；网络 getter 状态不可当作无外部可见行为。v2 据此保留 3 条兼容性警告，并以 stdatomic 消除 2 条 OSAtomic 警告。review_runtime 对 v2 完整复审结论 clean。实施注意 atomic_fetch_add 返回旧值，并用串行化计数/属性写入防止并发旧快照覆盖最终状态；原有 AC02 并发 getter 验收覆盖此约束。尚未修改产品源码。批准仅适用于本方案范围，不包含后续发布。

用户于 2026-11-14 回复“确认”，批准 v2；批准前方案 SHA256：c18e24d70a36f388a530eb49e9f533a8b611b44f5e29333e71365ef6d1b1a37f。
