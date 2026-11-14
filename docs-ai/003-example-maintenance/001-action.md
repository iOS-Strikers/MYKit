# 示例与仓库维护文件更新记录

## 范围与授权

基线与 HEAD：`19f5023c12fc3c0fd3e9da577d39744dc84c78f3`。用户于 2026-11-14 回复“确认”，批准 `000-plan.md` v1；批准前 SHA256 已记录。本轮修改保留在工作区，不提交、推送、改标签或发布 CocoaPods。

本轮仅更新 Example、依赖与构建配置、CI、仓库维护文件和相关文档；`MYKit/` 库源码、`MYKit.podspec`、`Tests/` 独立测试未修改。取消跟踪旧 Pods 生成文件，但保留本地安装供构建使用。

## 实际修改

- Example 与 Pods target 最低 iOS 15；示例版本 2.0.0 / 20000，仍使用本地 MYKit。锁定 SDWebImage 5.21.7、MJRefresh 3.7.9、CocoaPods 1.17.0；Gemfile.lock 含 arm64/x86_64 Darwin 和 ruby 平台。
- 修正 Foundation 页面路由；未知方法使用独立演示类，分别登记实例类与元类的 `@@:@` 完整签名，通过匹配参数/返回值的 `objc_msgSend` 调用。未登记方法仍抛出异常。
- KVO 演示有效属性的重复登记、两次正常移除、第三次多余移除及移除后不再通知；保留原生重复通知语义。Timer 与 Notification 使用正确的回调参数，增加可观察的计数；控制器退出释放由测试验证。
- 上报改为日志；非法指针操作移除，改为防护边界说明。替换占位测试为 8 项真实 XCTest，包含六个关键页面截图。
- Example 工程及其 MYKit Pods target 开启 ARC 异常清理。原因及局限见下文。
- 整理 `.gitignore`，取消跟踪 132 个旧 Pods 文件，删除 `_Pods.xcodeproj` 生成工程快捷链接；保留真实工程、共享 scheme、workspace、lockfile。
- 用 `.github/workflows/ci.yml` 替换 Travis；macos-15、只读权限、固定 actions revision、显式选择已安装 Xcode 26+。`ci/run.sh` 按版本选择最新可用 iPhone runtime，执行锁定依赖安装、Example、SafeKit 矩阵、Utilities、lint；保存日志和 xcresult，结果检查拒绝零测试、缺失、跳过和失败。
- LICENSE 仅将原年份改为 2019–2026，原作者、邮箱和 MIT 正文完全保留；补 Example/README.md，更新根 README。

## 实际环境与命令

2026-11-14；Xcode 27.2（27B52）；iPhone 17 Pro / iOS 26.5；UDID `50C308FC-04F8-4B6C-9F3B-5028FC63FF1B`。本地 Ruby 4.0 与 Bundler 4.0.16，CI 配置 Ruby 3.3；未在 GitHub runner 实际执行。Xcode 使用进程级 `DEVELOPER_DIR`，未修改全局 xcode-select 或擦除模拟器。

下列路径以本次工作目录（仓库的上两级）为起点：`work/MYKit` 是仓库，`work/` 保存执行日志，`outputs/示例维护证据/` 保存可交付证据。

```sh
# 仓库根目录，PATH 中使用 Homebrew Ruby 和该 Ruby 对应的 gem bin
bundle install
bundle exec pod update MYKit SDWebImage MJRefresh --no-repo-update --project-directory=Example
bundle exec pod install --project-directory=Example
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer ci/run.sh ../example-ci-final

# 不含 Pods 的干净副本：安装后构建、启动并执行全部示例测试
BUNDLE_GEMFILE=../example-clean-final/Gemfile bundle exec pod install --deployment --project-directory=../example-clean-final/Example
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild test \
  -workspace ../example-clean-final/Example/MYKit.xcworkspace -scheme MYKit-Example \
  -destination 'platform=iOS Simulator,id=50C308FC-04F8-4B6C-9F3B-5028FC63FF1B' \
  -derivedDataPath ../example-clean-final-build -resultBundlePath ../example-clean-final.xcresult \
  -only-testing:MYKit_Tests
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer python3 ci/check-tests.py \
  ../example-clean-final.xcresult Example/Tests/acceptance.json
```

首次依赖更新因 CDN 两个 SDWebImage spec 的 HTTP/2 framing error 失败；通过 `curl --http1.1` 从同一官方 CDN 获取 5.21.6/5.21.7 JSON，验证版本后缓存，随后安装成功。未修改全局 CocoaPods 代码或更换依赖源。

## 验收结果

