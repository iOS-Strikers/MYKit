# 示例与仓库维护文件更新方案 v1

状态：Approved（用户已确认）；基线/HEAD 19f5023，master 领先 origin/master 1 个提交；本轮开始时工作区干净。

## 用户目标与调查

用户标红 Example、.gitignore、.travis.yml、LICENSE、_Pods.xcodeproj，要求更新。按内容实际适配当前 iOS 15 最低版本与 MYKit 2.0.0，不为更新时间空改文件。

- Example/Podfile 声明 iOS 8，project 部分为 8/9.3；锁文件 MYKit 1.1.3、SDWebImage 4.2.3、MJRefresh 3.1.15.7、CocoaPods 1.6.1。
- 132 个 Example/Pods 文件已纳入 Git；根 _Pods.xcodeproj 为指向 Example/Pods/Pods.xcodeproj 的符号链接。
- Example/Tests/Tests.m 是 XCTFail 占位测试。
- 未知方法示例 someMethod: 未登记签名，且带冒号的方法用无参数 performSelector 调用，与 2.0.0 不兼容。SafeKit 列表 FoundationViewController 名称不匹配真实 MYFoundationViewController。
- 示例上报使用已弃用 alert；UncaughtException 按钮执行非法指针 free/写入，超出库防护契约。
- .travis.yml 仍使用 Xcode 7.3 / Simulator 9.3。Travis 官方当前公开镜像表仅列到 Xcode 14.2，无法满足现有测试结果解析器所需的现代 xcresulttool。GitHub 官方 macos-15 runner 镜像已列 Xcode 26.x、CocoaPods 1.17.0。
- LICENSE 是 MIT，2019 sunjinshuai；保留原作者、邮箱和完整授权条款。

这是示例行为、依赖与 CI 迁移，采用完整流程，批准前仅调查和方案。

## 更新设计

1. **Example**
   - 项目/应用/测试统一最低 iOS 15，修正现代 Xcode 构建必需的旧配置；示例版本信息对齐 2.0.0，但不改库 podspec 版本。
   - 仍依赖本地 MYKit（:path => '../'）；将示例 SDWebImage 更新至 5.x、MJRefresh 更新至 3.7.x；研究时官方最新 tag 分别为 5.21.7、3.7.9，最终以 CocoaPods 解析并锁定的可用版本为准。只适配现有少量调用，不全面重写示例 UI。
   - 新增根 Gemfile / Gemfile.lock，将 CocoaPods 及其依赖版本固定并与全局 cocoapods-spm 插件隔离。保留 Podfile.lock、真实 .xcodeproj、共享 scheme 与 .xcworkspace 入口。
   - 对未知方法示例使用专用 demo 类，分别为实例/类方法登记精确签名，再通过参数与返回类型匹配的消息调用展示；保留未登记消息失败的库契约，不修改 SafeKit。
   - 修正错误页面路由；示例错误上报改为日志，避免自动弹窗干扰演示与测试。KVO/Timer/Notification 示例按当前契约做必需修补，保证明确演示动作不意外崩溃。
   - 将非法内存访问示例改为“防护不覆盖任意信号/非法指针”的说明页，不再提供默认触发进程崩溃的按钮。
   - 替换占位 XCTest 为真实示例启动、路由、签名兜底、KVO/Timer/Notification 生命周期 smoke tests；按实际行为断言，不用空断言凑通过。补 Example/README.md 和少量 UI 验证入口/稳定标识，必要时用 XCTest 渲染截图或 UI 测试验证关键页面。
2. **.gitignore**
   - 整理 Xcode 临时状态、DerivedData、构建产物、xcresult、本地 Bundler 目录和 CocoaPods 生成目录规则；保留 lockfile、共享 scheme、workspace 配置可追踪。
   - 取消跟踪旧 Example/Pods 生成文件，由 bundle exec pod install 按锁文件恢复；不提交新下载的第三方源文件。保留依赖自己的许可证在安装目录，不改其内容。
