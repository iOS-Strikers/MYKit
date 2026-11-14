# GitHub Actions 并行验收优化方案 v1

状态：Approved（用户已确认）；当前基线 `640ef8388ebfa30ace5b96fba9196646573a7b88`。本轮只调查、编写方案，未修改生产 CI 或测试实现。

## 目标与证据

用户要求降低约 42 分钟的 GitHub Actions 耗时，不能减少测试覆盖。

成功基线：https://github.com/iOS-Strikers/MYKit/actions/runs/43583767208

- test job：10:07:35–10:50:30 UTC，共 42 分 55 秒；主要验证步骤 42 分 30 秒。
- 13 次 Xcode 测试会话的 `Testing started completed` 耗时合计 2004.303 秒（33.4 分钟）；实际 XCTest 用例执行合计约 17.4 秒。
- Example：8 项，会话 222.607 秒；Utilities：12 项，会话 126.289 秒。
- SafeKit：11 个独立进程模式、149 次执行，会话合计 1655.407 秒（27.6 分钟）。Native 306 秒、KVO 227 秒，其余模式约 109–167 秒。
- 原流水线已有共享 DerivedData，后续模式日志没有再次全量编译。依赖安装和产物上传也不是主要瓶颈。
- 本地测试速度不能代表虚拟 runner；当前基线是 Xcode 26.3 / iOS 26.2。保持同一 runner 与工具链选择策略，先只优化调度，避免同时改多个变量。

完整时序来源已下载到工作目录 `work/actions-fixed-artifacts`；提取结果 `work/ci-timing-baseline.json`。项目为 public，使用现有标准 macos-15 runner，不启用付费 larger runner 或修改账号设置。

## 拟实施方案

### 五路并行，保留原命令语义

| 分组 | 执行内容 | 基线测试会话耗时合计 |
|---|---|---:|
| apps | Example 8 项＋Utilities 12 项，组内串行 | 349 秒 |
| safekit-a | Native、Null、Notification、Record | 646 秒 |
| safekit-b | KVO、Container、Timer | 466 秒 |
| safekit-c | Unknown、All、Reverse、Concurrent | 544 秒 |
| lint | 当前全部模块 CocoaPods lint | 原命令保持 |

- 每个 SafeKit 模式仍启动独立测试进程；不把 swizzle 注册、状态或环境混入同一进程。
- 每组保留共享 DerivedData。各组使用独立 runner、模拟器与输出目录，避免并发访问同一模拟器/构建目录。
- `fail-fast: false`，一组失败不取消其他组；不设置 continue-on-error，不自动重试掩盖失败。
- 并行上限 5。实际并发仍受账号/组织额度与排队影响，不保证总耗时上限。
- SafeKit 分组不安装与其无关的 CocoaPods 示例依赖；apps/lint 保留原锁定 Bundler 与 CocoaPods 路径。没有移除任何构建、导入、截图或 lint 检查。
- 本地 `ci/run.sh` 默认仍运行全部内容，也支持显式分组；增加可观察的分段耗时，后续能直接从 job 和摘要看到瓶颈。

### 覆盖完整性门禁

新增单一分组清单（拟 `ci/lanes.json`），工作流矩阵与本地分组执行从它读取，避免 YAML 与脚本两套模式列表漂移。清单校验要求 SafeKit 的 11 模式与 `Tests/matrix.json` 精确一致，重复、缺失或未知模式都失败。

保留最终 `test` 检查入口，所有并行组结束后运行（`if: always()`）。任何组失败、取消、跳过、产物缺失都不能得到最终成功。

汇总基于实际测试树，逐模式匹配当前 matrix 中的确切测试标识，并核验全部选中用例 Passed；Example/Utilities 对照各自 acceptance 清单，拒绝零测试、失败、跳过、缺失。校验总数为 Example 8、SafeKit 149、Utilities 12，共 169 次；同时核验 lint exit 0。仅数字相同而方法不同也不允许通过。

