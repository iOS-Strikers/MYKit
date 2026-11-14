# MYKit

面向 iOS 的 Objective-C 工具库，提供 Foundation 扩展、UIKit 辅助功能，以及按需启用的异常防护。

## 模块划分

| CocoaPods 子模块 | 内容 |
| --- | --- |
| `Core`（默认） | 统一入口头文件，以及 Foundation、UIKit、SafeKit 三个模块 |
| `Foundation` | 集合、字符串、日期、数据及运行时等 Foundation 扩展 |
| `UIKit` | UIKit 扩展，依赖 Foundation 模块 |
| `SafeKit` | 容器/KVC、KVO、通知、定时器、未知方法及 NSNull 防护，依赖 Foundation 模块 |

源码位于 [`MYKit/Classes`](MYKit/Classes)，模块配置见 [`MYKit.podspec`](MYKit.podspec)。
SafeKit 需要显式启用，仅链接库不会自动安装防护 Hook。

## 版本与平台状态

SafeKit 的审查与修复已通过提交
[`8d2aa2a`](https://github.com/iOS-Strikers/MYKit/commit/8d2aa2ab40261a15e12498eaa60fd34263ded01d)
合入 `master`。

**2.0.0** 包含本次 SafeKit 修复，最低系统版本提高到 **iOS 15.0**。未知方法兜底需要显式登记真实签名。详见 [变更记录](CHANGELOG.md)。

| 项目 | 状态 |
| --- | --- |
| 库声明的最低系统版本 | iOS 15.0 |
| 独立 XCTest 宿主 | 最低部署版本为 iOS 15.0，不依赖 CocoaPods |
| 已验证环境 | Xcode 27.2（27B52）、iPhone 17 Pro 模拟器、iOS 26.5（23F77）、arm64 |
| 测试工具要求 | 完整 Xcode、可用的 iOS 模拟器和 Python 3 |
| 本次未验证 | 真机、旧版 iOS，以及与其他方法交换库组合使用的情况 |

## 安装

仅接入已审查版本的 SafeKit：

```ruby
pod 'MYKit/SafeKit', '2.0.0'
```

需要全部模块时，将 `MYKit/SafeKit` 改为 `MYKit`。也可以引用本地仓库：

```ruby
pod 'MYKit/SafeKit', :path => '../MYKit'
```

选择一种来源配置，然后在应用工程中执行 `pod install`。
按旧版本号安装（`pod 'MYKit', '1.1.3'`）不会选中本次修复后的源码。

## 快速接入

注册错误上报对象，并按需开启防护。建议在需要保护的业务操作开始前完成注册：

```objc
#import <MYKit/MYSafeKit.h>

@interface AppSafeKitReporter : NSObject <MYSafeKitRecordProtocol>
@end

@implementation AppSafeKitReporter
- (void)recordWithReason:(NSError *)reason {
    NSLog(@"SafeKit: %@", reason);
}
@end

// 放在应用启动逻辑中：
[MYSafeKit registerRecordHandler:[AppSafeKitReporter new]];
[MYSafeKit registerSafeKitShieldWithAbility:
    MYSafeKitShieldTypeContainer | MYSafeKitShieldTypeKVO];
```

调用 `registerSafeKitShield` 相当于启用 `MYSafeKitShieldTypeAll`，但不代表可以恢复所有崩溃。
库会持有上报对象；向 `registerRecordHandler:` 传入 `nil` 只会清除上报对象，不会撤销已安装的防护 Hook。

## SafeKit 防护行为与边界

只开启应用需要的防护能力。注册对整个进程生效，可以追加能力，不能撤销；重复注册是幂等操作。
`All` 包含全部六类防护，但不提供任意崩溃恢复保证。

| 防护能力 | 支持行为 | 使用边界 |
| --- | --- | --- |
| Container | 数组/字典构造、已采样 Foundation 类簇的读取与修改、字符串操作、NSObject 默认 KVC 处理 | 非法对象读取返回 `nil`，非法字符读取返回 `0`，查找失败返回 `NSNotFound`；非法写入整批拒绝；构造时过滤 `nil` 元素或键值对。不覆盖无效 C 指针、集合并发修改、任意自定义子类，也不保证覆盖未来所有 Foundation 私有类。 |
| KVO | 按 observer/keyPath/context 独立登记，支持重复观察、原生选项、匹配移除和观察双方释放清理 | 业务回调异常继续向外抛出。iOS 26.5 对照确认，`Initial` 回调发生在新监听安装之前，回调抛异常时不会留下新登记；安装前移除该新监听属于无匹配移除，会记录错误并忽略。启用防护前已有的原生监听仍可移除。不调用 NSObject KVO 方法的自定义实现不在 Hook 范围内。 |
| Notification | 清理 selector 形式的通知监听，以弱引用记录通知中心并去重 | block 监听 token 保留原生生命周期，调用方仍需负责移除。 |
| Timer | 两个 target/selector 工厂方法创建的重复定时器使用弱 target；target 释放后，下一次触发会使定时器失效 | 单次定时器保持原生语义；不包装 block 定时器和直接初始化方法。弱 target 是有意的持有关系变化，需要保证其存活时，应由其他对象持有。 |
| UnrecognizedSelector | 仅对显式登记、运行时类精确匹配且具有明确类型签名的方法进行兜底 | 未登记的方法保持原生失败行为。已有动态解析、消息转发及自定义转发异常优先；不能从方法名推断真实签名。 |
| Null | 使用固定且具有真实类型签名的 selector 白名单 | 不等同于向 `nil` 发送任意消息。白名单之外的消息保留原有转发行为。 |

### 兼容性变化

旧版未知方法防护使用统一返回 `int` 的占位实现，存在 ABI 不匹配风险。此前依赖“吞掉任意未知方法”的应用，需要迁移到显式签名登记。
这是 2.0.0 的不兼容行为变化。最低系统版本也由 iOS 8.0 提高到 iOS 15.0。

```objc
// 调用方必须保证编码与真实调用一致，且方法不使用可变参数。
// 注册校验无法独立证明 ABI 正确；登记类方法时传入元类。
BOOL accepted = [MYSafeKit registerFallbackForClass:[MyModel class]
                                         selector:NSSelectorFromString(@"optionalDouble")
                                     typeEncoding:"d@:"];
[MYSafeKit registerSafeKitShieldWithAbility:MYSafeKitShieldTypeUnrecognizedSelector];
```

注册时会校验编码语法、支持的类型和参数数量，拒绝冲突签名、已有方法、联合体、数组、位域、不透明结构体及其他不支持的编码。
编码本身无法证明真实调用的 ABI，也无法识别调用方是否使用了可变参数。

支持的返回值按登记签名的返回长度清零；不会为缺失的 selector 永久添加方法实现。
登记只匹配实际运行时类，不会自动覆盖所有子类。

其他行为修复包括：

- 字典下标赋 `nil` 恢复为删除对应键。
- KVC 可以正常清空对象属性，仅链接 MYKit 不再改变 KVC 行为。
- 字符串截取位置等于长度、空字符串等合法边界保持 Foundation 行为。
- 非法字符串写入不再通过截断范围来部分修改数据。

### NSNull 白名单

下列每次兜底都会记录一次 Null 事件，上报重入保护抑制的事件除外。
参数不会被解引用，也不会被转发到空集合执行；`nil` 键和越界索引同样使用表中规定的返回值。

| selector | 返回值 |
| --- | --- |
| `length`、`count` | `NSUInteger` 类型的 `0` |
| `intValue`、`integerValue`、`longLongValue`、`unsignedLongLongValue`、`doubleValue`、`floatValue`、`boolValue` | 按实际返回类型返回 `0` 或 `NO` |
| `objectForKey:`、`objectForKeyedSubscript:`、`objectAtIndex:`、`objectAtIndexedSubscript:` | `nil` |
| `characterAtIndex:` | `unichar` 类型的 `0` |
| `substringFromIndex:`、`substringToIndex:`、`substringWithRange:` | `nil` |

### 错误上报

上报对象由库持有，并在触发防护的线程上同步接收错误，因此实现必须支持并发调用。
替换上报对象时有同步保护；执行回调时不持有上报对象锁。同线程的递归上报会被抑制，上报对象自身抛出的异常会被隔离。

错误信息保留原有的 `com.xxshield.<bundle identifier>` 错误域，使用防护能力值的负数作为错误码，并包含错误描述和 `callStack` 字段；调用栈最多保留 32 帧。

已弃用的弹窗辅助 API 会调度到主线程执行，不是默认上报机制。不要在错误上报回调中执行依赖可用 UI 的恢复操作。

## 测试与验证

最近一次有记录的验证包含 **29 个测试方法、11 种进程隔离配置，共执行 149 次，全部通过，无跳过或缺失用例**。
已完成两轮独立代码审查，最终无未解决问题。这些是对应源码版本的验证记录，不代表实时 CI 状态。

实现与验收细节见[交付记录](docs-ai/001-safekit-review/001-action.md)。该记录描述验收时的状态；当前合并与版本状态以上文说明为准。

独立工程 [`Tests/SafeKitTests.xcodeproj`](Tests/SafeKitTests.xcodeproj) 包含最小应用宿主、XCTest 测试包和独立 framework 测试模块，不依赖 Example 工程，也无需执行 `pod install`。

在仓库根目录选择可用模拟器：

```sh
export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
xcrun simctl list devices available
```

将 `YOUR_SIMULATOR_UDID` 替换为实际模拟器标识，然后运行完整矩阵：

```sh
python3 Tests/run-tests.py \
  --udid YOUR_SIMULATOR_UDID \
  --output /tmp/mykit-results
```

**输出目录必须尚不存在。** 每次运行使用新路径，避免覆盖已有证据。
也可以仅运行指定模式：

```sh
python3 Tests/run-tests.py \
  --udid YOUR_SIMULATOR_UDID \
  --mode Container --mode KVO \
  --output /tmp/mykit-container-kvo-results
```

| 配置 | 验证目的 |
| --- | --- |
| `Native` | 未启用防护时的 Foundation 行为，包括 KVO 原生语义对照 |
| `Container`、`KVO`、`Unknown`、`Null`、`Notification`、`Timer`、`Record` | 各项能力及上报机制的独立验证 |
| `All` | 全部防护组合运行 |
| `Reverse` | 反向注册防护能力 |
| `Concurrent` | 首次并发安装全部防护 |

运行脚本按照 [`Tests/matrix.json`](Tests/matrix.json) 选择精确用例，要求所有选定用例通过；缺失或跳过用例都会判定失败。
标准运行会在输出目录中保存 `summary.json`、各模式的命令、日志、测试结果树和 `.xcresult`，以及共享的 DerivedData。
[`acceptance`](Tests/acceptance) 目录提供逐项验收清单，供可选的证据验证器集成使用。

仓库已包含可直接使用的 Xcode 工程。只有调整工程包含的源文件时，才需要运行 `ruby Tests/generate-project.rb` 重新生成；该维护步骤依赖 Ruby 的 `xcodeproj` gem。

## 示例工程

[`Example`](Example/README.md) 最低支持 iOS 15，使用本地 MYKit 2.0.0，包含 8 项启动、路由、签名契约、生命周期与截图测试。

```sh
bundle install
bundle exec pod install --deployment --project-directory=Example
open Example/MYKit.xcworkspace
```

选择 `MYKit-Example` scheme。完整本地验证执行 `ci/run.sh`；GitHub Actions 使用相同入口运行示例、SafeKit 11 模式、Utilities 测试及 CocoaPods lint。Pods 由锁文件恢复，不再提交生成代码。完整测试链路需要 Ruby 3.3+、Xcode 26+ 与 iOS 26+ 模拟器；详见 [示例说明](Example/README.md)。

## 作者与许可证

作者：sunjinshuai — sunjinshuai@aikucun.com。

本项目使用 [MIT 许可证](LICENSE)。

## 工具类兼容性说明

- 窗口、顶层控制器、状态栏尺寸及调试类名标签接口应在主线程调用。全局查询只选择唯一的前台活跃场景中可见、普通级别的 key window；存在多个候选时返回 nil/0。有具体视图上下文时应使用该视图的 window。旧 AppDelegate 生命周期仍使用 delegate.window 和原生状态栏高度。
- `setButtonImageTitleStyle:padding:` 仅适用于 `configuration == nil` 的旧式 UIButton。十种图文布局继续保留原实现，不自动转换成 UIButtonConfiguration。
- MD2/MD4/MD5 方法只用于兼容已有摘要、协议和标识符，不用于密码存储或安全校验；新摘要需求可使用现有 SHA256 方法。
- `getCarrierName` 依赖已经废弃且没有等价替代的运营商接口，现代系统可能不再提供真实运营商名称。
- `beganNetworkActivity` / `endedNetworkActivity` 保留计数与旧属性状态，但 iOS 15 不再显示旧状态栏网络图标。需要可见加载反馈时由应用自身提供 UI。

本轮编译警告处置及验证见 [修复记录](docs-ai/002-compiler-warnings/001-action.md)。
