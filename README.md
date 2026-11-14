# MYKit

[![CI Status](https://img.shields.io/travis/sunjinshuai/MYKit.svg?style=flat)](https://travis-ci.org/sunjinshuai/MYKit)
[![Version](https://img.shields.io/cocoapods/v/MYKit.svg?style=flat)](https://cocoapods.org/pods/MYKit)
[![License](https://img.shields.io/cocoapods/l/MYKit.svg?style=flat)](https://cocoapods.org/pods/MYKit)
[![Platform](https://img.shields.io/cocoapods/p/MYKit.svg?style=flat)](https://cocoapods.org/pods/MYKit)

## Example

To run the example project, clone the repo, and run `pod install` from the Example directory first.

## Requirements

## Installation

MYKit is available through [CocoaPods](https://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod 'MYKit'
```

## Author

sunjinshuai, sunjinshuai@aikucun.com

## License

MYKit is available under the MIT license. See the LICENSE file for more info.

## SafeKit protection contract (unreleased changes)

Enable only the abilities needed by the application. Registration is process-wide,
additive and irreversible; repeated registration is idempotent. `All` includes all
six abilities, but does not mean that arbitrary crashes can be recovered.

```objc
[MYSafeKit registerRecordHandler:reporter];
[MYSafeKit registerSafeKitShieldWithAbility:
    MYSafeKitShieldTypeContainer | MYSafeKitShieldTypeKVO];
```

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
registration. This is a behavior change; the repository version has not been
released or bumped as part of this work.

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

### Tests

`Tests/SafeKitTests.xcodeproj` is an independent iOS XCTest host with no CocoaPods
dependencies. Its deployment target is iOS 15; this does **not** raise the podspec's
iOS 8 declaration. The legacy Example's iOS 8 build configuration is incompatible
with Xcode 27.2. Old OS compatibility, device execution, and interactions with
unrelated swizzling libraries require separate verification and are not claimed by
the current simulator run.

```sh
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
python3 Tests/run-tests.py --udid YOUR_SIMULATOR_UDID --output /tmp/mykit-results
```

The runner selects the exact cases in `Tests/matrix.json` and launches a new test
process for Native, each individual ability, All, Reverse, and Concurrent. It
requires every selected test to pass; missing/skipped tests are failures. Concurrent
starts with simultaneous first-time installation, not just repeated calls after
activation. Native provides the reference semantics for KVO Initial delivery and
registration counts. The fixture framework validates observations outside the app
executable. Regenerate the checked-in project only when source files change, using
`ruby Tests/generate-project.rb` with the `xcodeproj` gem installed.
