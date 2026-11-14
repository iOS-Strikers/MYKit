# MYKit 编译警告修复记录

## 范围与授权

基线/HEAD 为 `3913b97`（已发布的 2.0.0）。用户于 2026-11-14 回复“确认”，批准 `000-plan.md` v2；批准前哈希和独立方案审查已记录。当前改动为本地未提交修改，不改版本号、标签，也不发布 CocoaPods。

本次修复 UIKit/Foundation 工具类及其公共标注、内部窗口选择和测试入口；未修改 SafeKit 防护源码及原有 11 模式测试。工作区初始干净，没有覆盖用户改动。

## 编译警告处置

CocoaPods 相同工具链、全部子模块、导入验证下，**88 → 35，消除 53 条**。统计单位为 CocoaPods 输出的 WARN 记录（含头文件导入重复项），不是未经去重的原始 clang 行数。原 88 条对应 77 个唯一源位置。保留诊断，没有新增 suppress pragma 或关闭警告的编译选项；仍需 `--allow-warnings`。

| 类别 | 原记录 | 现记录 | 处理 |
|---|---:|---:|---|
| NSArray / NSDictionary 空值标注（含导入重复） | 22 | 0 | 对照实现补全 nullable / nonnull，nil 输入与错误返回语义不变 |
| NSDate 文档 | 12 | 0 | 补齐参数、默认格式、毫秒单位和返回值 |
| UIImage 枚举 | 5 | 0 | 显式转换到 CGBitmapInfo，保持位模式 |
| 权限查询 | 4 | 0 | CLLocationManager 实例查询，移除旧 AddressBook 分支；另修正相机误查日历 |
| 三处加载指示器 | 3 | 0 | Medium + 明确 white / gray 颜色，保留布局和恢复路径 |
| 窗口与状态栏 | 6 | 1 | 统一 foregroundActive 场景候选选择；保留无 scene 的原生状态栏回退 |
| 网络指示状态 | 4 | 2 | stdatomic，计数和属性写入在同一锁内，保留 getter 可观察状态 |
| 旧 UIButton 十种布局 | 24 | 24 | 没有等价的统一配置迁移；保留旧式按钮契约 |
| MD2 / MD4 / MD5 | 7 | 7 | 不改变摘要/协议/标识符输出；文档明确兼容用途 |
| 运营商接口 | 1 | 1 | 替代接口同样废弃且没有等价新 API，保留原输出 |

`MYWindowContextInternal.h` 标记为私有头。全局窗口查询没有唯一候选时返回 nil/0，旧 delegate.window 仅在无 scene 时回退。调试类名优先使用实例的 view.window，以关联对象识别自己的标签，并以弱引用登记所有标签所属窗口，关闭时也能清理已断开场景的窗口，不误删同 tag 的业务视图。

## 验证结果

环境：Xcode 27.2（27B52），iPhone 17 Pro 模拟器，iOS 26.5，arm64；UDID `50C308FC-04F8-4B6C-9F3B-5028FC63FF1B`。进程级 DEVELOPER_DIR；未切换全局 Xcode、未擦除模拟器。

- CocoaPods 最终全模块 lint：PASS，35 条兼容性警告，包含编译和 import validation。
- 独立 Utilities XCTest：12 个方法，12 次执行，全部 PASS、无跳过，required 验收映射全部 PASS。
- SafeKit 原有 11 模式矩阵：PASS，29 个方法、149 次执行，全部通过且无跳过。
- 浅色/深色加载态截图：已实际检查，白色按钮指示器、灰色导航指示器、提交文字均可见，无明显裁切；深色仍保留既定灰色，而非另行调整产品配色。

主要命令（仓库根目录）：

```sh
# 发布时建立的隔离 CocoaPods 环境，不修改全局插件。
BUNDLE_GEMFILE=../release-tools/Gemfile \
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
/opt/homebrew/opt/ruby/bin/bundle exec \
/Users/mengxiang/.local/share/gem/ruby/4.0.0/bin/pod \
lib lint MYKit.podspec --platforms=ios --allow-warnings

DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
python3 /Users/mengxiang/.codex/skills/ios-e2e-verification/scripts/verify.py unit \
  --project Tests/UtilitiesTests.xcodeproj --scheme Utilities \
  --udid 50C308FC-04F8-4B6C-9F3B-5028FC63FF1B \
  --only-testing UtilitiesTests/UtilitiesTests \
  --acceptance Tests/acceptance/Utilities.json \
  --output ../verification/warnings-green4 --timeout 240

DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
python3 Tests/run-tests.py \
  --udid 50C308FC-04F8-4B6C-9F3B-5028FC63FF1B \
  --output ../verification/warnings-safekit-matrix \
  --verifier /Users/mengxiang/.codex/skills/ios-e2e-verification/scripts/verify.py
```