每组产物独立命名，保留命令、耗时、tests.json、summary 和 xcresult；下载同一次运行的全部分组证据，汇总失败时也保留报告。actions 固定已验证 revision，权限仍为 contents: read。

### 暂不做的优化

不删模式、不减少测试、不改断言、不根据变更路径跳过测试、不降低运行时验证或 lint 范围、不关闭代码覆盖采集来换速度、不改库 API/源码。不引入未验证的跨提交 DerivedData 缓存、不关闭系统服务或降低 runner 安全配置。

## 修改范围（均为拟修改/新增）

- `.github/workflows/ci.yml`：分组矩阵、独立产物、最终完整性检查。
- `ci/run.sh` 与小型分组/汇总脚本：执行选择、时间记录、精确覆盖验证；公共 runner `Tests/run-tests.py` 仅在实际需要记录时序时最小扩展。
- `ci/` 的 Python 回归测试：分组遗漏/重复、缺产物、错误标识、Skipped/Failed、组失败与成功汇总路径。
- `Example/README.md` / 根 README：说明并行入口、失败语义与本地全量命令。
- 本目录 `001-action.md`：完成后记录实际测量、审查和限制。

不修改 `MYKit/`、`MYKit.podspec`、现有 XCTest 测试源码与 acceptance/matrix 中的用例列表。

## 验收与衡量

1. **覆盖不变（必需）**：所有原测试源文件、matrix 与 acceptance 清单哈希保持一致；分组并集无重复且完整；实际远程记录仍为 169 次全部通过，lint 全量通过。
2. **失败不能被汇总掩盖（必需）**：对缺模式、重复模式、缺/错测试标识、Skipped、Failed、缺产物与组失败做失败回归；正常完整产物通过。
3. **本地可用（必需）**：分组命令与默认全量入口对应原有测试命令；执行受影响的本地流程和语法检查，必要时真实单组测试；不因调度变化重写业务断言。
4. **远程效果（必需）**：完成独立至少两轮代码审查、本地验证后提交并推送优化，等待该 SHA 的全部 Actions 完成，下载逐组证据核验。与 42 分 55 秒基线比较运行耗时并分开说明排队时间；目标在正常并发可用时减少至少 40%，预估 12–18 分钟不作为已证实结果。若未达到，继续根据真实时序定位；不能仅因任务拆分就声称优化成功。
5. **可回退（必需）**：保留本地串行全量入口；所有变化限于调度、证据与文档；工作流无自动发布或部署。
6. 最终 action、测试证据、两轮独立审查及当前快照一致；远程失败仍如实报告，不降低验收条件来求绿。

## 取舍与风险

- 并行降低等待时间，但可能增加总 runner 分钟数，因为 3 个 SafeKit 分组各自冷构建一次。不会擅自使用付费 runner；并发额度不足会削弱收益。
- 单次 A/B 受 runner 负载影响，最终报告提供实测数据，不把一次结果承诺为长期 SLA。
- 新增汇总器是风险点，必须优先验证漏跑/跳过/错误标识不能假绿，原始测试结果树与逐组 job 状态均保留。

## 依据

- GitHub matrix / max-parallel / fail-fast：https://docs.github.com/en/actions/how-tos/write-workflows/choose-what-workflows-do/run-job-variations
- 最终依赖任务 `always()`：https://docs.github.com/en/actions/how-tos/write-workflows/choose-what-workflows-do/use-jobs
- 本仓库已成功执行的 CI 与 xcresult 证据。

## 审查与授权

独立 review_runtime 已完成 Spec Review，结论 clean。实施时重点核对准备/下载失败不能跳过最终门禁、单一清单约束矩阵与执行器、按“模式＋测试标识”计数而非跨模式去重。等待用户批准本方案后实施。

用户于 2026-11-14 明确确认实施、推送并核对远程提速和覆盖；批准前 SHA256：c922be1dfc1a208f8646c2eaf923451bca6ccd0b0840779378100fc5bf6e62a3。
