# MYKit 防护优化实际交付

## 范围与快照

用户于 2026-11-14 批准 v2；批准原文及方案哈希见 `000-plan.md`。基线/当前 HEAD：`7187e6af3002ef2c536cef839435c71d549de1ac`，本地分支 `codex/safekit-review`。交付为未提交工作区改动，无用户原有修改被覆盖；未推送、未建 PR、未发布。

实际改动包括 SafeKit 六项防护、`Foundation/NSObject/NSObject+Swizzle.{h,m}`、README，以及新增独立 `Tests/` 工程、动态 framework fixture、测试矩阵/验收清单/运行脚本。`MYSafeContainerInternal.h` 为内部范围与安装辅助。其余 UIKit/Foundation 工具类、旧示例及第三方 Pods 未修改。

## 实际变更

- Hook：验证类/方法/签名，安装幂等；常规交换将实现本地化，防护 block 保存原 IMP，避免父类替代 selector 污染。容器采样空/单/多/可变、动态字符串和 CF 桥接类。
- Container/KVC：保留合法 nil、空范围、末尾边界；减法检查溢出；批量数量及索引完整预检；非法写入整体拒绝；构造只在过滤 nil 时分配堆缓冲，无 VLA；未注册时不覆盖 NSObject 默认 KVC，用户 override/业务异常保持。
- KVO：每次注册独立代理，弱 observer、copy keyPath、独立 context；支持多个/重复观察者及对应移除。原生 Initial 对照确认回调发生在安装前，异常不会残留新注册；按此实现。登记异常回滚、析构链恰好继续、观察两端释放清理。内部旁路限制到具体代理或原生移除调用链，保留启用前原生观察的移除。
- UnknownSelector：移除伪造 int stub，新增显式真实编码注册 API；仅支持的真实编码返回清零；保留动态解析、转发、未登记错误和自定义转发异常。编码可信性由调用方保证。
- NSNull：17 个明确 selector 的真实签名白名单，按约定返回 0/nil、报告一次；不再转发到空集合执行危险参数。
- Notification：关联中心改为弱引用、去重、同步；不改变 block token 生命周期。
- Timer：去掉无效关联，保留重复 selector 工厂的 weak target；避免两工厂内部调用造成重复代理；动态转发和单次 timer 保持原语义。
- Record：handler 快照同步，线程局部重入抑制，回调异常隔离，32 帧有界堆栈；保留原错误域/负 ability code；弃用 alert API 并在主线程执行。

## 已执行验证

环境：Xcode 27.2 (27B52)，iPhone 17 Pro 模拟器，iOS 26.5 (23F77)，arm64；UDID `50C308FC-04F8-4B6C-9F3B-5028FC63FF1B`。使用进程级 DEVELOPER_DIR，未切换全局工具链、未擦除模拟器。

已执行命令（从仓库根目录）：

```sh
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
python3 Tests/run-tests.py \
  --udid 50C308FC-04F8-4B6C-9F3B-5028FC63FF1B \
  --output ../verification/matrix-v2 \
  --verifier /Users/mengxiang/.codex/skills/ios-e2e-verification/scripts/verify.py
```

结果：**PASS，29 个独立测试方法、11 种独立进程配置、149 次选定测试执行，零失败、零跳过。** 每种配置均有实际 xcodebuild exit 0、非零 XCTest 结果与 required 验收映射 PASS。每次使用唯一 DerivedData/xcresult 目录；日志、命令、快照、test tree 和逐项 AC 结果保留在线程 `work/verification/matrix-v2/`，用户可见副本位于线程 `outputs/修复验收证据/matrix/`。测试模式必须显式提供，缺失不能静默退回 Native。

| 模式 | 测试执行数 | 结果 |
|---|---:|---|
| Native | 9 | PASS |
| Container | 11 | PASS |
| KVO | 15 | PASS |
| Unknown | 6 | PASS |
| Null | 5 | PASS |
| Notification | 5 | PASS |
| Timer | 6 | PASS |
| Record | 5 | PASS |
| All | 29 | PASS |
| Reverse | 29 | PASS |
| Concurrent | 29 | PASS |

具体计数以 `Tests/matrix.json` 及验收 manifest 为准。

## 验收映射

