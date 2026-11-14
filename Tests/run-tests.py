#!/usr/bin/env python3
"""Run the process-isolated SafeKit matrix and reject skipped/missing test cases."""
import argparse
import json
from pathlib import Path
import subprocess
import sys


def cases(node):
    if isinstance(node, dict):
        if node.get("nodeType") == "Test Case":
            yield node
        for value in node.values():
            yield from cases(value)
    elif isinstance(node, list):
        for child in node:
            yield from cases(child)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--udid", required=True)
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--mode", action="append")
    parser.add_argument("--verifier", type=Path, help="Optional evidence verifier implementing the ios-e2e-verification CLI")
    args = parser.parse_args()
    root = Path(__file__).resolve().parent
    matrix = json.loads((root / "matrix.json").read_text())
    modes = args.mode or ["Native", "Container", "KVO", "Unknown", "Null", "Notification", "Timer", "Record", "All", "Reverse", "Concurrent"]
    if any(mode not in matrix for mode in modes):
        parser.error("Unknown matrix mode")
    args.output.mkdir(parents=True, exist_ok=False)
    results = []
    for mode in modes:
        selected = matrix[mode]
        out = args.output / mode
        if args.verifier:
            command = [sys.executable, str(args.verifier), "unit", "--project", str(root / "SafeKitTests.xcodeproj"), "--scheme", "SafeKit-" + mode, "--udid", args.udid, "--output", str(out), "--acceptance", str(root / "acceptance" / (mode + ".json")), "--timeout", "240"]
            for name in selected:
                command.extend(["--only-testing", "SafeKitTests/SafeKitTests/" + name])
            result = subprocess.run(command, check=False)
            passed = result.returncode == 0
        else:
            out.mkdir()
            command = ["xcrun", "xcodebuild", "test", "-project", str(root / "SafeKitTests.xcodeproj"), "-scheme", "SafeKit-" + mode, "-destination", "platform=iOS Simulator,id=" + args.udid, "-derivedDataPath", str(args.output / "DerivedData"), "-resultBundlePath", str(out / "result.xcresult")]
            command.extend("-only-testing:SafeKitTests/SafeKitTests/" + name for name in selected)
            (out / "command.json").write_text(json.dumps(command, indent=2))
            with (out / "command.log").open("w") as log:
                try:
                    result = subprocess.run(command, stdout=log, stderr=subprocess.STDOUT, timeout=240, check=False)
                    passed = result.returncode == 0
                except subprocess.TimeoutExpired:
                    passed = False
            parsed = subprocess.run(["xcrun", "xcresulttool", "get", "test-results", "tests", "--path", str(out / "result.xcresult")], capture_output=True, text=True, check=False)
            (out / "tests.json").write_text(parsed.stdout)
            try:
                observed = list(cases(json.loads(parsed.stdout)))
                identifiers = {test["nodeIdentifier"] for test in observed}
                passed = passed and bool(observed) and all(test.get("result") == "Passed" for test in observed) and all("SafeKitTests/" + name in identifiers for name in selected)
            except (ValueError, KeyError):
                passed = False
        results.append({"mode": mode, "passed": passed, "selected_tests": len(selected)})
        (args.output / "summary.json").write_text(json.dumps(results, indent=2))
        print(mode + ": " + ("PASS" if passed else "FAIL"), flush=True)
        if not passed:
            return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
