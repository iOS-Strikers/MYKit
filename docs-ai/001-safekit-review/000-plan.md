# MYKit 防护优化方案 v2

基线：master@7187e6af3002ef2c536cef839435c71d549de1ac。状态：v2 已通过独立 Spec review（clean），用户已于 2026-11-14 批准；本文件保留获批方案及其原始哈希，实际交付见 001-action.md。

## 目标与范围

逐项修复《MYKit防护审查.md》全部六类防护及公共底座。合法 Foundation 调用保留系统行为；非法调用的兜底必须有明确契约、可观测且不制造新的数据损坏。公共 MYSafeKit ability 位值及原注册入口保持；不进行无关 UIKit/Foundation 工具类重构，不自动发布、提交、推送或创建 PR。

仓库没有 AGENTS.md 或现有任务文档目录。批准后采用拟新增 `docs-ai/001-safekit-review/000-plan.md` 保存本方案及验收映射，实施记录用 `001-action.md`；当前审查交付保存在 outputs。

## 设计决定

### 1. 注册与 Hook

对实际类型及 Method 做探测、空值和类型签名校验。原方法和替代方法都先物化到目标类，避免修改继承 Method；维护注册去重，顶层 ability 重复/并发调用不会交换回原实现。公共 Swizzle 签名尽量保留，SafeKit 内部使用可返回成功状态的辅助实现。不同防护使用不同前缀 selector，避免 NSObject 与 NSNull 的替代 selector 重名。

类簇覆盖通过真实样本（空/单/多元素、可变、动态字符串、tagged、CF bridge）发现，并按有效类/selector 去重。不声称任意系统私有类已完整覆盖；无法 Hook 的路径应可诊断，不能注册虚假成功或把任意指针/C 内存错误当成可恢复异常。

### 2. Container 与 KVC

- 对合法输入直接走原方法；修复 nil 字典下标删除、KVC 对象属性清空、字符串 from/to==length、空字符串空范围、数组合法批量插入。
- 范围检查统一采用减法防溢出；批量插入按最终索引语义逐项检查，并核对数量；替换与删除验证边界。非法可变操作整体 no-op，不截断后部分写入。
- 非法对象读取返回 nil；非法 characterAtIndex 返回 0；非法查找返回 NSNotFound。记录错误原因，正常输入不上报。
- 构造中的 nil 元素/键值对保留原设计的过滤策略；只对真实有效指针提供的 count 元素做处理，不尝试保证任意无效 C 指针安全。移除随 count 增长的栈数组，分配失败不得调用不完整缓冲；有效输入避免重复拷贝。
- 移除直接覆盖 NSObject 原 KVC 方法的 Category 实现。只在 Container 注册时安装相应 Hook；自定义 override 优先，业务 getter/setter 抛出的任意异常不统一吞掉。undefined key 与 scalar nil 的库内默认兜底须可上报，关闭/未注册时保持系统行为。

### 3. KVO

保留观察代理方向，但改为每条登记拥有独立 identity/context/options 状态。不同观察者和不同 context 均可独立注册；同一 identity 的重复登记按 Foundation 可观察的注册/移除语义计数，不再凭 keyPath 判断重复。先用未启用防护的原生测试明确不带 context 移除的行为，再按结果匹配；带 context 仅影响匹配记录，移除不存在记录上报并 no-op。

事务登记须支持 Initial 同步回调及其中的自移除/重新添加；区分底层注册失败和 Initial 业务回调异常。前者需回滚，后者必须按原生对照确定注册是否已生效并同步账本，不能统一当注册失败回滚；统一保护登记状态，不能在非递归状态锁中回调业务、上报或执行可能重入的原 add。采用登记状态与回调快照，确保同 keyPath 并发增删不会让账本与底层注册脱节；不承诺业务对象自身可并发修改。