通用复跑入口为随代码提供的 `Tests/UtilitiesTests.xcodeproj` / `Utilities` scheme，可直接用 xcodebuild test；`Tests/generate-utilities-project.rb` 只用于维护源文件列表，需要 xcodeproj Ruby gem，不依赖旧 Example 的 CocoaPods 配置。`Tests/acceptance/Utilities.json` 保存精确验收方法名。

## 验收映射

| AC | 已执行证据 |
|---|---|
| AC01 | `warnings-lint-final.log`，35 条 WARN，退出码 0，所有子模块成功 |
| AC02 | `testPlistNilInvalidAndRoundTrips`、`testBitmapColorAndGrayConversion`、`testCameraPermissionUsesVideoAuthorization`、`testLocationAndContactsPermissionQueries`、`testNetworkBalancedAndConcurrentState`、`testNetworkNativeGetterParity`、`testLegacyStatusBarFallbackMatchesNative` |
| AC03 | `testWindowSelectionPolicy`（候选 fixture）、`testSceneWindowIntegrationAndClassLabelCleanup`（真实单 scene 宿主）、`testClassNameCleanupAfterSceneDisconnect`（断开场景 fixture）、legacy 原生状态栏对照 |
| AC04 | `testButtonIndicatorUsesModernStyleAndRestoresState`、`testLoadingViewsAndVisualEvidence`；两张 XCTAttachment 图片 |
| AC05 | 12 项工具测试及原 11 模式全矩阵，结果树与 required manifest |
| AC06 | 独立 Review round 1 两项 P2 ACCEPT 并补回归；终轮结论见外置独立审查记录，不预填未发生的 clean |

网络并发测试以 setter spy 观察调用序列，避免后台调用 UIKit 产生额外 UI 行为；另一项主线程原生 setter/getter 对照验证兼容结果，二者分开报告。多场景选择策略使用 fixture，不冒充真实多窗口 E2E。当前模拟器自动提供 scene；无 scene 分支通过注入的旧 delegate/window 与原生状态栏返回值作对照。

## Red / green 和测试校正

- `warnings-red`：原实现的相机查询错误路由、加载器旧样式真实断言失败；最终相同意图测试 PASS。
- `warnings-probes`：round 1 发现的断开场景窗口标签残留真实失败；新增弱窗口登记后 `testClassNameCleanupAfterSceneDisconnect` PASS。
- `warnings-green1` 为新测试宏参数中的数组逗号导致编译失败，属于测试构建问题，不当作产品 red。
- `warnings-green2`：纠正了“宿主一定无 scene”的测试假设；UIKit 当前实际有 scene。也发现 `colorAtPixel:(0,0)` 返回透明色。
- 将 `3913b97` 的原始 `colorAtPixel:` 方法作为临时独立命名 fixture 对照，`warnings-probes` 中同样失败，确认是既有边缘取色问题。本次只做枚举位模式修复，未扩展到图片算法；调查 fixture 已移除，没有保留复制的产品实现作为测试。
- `warnings-green3`：测试渲染器默认 3x，而既有灰度方法按 point 尺寸输出，造成 12px 与 4px 假设冲突；最终将代表性位模式测试显式固定为 1x、4×4 像素，检查内部像素颜色与灰度输出。没有修改算法或将错误边缘输出认定为正确功能。

## 边界

真机、iOS 15 运行时、真实双 SIM/多 scene E2E 未执行，NOT RUN。仍有 35 条有明确兼容理由的编译警告。本轮额外发现的 `colorAtPixel:(0,0)` 边缘问题未修复，作为独立遗留缺陷记录；不宣称整个工具库没有其他缺陷。

证据在当前任务的 `outputs/编译警告修复证据/`：原始命令日志、验收 manifest、结果树、警告清单、源码/测试哈希与截图。完整 xcresult 和 DerivedData 留在 `work/verification/`。文档变化不改变已验证的源码/测试内容；最终源码哈希为 `93f4f6da61d60a520bb237e4c817ed9a12387b84631398020323f830df20d7d1`。