| AC | 测试/证据 |
|---|---|
| AC01 | Native 与全部单项模式；`testNativeSemanticsAndIsolation`、`testSwizzleInheritanceMissingMethodsAndIdempotence`、`testStartupHasNoUnavailableGuards`；Concurrent 模式首次并发 All 安装；Reverse 反向顺序。 |
| AC02/03 | `testArrayReadsAndRangeOverflow`、`testArrayMutationsAtomicAndValid`、`testConstructorsAndLargeInput`（20 万元素）、`testDictionaryMutationAndBridging`、`testStringsAllBoundariesAndBridging`、`testKVCDefaultsAndOverrides`，Native 合法 nil 对照。 |
| AC04 | KVO 身份/options/两种 remove、重复登记、Initial 重入和异常、并发、动态 framework、注册异常回滚、业务原生注册重入、启用前登记移除及非法参数各用例。 |
| AC05 | `testKVOLifetimesAndUnobservedDestruction`、`testKVOObservedDiesBeforeLivingObserver`：明确区分双方销毁顺序，weak 清零与关联对象析构计数。 |
| AC06 | `testUnknownTypedFallbackAndRejection`、`testUnknownPreservesResolutionAndForwardingExceptions`：对象/整数/浮点/结构体、类与实例方法、编码冲突/不支持、原始解析和两级转发。 |
| AC07 | `testNullEveryAllowedSelector`：17 个 selector，各自零/正常和 nil/越界参数、真实返回类型、一次上报；Null/All/Reverse/Concurrent 组合。 |
| AC08 | `testNotificationLifetimeAndConcurrentRegistration`：通知、移除、自建 center/observer 释放、重复并发登记、block token。 |
| AC09 | `testTimerFactoriesAndTargetRelease`、`testTimerDynamicForwarding`：两工厂、重复/单次、释放、参数/userInfo 身份、两级转发。 |
| AC10 | `testRecordReentryExceptionsAndConcurrency`：递归、异常、并发替换/上报、空 handler、代码/堆栈限制。 |
| AC11 | 非零测试/全矩阵 required PASS 已完成；独立代码审查轮次与最终结论见外置审查记录，本文不预填尚未发生的 clean。 |

## 回归与原生对照证据

1. 初次审查的旧源码 macOS 隔离复现：数组/字符串越界、合法操作被改坏、KVO 回调丢失、未知方法 ABI 错误等；保留于线程 `outputs/审查证据/`。不将其当作 iOS 验收。
2. 初始 iOS Native 测试纠正了“Initial 后已安装”的错误假设：回调内首次移除会抛异常，Initial 回调抛异常后没有新观察。此失败不是产品回归 red，而是对测试预期的原生校正；保留 `work/verification/native/`。
3. 独立 round 1 在新源码复现两项 KVO 错误：线程级旁路漏记业务注册、启用前观察无法移除。均接受并修复，已加入 iOS 回归；见 `testKVONativeRegistrationReentryIsTracked`、`testKVORegistrationBeforeActivationCanBeRemoved`。
4. 修复启用前兼容路径时，`all-extended` 暴露错误 context 的原生内部转调又误删另一条代理记录；收窄到具体原生移除调用链后，`all-context` 及最终矩阵通过。
5. 字典 `dictionaryWithObjects:nil forKeys:nil` 与 `nil/空数组`：iOS Native 对照 PASS，新防护旧检查下 `nil-red` 真实失败；移除不必要的非 nil 限制后最终矩阵转绿，且无误报。对应日志已归档于 `outputs/修复验收证据/regressions/`。

## 偏差与边界

没有扩大生产最低系统版本，也未升级旧示例依赖；现代测试宿主独立于 CocoaPods。实际 Initial 顺序以 iOS 原生证据纠正，不是放宽断言迁就实现。错误域保持原值，避免无关公共行为变化。测试使用支持的平台编码，结构体消息调用由编译器选择 ABI。

跨线程同步等待原生 KVO 的内部操作不是本库能保证无死锁的使用模式；独立有界 macOS 对照显示一类嵌套 Initial 等待在原生与防护下均阻塞直到外层返回，没有将其错误列为新增防护缺陷。此对照不替代 iOS 行为验收。

本次不涉及产品 UI 改动，无 UI 外观验收要求。真机、旧 iOS 8 运行时、其他模拟器版本、任意私有类/第三方 Hook 组合未执行，明确 NOT RUN。iOS 8 podspec 声明保留不等于已验证兼容。

## 独立 Review 与 Evidence Gate

round 1：review_runtime 独立会话全量审查，issues；两项 P1 和测试覆盖 P2 全部 ACCEPT，已补修复及对应回归。对照复核未确认的新死锁假设不作为 finding。

后续各轮复核旧问题并 fresh review 完整当前 diff。最终 clean 和 Gate 结果写在外置审查记录，以免最终审查后修改本交付文档。发布/PR 未授权，未执行。