observer 使用弱引用，keyPath 使用 copy，context 保持指针身份。只转发给活着的真实观察者，正确透传 options/change/context；不吞观察者业务回调的任意异常。清理时不创建新代理、不在半析构对象上调用任意 reporter；原 dealloc 必须恰好调用一次。消除对 UIApplication delegate / dladdr 缺失值的未检查依赖；系统类、动态 framework、扩展宿主与用户自定义 KVO 的覆盖边界需明确并测试。若无法在某路径安全代理，应保留原行为并报告限制，不能静默使合法监听失效。

### 4. UnknownSelector 与 NSNull（行为收紧）

删除根据 selector 冒号数拼造 int ABI 的做法。建议新增可选 API：`+registerFallbackForClass:selector:typeEncoding:`，返回 BOOL；调用方提供真实 Class、SEL、完整 Objective-C method encoding，注册时校验 self/_cmd、参数数目、返回长度及允许类型，冲突签名拒绝并报告。Class 为实例方法所属类，类方法使用 metaclass；注册表按实际类+selector 匹配，不把同名不同类视为同一签名，库只校验编码结构及支持类型集合，不接受 union 等未支持类型；编码本身无法识别 variadic 或证明未知方法的调用 ABI。调用方必须保证编码与真实调用完全一致、方法非 variadic；传错签名不属于防护保证范围。返回值按登记且受支持的签名长度清零。

先尊重原有动态解析、快速转发、methodSignatureForSelector/forwardInvocation；已有自定义转发抛出的异常原样传播，不可 catch 任意转发异常后清零。兜底仅处理抵达默认未处理路径且显式登记的调用；自定义转发路径无法可靠证明进入默认未处理时保留其原行为。未登记的未知调用保持原系统异常；已有 ability All 保留，但不再承诺可以自动吞任意未知调用。此处是明确的兼容性变化，需在 README/迁移说明中突出说明，并在未来发布时决定版本号（本次不发布）。

NSNull 使用有限安全 selector 白名单及真实签名，逐项定义返回值/参数验证，不再“哪个空对象响应就转发”。首版确切白名单：`length`、`count` 返回 NSUInteger 0；`intValue`、`integerValue`、`longLongValue`、`unsignedLongLongValue`、`doubleValue`、`floatValue`、`boolValue` 按各自真实类型返回 0/NO；`objectForKey:`、`objectForKeyedSubscript:`、`objectAtIndex:`、`objectAtIndexedSubscript:` 返回 nil；`characterAtIndex:` 返回 unichar 0；`substringFromIndex:`、`substringToIndex:`、`substringWithRange:` 返回 nil。白名单调用均按 Null 类型上报一次（Record 重入抑制除外）；由于接收者为 NSNull，不对任意参数解引用或按空容器重新执行，nil key、任何索引/范围均按上述固定结果兜底。分别测试真实对象/标量返回与所有边界；其他 selector 走既有转发链，不保证防护。单独开启和与 UnknownSelector/Container 同开都不能引入递归。

### 5. Notification、Timer、Record

Notification 对观察者关联的 center 使用弱引用、身份去重及同步快照；保留 selector 注册清理，明确 block token 不在当前保护范围，不扩大为自动修改 block 生命周期。

Timer 保留“两个 selector 工厂的重复 timer 使用 weak target”现有约定，移除无效关联，验证原 NSTimer 参数传递、单次 timer 不改变强持有语义、target 释放后下次触发 invalidate。合法动态转发 target 不应因仅检查 respondsToSelector 被误停止；调用前签名/转发行为应按原 NSTimer 契约测试。timer 本身持有代理，不新增全局强引用池。

Record 使用同步安全的 handler 快照，线程局部递归抑制，不持锁回调；回调抛异常隔离并有不递归的最低限度记录。保留调用线程交付契约，文档要求 reporter 可并发；收集有界堆栈，避免递归故障路径再次格式化不可信业务对象。旧 alert API 标记弃用并保证主线程调用，不把 UI 弹窗作为默认错误汇报。

### 6. 测试与构建

