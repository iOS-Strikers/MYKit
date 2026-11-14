#!/usr/bin/env python3
"""Reject empty, failed, skipped, or incomplete xcresult test runs."""
import argparse
import json
from pathlib import Path
import subprocess
import sys

sys.dont_write_bytecode = True
from importlib.util import spec_from_file_location, module_from_spec
spec = spec_from_file_location('matrix_runner', Path(__file__).resolve().parents[1] / 'Tests/run-tests.py')
runner = module_from_spec(spec)
spec.loader.exec_module(runner)
parser = argparse.ArgumentParser()
parser.add_argument('result', type=Path)
parser.add_argument('acceptance', type=Path)
args = parser.parse_args()
result = subprocess.run(['xcrun', 'xcresulttool', 'get', 'test-results', 'tests', '--path', str(args.result)], capture_output=True, text=True, check=True)
(args.result.parent / 'tests.json').write_text(result.stdout)
observed = list(runner.cases(json.loads(result.stdout)))
criteria = json.loads(args.acceptance.read_text())['criteria']
required = {name for item in criteria if item['required'] for name in item['tests']}
actual = {test['nodeIdentifier'] for test in observed}
passed = bool(required) and bool(observed) and required <= actual and all(test.get('result') == 'Passed' for test in observed)
summary = {'passed': passed, 'observed': len(observed), 'missing': sorted(required - actual)}
(args.result.parent / 'summary.json').write_text(json.dumps(summary, indent=2))
print(json.dumps(summary))
sys.exit(0 if passed else 1)