3. **.travis.yml → GitHub Actions**
   - 删除不可用的 Travis 配置，新增 .github/workflows/ci.yml。使用官方支持的 macos-15 runner 和其可用 Xcode；记录实际版本并检查测试工具前提，不写不存在的 SDK 路径。
   - 工作流仅构建/测试：PR、push、手动触发；contents: read，第三方/官方 actions 固定经核实的 revision；无发布令牌、无 CocoaPods 自动发布。
   - 执行依赖锁定安装、Example 构建与真实测试、SafeKit 11 模式矩阵、Utilities 测试、pod lib lint --allow-warnings；保存失败/成功日志、xcresult/summary。新增可本地复用的 ci 脚本，选择实际可用的 iPhone 模拟器，不固定本机 UDID。
   - 使用仓库自身 runner / xcresult 解析，不依赖用户 ~/.codex 技能路径。保留准确的非零测试、缺失/跳过失败检测。
4. **LICENSE**
   - 仅将版权年份更新为 2019–2026；保持 sunjinshuai、原邮箱及 MIT 正文逐字不变。不改许可类型、不添加未证实的权利人。
5. **_Pods.xcodeproj**
   - 删除根目录的生成工程快捷链接，文档统一引导打开 Example/MYKit.xcworkspace。该链接目标由 pod install 生成，属于构建依赖而非独立源码工程。
6. **关联文档**
   - README 中旧 Example 不可构建说明改为经过实际验证的接入/运行步骤；记录依赖、CI 和验证限制，不宣称未执行的远程 CI 已通过。

## 验收标准

- AC01 必需：在当前 Xcode 27.2 / iOS 26.5 模拟器，使用锁定依赖从干净隔离副本恢复 Pods，Example 构建、启动和非零 smoke tests PASS。
- AC02 必需：示例未知方法页已登记真实签名、菜单页面可创建，KVO/Timer/通知关键操作与退出不崩溃；说明页无非法内存写；关键页面截图实际检查。涉及稳定行为的修复尽可能先红后绿，构建环境失败与业务 red 分开记录。
- AC03 必需：现有 SafeKit 11 模式 149 次执行及 Utilities 12 项回归保持通过，pod lib lint 成功；已批准保留的 35 条兼容警告不要求在本轮清零。
- AC04 必需：CI YAML 语法、action revisions、运行器与工具版本要求核验；相同本地 CI 脚本链路实际执行通过。远程 Actions 因本轮不推送为 NOT RUN，不用本地结果冒充。
- AC05 必需：从干净副本可按 Gemfile.lock / Podfile.lock 安装，tracked 列表不含 Pods 生成代码或 _Pods.xcodeproj；git check-ignore 确认结果产物被忽略、lockfile/共享scheme未误忽略。
- AC06 必需：LICENSE 除首行年份外完全一致；MIT 声明保留。独立至少两轮完整 code review，最终 clean，Action 有实际命令与边界。

## 不包含

不修改 MYKit 公共 API/防护算法，不修复另案记录的 colorAtPixel 边缘缺陷；不全量重设计示例；不自动提交/推送、不改已有提交或 2.0.0 标签、不再次发布 CocoaPods、不启用付费 CI 或改 GitHub 设置。19f5023 仍为已存在的本地提交。

## 参考与风险

- https://docs.travis-ci.com/user/reference/osx/
- https://github.com/actions/runner-images/blob/main/images/macos/macos-15-Readme.md
- 官方 release API：SDWebImage/SDWebImage 5.21.7，CoderMJLee/MJRefresh 3.7.9。
- 依赖升级可能需适配；只修改 Example 范围。实际发现需改库 API 或扩大范围时再另行确认。
- 真机、iOS 15 runtime、远程 Actions 执行暂不作为本轮必需验证；明确 NOT RUN。

## 审查与授权

独立 review_runtime 已核查实际文件和方案，结论 clean，无阻断问题。待用户批准。所有新增路径均为计划新增；未修改实现。

用户于 2026-11-14 回复“确认”，批准 v1；批准前 SHA256：db857c13cacdaebf6fc9d0a31608ff40a5d1466e4f6674faf8c906dcb389fbfa。