新增独立现代 iOS XCTest 宿主，直接编译 SafeKit/所需 Swizzle，避开旧示例第三方依赖。测试宿主可以设置工具链支持的 deployment target；不擅自提高 podspec 的 iOS 8 最低声明。先保留旧示例构建失败记录，再决定修复示例的最小配置/依赖变更；若必须升级依赖或移除旧系统支持，另行说明影响。

全局 Hook 不能可靠卸载，未启用、单能力、All 和不同注册顺序以独立进程/宿主运行，不能让测试顺序掩盖问题。缺少 iOS 8 等旧运行时仅能报告兼容性未验证；本机至少在 iOS 26.5 模拟器执行行为测试。不把 macOS 隔离执行、build 成功或空测试计为 iOS 行为通过。

## 验收标准（全部必需，旧系统真机另列限制）

| ID | 验收 |
|---|---|
| AC01 | 未注册不改变原 Foundation/KVC 行为；每个 ability 单开、All、重复/并发注册正常；Hook 缺类/方法、父子类继承与相反顺序不污染其他实现。 |
| AC02 | F06–F11 所有复现转绿；合法空/末尾/nil/批量行为与原生对照一致；非法输入无部分写入且产生预期上报。 |
| AC03 | NSArray/NSDictionary 两类构造与所有现有 Hook 对应 selector 的合法/非法用例；大输入无 VLA 栈增长、正常路径无不必要复制；真实类簇样本覆盖明确。 |
| AC04 | KVO 单/多 observer、重复注册、不同 context、带/不带 context remove、陌生 observer、Initial/Old/New/Prior、Initial 回调内移除自身及移除后再添加、Initial 业务回调抛异常后的原生对照、业务重入、注册异常回滚、并发增删和 framework 模型测试；回调身份和值正确、无死锁。 |
| AC05 | KVO observed/observer 两种销毁顺序、未观察对象析构、weak 清零与关联对象析构；原析构恰好一次，无泄漏/残留通知。 |
| AC06 | UnknownSelector 已登记对象/整数/浮点/结构体真实签名按定义清零；未登记保留原异常；动态解析及两级转发正常、自定义转发抛异常原样传播；不支持/冲突签名拒绝；类方法与实例方法隔离。 |
| AC07 | NSNull 白名单每 selector 的合法/非法参数和返回类型；单独、All、相反注册顺序一致，非白名单按文档保留原行为。 |
| AC08 | Notification selector 注册/移除/释放、自建 center 释放、重复注册及并发压力；block token 原生语义不变。 |
| AC09 | Timer scheduled/unscheduled、重复/单次、目标释放、动态转发、timer 参数身份与 userInfo；无意外 retain cycle。 |
| AC10 | Record reporter 重入、抛异常、并发注册/上报、空 handler 和正确错误类型；无递归崩溃/死锁；正常调用不误报。 |
| AC11 | 模拟器测试非零且逐项映射以上 AC；记录真实命令/退出码/xcresult/源码快照；至少两轮独立 Code Review，最新交付 clean 后无额外未审变更。 |

## 交付与限制

代码、有效 XCTest、README 防护矩阵/不支持场景/迁移说明、逐项验证证据与最终独立审查结论。旧 iOS 支持、真机与其他 Hook 库组合未实际运行时明确列为未验证，不以当前模拟器代替。用户批准本方案后实施；不自动 merge、deploy 或发布 CocoaPods。

## 独立审查修订记录

v1 → v2：接受 reviewer 的四项意见，明确编码无法证明 ABI/识别 variadic、已有自定义转发异常不可吞、Initial 重入及业务异常与注册失败必须分别对照、首版 NSNull 白名单逐项固定返回及上报契约。原生 macOS KVO 重复登记对照作为设计参考，最终 iOS 行为仍以 iOS 对照测试确定。

## 批准

用户于 2026-11-14 明确批准：“按 v2 方案实施，把每项防护的问题修好，补齐测试，再逐项 review 一遍。”
批准方案 SHA-256：`624aca040f96d86ebfb275574107583e0da51ac95902fcc2099b0f14f0112c9a`。
