# MYKit

Objective-C utilities for iOS, with Foundation extensions, UIKit helpers, and
opt-in protection for selected exception-prone operations.

## Modules

| CocoaPods subspec | Contents |
| --- | --- |
| `Core` (default) | Umbrella headers and the Foundation, UIKit, and SafeKit modules |
| `Foundation` | Foundation extensions for collections, strings, dates, data, and runtime helpers |
| `UIKit` | UIKit extensions; depends on Foundation |
| `SafeKit` | Container/KVC, KVO, notification, timer, unknown-selector, and NSNull protection; depends on Foundation |

Source: [`MYKit/Classes`](MYKit/Classes). Specification: [`MYKit.podspec`](MYKit.podspec).
SafeKit is opt-in: linking the library does not enable its protection hooks.

## Version and platform status

The SafeKit review and fixes are merged into `master` in
[`8d2aa2a`](https://github.com/iOS-Strikers/MYKit/commit/8d2aa2ab40261a15e12498eaa60fd34263ded01d).
The podspec still declares **1.1.3**, and the existing `1.1.3` Git tag points to
code **before** these fixes. No new CocoaPods release was made as part of this work.
Use the pinned source revision below to obtain the reviewed implementation.

| Item | Status |
| --- | --- |
| Library deployment declaration | iOS 8.0 in the podspec; retained, not newly validated |
| Independent XCTest host | iOS 15.0 deployment target; no CocoaPods dependencies |
| Verified environment | Xcode 27.2 (27B52), iPhone 17 Pro simulator, iOS 26.5 (23F77), arm64 |
| Test tooling | Full Xcode, an available iOS simulator, and Python 3 |
| Not verified in this revision | Physical devices, older iOS versions, and combinations with other swizzling libraries |

## Installation

To use only SafeKit from the reviewed source revision:

```ruby
pod 'MYKit/SafeKit',
    :git => 'https://github.com/iOS-Strikers/MYKit.git',
    :commit => '8d2aa2ab40261a15e12498eaa60fd34263ded01d'
```

For all modules, use `MYKit` instead of `MYKit/SafeKit`. For a local checkout:

```ruby
pod 'MYKit/SafeKit', :path => '../MYKit'
```

Choose one source configuration, then run `pod install` in your application project.
The historical version-based installation (`pod 'MYKit', '1.1.3'`) does not select
the new source revision.

## Quick start

Register a reporter and enable the abilities needed by your application, ideally
before the operations you want protected:

```objc
#import <MYKit/MYSafeKit.h>

@interface AppSafeKitReporter : NSObject <MYSafeKitRecordProtocol>
@end

@implementation AppSafeKitReporter
- (void)recordWithReason:(NSError *)reason {
    NSLog(@"SafeKit: %@", reason);
}
@end

// In application startup code:
[MYSafeKit registerRecordHandler:[AppSafeKitReporter new]];
[MYSafeKit registerSafeKitShieldWithAbility:
    MYSafeKitShieldTypeContainer | MYSafeKitShieldTypeKVO];
```

`registerSafeKitShield` enables `MYSafeKitShieldTypeAll`. It does not promise recovery
from every crash. The reporter is retained; passing nil to `registerRecordHandler:`
clears the reporter, not the installed protection hooks.

## SafeKit protection contract

Enable only the abilities needed by the application. Registration is process-wide,
additive and irreversible; repeated registration is idempotent. `All` includes all
six abilities, but does not mean that arbitrary crashes can be recovered.

| Ability | Supported behavior | Boundaries |
| --- | --- | --- |
| Container | Array/dictionary construction, sampled Foundation class-cluster reads and mutations, strings, default NSObject KVC handling | Invalid object reads return nil, invalid character reads return 0, failed searches return NSNotFound. Invalid writes are rejected as a whole. Nil construction elements/pairs are filtered. Invalid C pointers, concurrent collection mutation, arbitrary custom subclasses and every future private Foundation class are not covered. |
| KVO | Separate registrations per observer/keyPath/context, duplicate observations, native options, matching removal, observer/observed cleanup | Client callback exceptions propagate. Initial callbacks precede installation, as verified on iOS 26.5; an exception leaves no new registration. Removal before that installation is an unmatched removal: reported/no-op. Existing observations created before activation can still be removed. Custom implementations that never call NSObject's KVO methods are outside the hook. |
| Notification | Selector observation cleanup, weak deduplicated notification-center tracking | Block observer tokens keep their native lifecycle and must be removed by the caller. |
| Timer | Repeating timers created by the two target/selector factory APIs use weak targets; the next fire after target destruction invalidates the timer | Single-shot timers retain native semantics. Block timers and direct initializers are not wrapped. Weak targets are an intentional ownership change: retain a target elsewhere if it must stay alive. |
| UnrecognizedSelector | Explicitly registered, exact-class, typed fallback only | Unregistered selectors keep native failure behavior. Existing resolution/forwarding and custom forwarding exceptions take precedence. This cannot infer a method signature from its name. |
| Null | Fixed, typed selector allowlist | Not equivalent to sending any message to nil. Nonallowlisted messages retain the original forwarding behavior. |

### Compatibility changes

The old generic unknown-selector `int` stub was ABI-unsafe. Applications that
previously relied on swallowing arbitrary unknown methods must migrate to explicit
registration. This is a behavior change in `master`; the podspec version has not been
bumped and no new release tag was created for these changes.

```objc
// The caller MUST guarantee this is the actual encoding of a non-variadic call.
// Registration does not independently prove the ABI. Pass a metaclass for class methods.
BOOL accepted = [MYSafeKit registerFallbackForClass:[MyModel class]
                                         selector:NSSelectorFromString(@"optionalDouble")
                                     typeEncoding:"d@:"];
[MYSafeKit registerSafeKitShieldWithAbility:MYSafeKitShieldTypeUnrecognizedSelector];
```

The registry validates encoding syntax, supported types and argument count. It
rejects conflicting signatures, existing selectors, unions, arrays, bitfields,
opaque structures and unsupported encodings. It cannot detect variadic calls from
an encoding or validate a dishonest encoding. Supported return values are cleared
using the registered return size; no implementation is permanently added for the
missing selector. Registration matches the actual runtime class, not all subclasses.

Legal dictionary subscript assignment to nil now deletes the key; KVC can clear
object properties; substring endpoints equal to length and empty strings retain
Foundation behavior. Invalid string writes no longer truncate and partially modify
data. KVC behavior is no longer changed merely by linking MYKit.

### NSNull allowlist

Every fallback below reports one Null event (except events suppressed by record
reentry protection). Parameters are not dereferenced or forwarded into an empty
collection. The same defined fallback applies to nil keys and out-of-range indices.

| Selectors | Result |
| --- | --- |
| `length`, `count` | NSUInteger 0 |
| `intValue`, `integerValue`, `longLongValue`, `unsignedLongLongValue`, `doubleValue`, `floatValue`, `boolValue` | Zero/NO of the actual return type |
| `objectForKey:`, `objectForKeyedSubscript:`, `objectAtIndex:`, `objectAtIndexedSubscript:` | nil |
| `characterAtIndex:` | unichar 0 |
| `substringFromIndex:`, `substringToIndex:`, `substringWithRange:` | nil |

### Reporting

Handlers are retained and receive errors synchronously on the triggering thread;
implementations must support concurrent calls. Handler replacement is synchronized,
callbacks run without the handler lock, same-thread recursive events are suppressed,
and handler exceptions are isolated. Errors retain the original `com.xxshield.<bundle identifier>` domain, a negative
ability code, a description, and at most 32 stack frames under `callStack`.
The deprecated alert helper dispatches to the main queue and is not a
default reporting mechanism. Do not perform recovery requiring a live UI from a
report callback.

## Tests and verification

The latest recorded review run used **29 test methods across 11 process-isolated
configurations: 149 executions, all passed, with no skipped or missing cases**.
Two independent code-review rounds completed, with the final review clean. These
are recorded results for the reviewed source revision, not a live CI badge.
Implementation and acceptance details: [delivery record](docs-ai/001-safekit-review/001-action.md).
That record captures the validation-time state; current merge and version status
are described above.

The independent [`Tests/SafeKitTests.xcodeproj`](Tests/SafeKitTests.xcodeproj) builds
a minimal app host, XCTest bundle, and a separate framework fixture. It does not
require the legacy Example project or `pod install`.

From the repository root, select an available simulator:

```sh
export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
xcrun simctl list devices available
```

Then replace `YOUR_SIMULATOR_UDID` and run the full matrix:

```sh
python3 Tests/run-tests.py \
  --udid YOUR_SIMULATOR_UDID \
  --output /tmp/mykit-results
```

**The output directory must not already exist.** Choose a fresh path for every run;
previous evidence is not overwritten. To select individual modes:

```sh
python3 Tests/run-tests.py \
  --udid YOUR_SIMULATOR_UDID \
  --mode Container --mode KVO \
  --output /tmp/mykit-container-kvo-results
```

| Configuration | Purpose |
| --- | --- |
| `Native` | Unprotected Foundation behavior, including KVO reference semantics |
| `Container`, `KVO`, `Unknown`, `Null`, `Notification`, `Timer`, `Record` | Individual capability and reporting verification |
| `All` | Combined protections |
| `Reverse` | Reverse capability registration order |
| `Concurrent` | Concurrent first-time installation of all protections |

The runner uses [`Tests/matrix.json`](Tests/matrix.json) to select exact cases and
requires every selected case to pass. Missing/skipped cases fail the run. Standard
runs write `summary.json`, per-mode commands/logs/test trees and `.xcresult` bundles,
plus shared DerivedData under the chosen output directory. The
[`acceptance`](Tests/acceptance) directory provides explicit contracts for the
optional evidence-verifier integration.

The checked-in Xcode project can be used directly. Only when changing its source
membership, regenerate it with `ruby Tests/generate-project.rb`; that maintenance
step requires the `xcodeproj` Ruby gem.

## Legacy example

[`Example`](Example) contains the original demonstration application and CocoaPods
configuration. Its iOS 8 deployment settings are incompatible with the verified
Xcode 27.2 toolchain, so it is not the current validation entry point. Use the
independent test project above to reproduce the current SafeKit verification.

## Author and license

Created by sunjinshuai — sunjinshuai@aikucun.com.

Distributed under the [MIT license](LICENSE).
