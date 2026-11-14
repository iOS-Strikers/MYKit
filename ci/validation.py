#!/usr/bin/env python3
"""Single partition definition and exact coverage gate for parallel CI."""
import argparse
from collections import Counter
import json
import os
from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[1]


def read_json(path):
    return json.loads(path.read_text())


def validate_lanes(lanes, matrix):
    names = [lane['name'] for lane in lanes]
    if len(set(names)) != len(names) or not all(re.fullmatch(r'[a-z][a-z0-9-]*', n) for n in names):
        raise ValueError('Lane names must be unique and safe directory names')
    kinds = Counter(lane['kind'] for lane in lanes)
    if kinds['apps'] != 1 or kinds['lint'] != 1 or kinds['safekit'] < 1 or set(kinds) != {'apps', 'lint', 'safekit'}:
        raise ValueError('Exactly one apps/lint lane and at least one SafeKit lane are required')
    modes = []
    for lane in lanes:
        if lane['kind'] == 'safekit':
            if not lane['modes']: raise ValueError('Empty SafeKit lane')
            modes.extend(lane['modes'])
        elif lane['modes']:
            raise ValueError('Only SafeKit lanes can select modes')
    if Counter(modes) != Counter(matrix.keys()):
        raise ValueError('SafeKit partition has missing, duplicate or unknown modes')


def load_lanes(root=ROOT):
    lanes = read_json(root / 'ci/lanes.json')
    validate_lanes(lanes, read_json(root / 'Tests/matrix.json'))
    return lanes


def required_tests(path):
    criteria = read_json(path)['criteria']
    names = [name for item in criteria if item['required'] for name in item['tests']]
    if not names: raise ValueError('Empty acceptance list: ' + str(path))
    return sorted(set(names))


def cases(node):
    if isinstance(node, dict):
        if node.get('nodeType') == 'Test Case':
            yield node
        for value in node.values(): yield from cases(value)
    elif isinstance(node, list):
        for value in node: yield from cases(value)


def check_tree(path, expected):
    observed = list(cases(read_json(path)))
    identifiers = [node['nodeIdentifier'] for node in observed]
    if not expected or Counter(identifiers) != Counter(expected):
        raise ValueError('Missing, extra or duplicate test identifiers: ' + str(path))
    if any(node.get('result') != 'Passed' for node in observed):
        raise ValueError('Non-passing test result: ' + str(path))
    return len(observed)


def validate_job_results(needs):
    if set(needs) != {'prepare', 'validate'} or any(job.get('result') != 'success' for job in needs.values()):
        raise ValueError('Preparation and every matrix job must succeed; failed, cancelled or skipped jobs cannot pass')


def aggregate(artifacts, root=ROOT, sha=None):
    if not sha: raise ValueError('Expected commit SHA is required')
    lanes = load_lanes(root)
    matrix = read_json(root / 'Tests/matrix.json')
    counts = {}
    mode_count = 0
    for lane in lanes:
        directory = artifacts / ('ios-validation-' + lane['name'])
        status = read_json(directory / 'lane.json')
        if any(status.get(key) != lane[key] for key in ('name', 'kind', 'modes')):
            raise ValueError('Lane metadata does not match the partition: ' + lane['name'])
        if status.get('exit_code') != 0 or status.get('head_sha') != sha:
            raise ValueError('Lane failed or belongs to another commit: ' + lane['name'])
        if lane['kind'] == 'safekit':
            for mode in lane['modes']:
                counts['safekit/' + mode] = check_tree(directory / 'safekit' / mode / 'tests.json', ['SafeKitTests/' + name for name in matrix[mode]])
                mode_count += 1
        elif lane['kind'] == 'apps':
            for suite, acceptance in [('example', 'Example/Tests/acceptance.json'), ('utilities', 'Tests/acceptance/Utilities.json')]:
                counts[suite] = check_tree(directory / suite / 'tests.json', required_tests(root / acceptance))
        else:
            if read_json(directory / 'lint-result.json').get('exit_code') != 0:
                raise ValueError('CocoaPods lint failed')
    return {'passed': True, 'head_sha': sha, 'counts': counts, 'total_tests': sum(counts.values()), 'safekit_modes': mode_count, 'lint_passed': True}


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('command', choices=['matrix', 'aggregate'])
    parser.add_argument('--artifacts', type=Path)
    parser.add_argument('--sha')
    parser.add_argument('--output', type=Path)
    args = parser.parse_args()
    if args.command == 'matrix':
        print(json.dumps({'include': [{'name': x['name'], 'ruby': x['kind'] != 'safekit'} for x in load_lanes()]}))
        return 0
    if not args.artifacts or not args.output or not args.sha:
        parser.error('aggregate requires --artifacts, --sha and --output')
    try:
        if 'GITHUB_NEEDS' in os.environ:
            validate_job_results(json.loads(os.environ['GITHUB_NEEDS']))
        result = aggregate(args.artifacts, sha=args.sha)
    except (OSError, ValueError, KeyError, TypeError) as error:
        result = {'passed': False, 'error': str(error)}
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(result, indent=2) + '\n')
    print(json.dumps(result))
    return 0 if result['passed'] else 1


if __name__ == '__main__':
    raise SystemExit(main())
