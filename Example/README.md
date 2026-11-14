# MYKit 示例

示例最低支持 iOS 15，使用本地 `../MYKit.podspec`（2.0.0）。第三方演示依赖锁定为 SDWebImage 5.21.7、MJRefresh 3.7.9。

## 安装与运行

需要完整 Xcode、可用的 iOS 模拟器和 Ruby 3.3 或更新版本。仓库用 Bundler 固定 CocoaPods 1.17.0；避免混用系统 Ruby 与其他 Ruby 安装的 gem。

在仓库根目录执行：

```sh
bundle install
bundle exec pod install --deployment --project-directory=Example
open Example/MYKit.xcworkspace
```

选择 `MYKit-Example` scheme 和 iPhone 模拟器运行。真机需要自行配置签名。`Pods/` 为生成依赖，不纳入版本管理；保留 `Podfile.lock` 与 `Gemfile.lock`。升级依赖时显式执行 `bundle exec pod update --project-directory=Example`，审查锁文件差异。

## SafeKit 演示

- KVO：点击按钮，重复登记同一观察关系、变更有效属性，再重复移除；保留原生的两次通知语义，第三次多余移除由防护层处理，移除后再次变更不再通知。
- Timer：显示触发次数；退出后目标可释放，下次触发时失效的代理会停止定时器。
- Foundation：保留字符串越界防护演示，控制台显示报告。
- UnrecognizedSelector：专用演示类分别登记实例和类方法的完整签名，再调用带一个对象参数、返回对象的方法；兜底返回 nil。未登记的方法仍会抛出异常。
- Notification：点击按钮发送通知并显示次数，退出后 selector observer 可被清理。
- UncaughtException：说明防护边界，不执行非法指针或信号崩溃操作。

防护报告写入 Xcode 控制台，不自动弹出对话框。这些演示不能替代业务输入校验，也不代表任意崩溃均可恢复。

## 测试与 CI

Xcode 的 Product → Test 执行 `MYKit_Tests` 的 8 项 smoke tests，覆盖启动、真实菜单路由、签名契约、生命周期、边界说明及关键页面截图。截图保存在测试结果 attachments 中。

在仓库根目录运行完整验证：

```sh
ci/run.sh
# 可指定已经存在的模拟器和新的输出目录：
SIMULATOR_UDID=<UDID> ci/run.sh /tmp/mykit-validation
```

脚本使用当前 Xcode，自动选择可用 iPhone 模拟器（或显式 UDID），依次安装锁定依赖、运行 Example、SafeKit 11 模式、Utilities 测试及 `pod lib lint --allow-warnings`。完整测试链路要求 Xcode 26+、iOS 26+ 模拟器，并提供 `xcresulttool get test-results tests`，测试结果必须非零且所有必需用例实际通过。产物默认放在被忽略的 `.artifacts/`。

GitHub Actions 使用 macOS 15 runner，显式选择已安装的 Xcode 26 或更新版本、最新可用 iPhone runtime、固定 revision 的 actions 和 Ruby 3.3；只验证，不发布 CocoaPods。依赖下载仍需要网络。远程 Actions、真机及 iOS 15 runtime 的结果须与本地模拟器验证分别确认。

## 异常清理配置

示例工程及 Podfile 中的 MYKit target 启用 `CLANG_ENABLE_OBJC_ARC_EXCEPTIONS=YES`。SafeKit 会捕获 Objective-C 异常，异常展开时也需要释放 ARC 局部引用；本次多余 KVO 移除测试在缺少此设置时观察到控制器未释放，启用后通过释放断言。此配置仅修正示例构建，本轮没有修改库 podspec；其他集成应单独核实异常清理设置。
