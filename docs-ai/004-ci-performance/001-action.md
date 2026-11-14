# CI 并行优化实施记录

## 授权与范围

基线 `640ef8388ebfa30ace5b96fba9196646573a7b88`。用户明确批准方案 v1、实施和推送，要求等待 Actions 完成并核对实际提速，测试覆盖不减少；批准哈希见 `000-plan.md`。

此记录在推送前独立复审前定稿。远程性能与覆盖的最终结果，以本次提交的 Actions 产物及本次任务交付的实测报告为准；此处不预填尚未发生的成功或速度。

## 已实施

- `ci/lanes.json` 是五路分组的唯一来源；准备任务和本地执行器共同读取并验证所有原 SafeKit 模式恰好出现一次。
- `.github/workflows/ci.yml` 使用原有 macos-15 / Xcode 26+ 选择逻辑，最多五路并行、fail-fast false。SafeKit 三组免装无关 Pods；apps/lint 仍使用锁定 Bundler/CocoaPods。没有增加付费 runner 或修改账号设置。
- `ci/run.py` 复用原有构建、测试与 lint 命令；`ci/run.sh` 保留默认本地全量入口，新增 --lane 选择。输出目录要求不存在，防止旧产物混入。每步骤记录命令、退出码与耗时，分组最终记录 SHA 和状态。
- `ci/validation.py` 汇总各组实际 tests.json；按“模式＋测试标识”精确匹配当前 matrix/acceptance，拒绝缺失、额外、重复、Skipped/Failed 和空测试。核对组状态、相同 SHA 与 lint exit 0。最终 test 任务 always 执行；准备或分组失败、取消、跳过以及下载/解析失败均无法成为成功。
- 产物按组隔离保存；默认下载行为保留组目录。保留全部日志、结果树、xcresult 和独立的覆盖汇总报告，不上传 DerivedData。
- 原库源码、podspec、XCTest 源码、原 matrix/acceptance 清单、进程隔离和断言未改。原 169 次测试和 lint 全量保留；另新增 13 项调度/汇总器回归测试。

## 本地验证

2026-11-14，当前 Xcode 27.2 / iOS 26.5；未切换全局 Xcode、未擦除模拟器。

- `PYTHONDONTWRITEBYTECODE=1 python3 -m unittest discover -s ci -p 'test_*.py'`：13 项 PASS。覆盖完整分组、遗漏/重复/未知模式、非 SafeKit 组缺失、错误/缺失/重复测试标识、Skipped/Failed、缺产物、错误 SHA、失败/取消/跳过的 job、lint 失败，以及全量/分组命令等价性。新功能测试初次运行因模块尚未实现失败；这不是业务 bug 的 red 回归，不将其冒充为业务失败证据。
- `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer ci/run.sh ../ci-parallel-local-b --lane safekit-b`：exit 0；KVO 15＋Container 11＋Timer 6，共 32 项 PASS，无超时。产物在工作目录 `work/ci-parallel-local-b`。
- 将成功基线远程 raw tests.json 按新分组回放汇总：Example 8＋SafeKit 149＋Utilities 12，11 模式、169 次准确通过。仅验证汇总兼容性，不冒充本轮远程执行。
- YAML 解析、`bash -n ci/run.sh`、`git diff --check`：PASS。
- 与基线对比，原库及 XCTest、matrix/acceptance 文件未修改；不会用新增调度测试替代原有测试。

## 审查与远程测量

独立 reviewer `/root/review_runtime` 第1轮完整审查 clean，实际运行 13 项回归通过。最终轮在本文定稿后进行，结果保存在任务外置审查记录；不预填未知结论。

推送后必须核对最终 test 和每个分组成功、原 169 次测试全部实际 Passed、lint exit 0。记录准备、分组、汇总与排队时间，并与成功基线 run 43583767208 的 42 分 55 秒比较。目标至少减少 40%；预估 12–18 分钟仅为估算，不能替代实测。

## 限制

并行额度和 runner 负载可能降低收益，总 runner 分钟可能增加。未使用跨提交 DerivedData 缓存、修改系统服务、删除测试或改变运行时/库行为。未提供长期性能 SLA。该文档生成时本轮远程执行尚未开始，整体性能验收未宣称完成。