| AC | 实际结果 | 证据 |
|---|---|---|
| AC01 | PASS：干净副本锁定安装 exit 0；Example 构建、启动、8/8 测试通过 | `work/example-clean-final-install.log`、`work/example-clean-final-test.log`、`work/example-clean-final.xcresult`、`work/example-clean-final-summary.log` |
| AC02 | PASS：六个菜单路由可导航，签名返回/失败契约、KVO/Timer/通知释放、无破坏性按钮；6 页截图实际检查 | `Example/Tests/Tests.m`、`Example/Tests/acceptance.json`、`outputs/示例维护证据/最终截图/` |
| AC03 | PASS：SafeKit 11 模式共 149 次执行、Utilities 12 项全部通过；lint exit 0 | `work/example-ci-final/safekit/summary.json`、`utilities/summary.json`、`lint.log` |
| AC04 | PASS（本地）：完整 ci/run.sh exit 0；YAML 解析、bash 语法、固定 action SHA、Xcode 选择代码在本机执行成功 | `work/example-ci-final.log`、`work/example-workflow.json`、`work/example-github-env` |
| AC05 | PASS：干净副本无 Pods、无快捷链接即可恢复；索引无 Pods；临时产物被忽略，锁文件/scheme/workspace未误忽略 | 干净副本安装记录；`git ls-files`、`git check-ignore --no-index --stdin` 断言 |
| AC06 | LICENSE PASS；独立审查第1轮问题已接受并修复，最终结果外置记录 | 精确文本比对仅年份变化；外置独立复审记录 |

`ci/run.sh` 中 Example 最初通过后，仅调整了截图测试的动画开关；其最终版本已在干净副本完整 8/8 重跑通过。SafeKit、Utilities、lint 涉及源码与配置未随该截图调整变化，无需重复完整矩阵。

## 回归证据与发现

1. **菜单路由 red → green**：`work/verification/example-red/run-8ziyfdye/command.log` 明确失败于不存在的 `FoundationViewController`；修正为真实类后通过。构建成功后的目标断言失败，不是环境失败。
2. **KVO 测试预期校正**：初稿错误期待重复登记只通知一次。对照已有 `testKVODuplicateAndContextlessNativeParity`，确认两次通知是保留的原生语义；修正预期，并增加移除后的静默变更，未修改库行为。
3. **异常展开清理 red → green**：增加第三次多余移除后控制器不能释放；即时断言与两秒等待均失败（`work/example-ci-run1/example/command.log`、`work/example-kvo-recheck.log`）。单变量 `CLANG_ENABLE_OBJC_ARC_EXCEPTIONS=YES` 复测通过（`work/example-kvo-arc-exceptions.log`）。最终将设置写入示例工程及 MYKit Pods target，恢复即时释放断言，干净副本全部通过。只改变构建配置，不修改 SafeKit 算法。
4. **截图**：初次即刻截图碰到 UIButton 标题切换动画的透明帧；最终测试仅在截图范围临时关闭动画并在 finally 恢复。最终 KVO/通知截图分别可见 2 次/1 次通知结果；其余菜单、签名说明、Timer、边界页内容已实际检查。程序化导航和 XCTest 图片不冒充真机触摸验收。

## 独立审查

Reviewer：独立会话 `/root/review_runtime`，只读审查。

- Round 1：发现 macos-15 默认 Xcode 与现有场景窗口测试不匹配风险。**ACCEPT**，工作流显式选择 Xcode 26+，脚本优先最新 iOS runtime；本地执行选择逻辑得到实际 Xcode.app，全部测试链路通过。
- 本文在最终审查前定稿。第2轮及可能后续轮次、当前快照 clean 与总 Evidence Gate 结论保存在外置复审记录中，不预填未发生的结果。

## 限制与边界

- 远程 GitHub Actions、Intel runner / Ruby 3.3 组合、真机、iOS 15 runtime：NOT RUN；已按批准方案保留为非必需边界。最低部署版本 15 不等于已在 iOS 15 真机验证。
- lint 仍保留前轮批准的兼容警告；本轮不清零历史 SDK deprecated/unused 等诊断。现代 XCTest 与最低部署版本可能产生链接版本警告。
- ARC 异常清理仅在示例集成启用，库 podspec 未修改；其他消费项目仍需核实该构建选项，不能宣称所有集成都已修复此异常路径的释放问题。
- 已存在的 colorAtPixel 边缘问题、完整示例 UI 重设计、公共 API/版本/发布不在本轮范围。
- 无新增提交或推送，无 CocoaPods 发布，无生产或账号设置变更。
