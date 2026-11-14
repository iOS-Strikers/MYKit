#!/usr/bin/env python3
"""Run the complete local pipeline or one isolated CI lane."""
import argparse
import json
import os
from pathlib import Path
import subprocess
import sys
import time

sys.dont_write_bytecode = True
from validation import ROOT, load_lanes


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('output', nargs='?', type=Path, default=ROOT / '.artifacts' / time.strftime('ci-%Y%m%d-%H%M%S'))
    parser.add_argument('--lane', default='all')
    args = parser.parse_args()
    lanes = load_lanes()
    if args.lane == 'all':
        lane = {'name': 'all', 'kind': 'all', 'modes': []}
    else:
        lane = next((x for x in lanes if x['name'] == args.lane), None)
        if lane is None: parser.error('Unknown lane: ' + args.lane)
    output = args.output.resolve()
    output.mkdir(parents=True, exist_ok=False)
    os.chdir(ROOT)
    steps = []
    start = time.monotonic()
    exit_code = 1
    sha = os.environ.get('GITHUB_SHA') or subprocess.check_output(['git', 'rev-parse', 'HEAD'], text=True).strip()

    def run_step(name, command, log_name=None):
        print('Starting ' + name, flush=True)
        began = time.monotonic()
        log_path = output / (log_name or name + '.log')
        with log_path.open('w') as log:
            result = subprocess.run(command, stdout=log, stderr=subprocess.STDOUT, check=False)
        step = {'name': name, 'command': command, 'exit_code': result.returncode, 'seconds': round(time.monotonic() - began, 3)}
        steps.append(step)
        (output / 'timings.json').write_text(json.dumps(steps, indent=2) + '\n')
        print(f"{name}: exit {result.returncode}, {step['seconds']}s", flush=True)
        if result.returncode:
            print('\n'.join(log_path.read_text(errors='replace').splitlines()[-40:]), flush=True)
            raise subprocess.CalledProcessError(result.returncode, command)

    kind = lane['kind']
    try:
        run_step('xcode', ['xcodebuild', '-version'], 'xcode.txt')
        run_step('xcresulttool', ['xcrun', 'xcresulttool', 'get', 'test-results', 'tests', '--help'])
        if kind != 'lint':
            udid = os.environ.get('SIMULATOR_UDID')
            if not udid:
                run_step('simulator-list', ['xcrun', 'simctl', 'list', 'devices', 'available', '-j'])
                devices = json.loads((output / 'simulator-list.log').read_text())['devices']
                runtimes = sorted((k for k in devices if 'iOS-' in k), key=lambda k: tuple(int(n) for n in k.split('iOS-')[-1].split('-')), reverse=True)
                candidates = [device for runtime in runtimes for device in devices[runtime] if device.get('isAvailable') and device['name'].startswith('iPhone')]
                if not candidates: raise ValueError('No available iPhone simulator')
                udid = candidates[0]['udid']
            (output / 'simulator.txt').write_text(udid + '\n')
        if kind in ('apps', 'lint', 'all'):
            run_step('bundle-check', ['bundle', 'check'])
        if kind in ('apps', 'all'):
            run_step('pod-install', ['bundle', 'exec', 'pod', 'install', '--deployment', '--project-directory=Example'])
            for suite, project_arg, project, scheme, target, acceptance, derived in [
                ('example', '-workspace', 'Example/MYKit.xcworkspace', 'MYKit-Example', 'MYKit_Tests', 'Example/Tests/acceptance.json', 'DerivedData'),
                ('utilities', '-project', 'Tests/UtilitiesTests.xcodeproj', 'Utilities', 'UtilitiesTests', 'Tests/acceptance/Utilities.json', 'DerivedData-Utilities'),
            ]:
                directory = output / suite
                directory.mkdir()
                run_step(suite, ['xcodebuild', 'test', project_arg, project, '-scheme', scheme, '-destination', 'platform=iOS Simulator,id=' + udid, '-derivedDataPath', str(output / derived), '-resultBundlePath', str(directory / 'result.xcresult'), '-only-testing:' + target], suite + '/command.log')
                run_step(suite + '-coverage', [sys.executable, 'ci/check-tests.py', str(directory / 'result.xcresult'), acceptance])
        if kind in ('safekit', 'all'):
            command = [sys.executable, 'Tests/run-tests.py', '--udid', udid, '--output', str(output / 'safekit'), '--timeout', '900']
            for mode in lane['modes']: command.extend(['--mode', mode])
            run_step('safekit', command)
        if kind in ('lint', 'all'):
            try:
                run_step('lint', ['bundle', 'exec', 'pod', 'lib', 'lint', '--allow-warnings'])
            finally:
                lint_step = next((step for step in reversed(steps) if step['name'] == 'lint'), {})
                (output / 'lint-result.json').write_text(json.dumps({'exit_code': lint_step.get('exit_code', 1)}) + '\n')
        exit_code = 0
    except (OSError, ValueError, subprocess.CalledProcessError) as error:
        print(str(error), file=sys.stderr)
    finally:
        status = {**lane, 'head_sha': sha, 'exit_code': exit_code, 'seconds': round(time.monotonic() - start, 3), 'steps': steps}
        (output / 'lane.json').write_text(json.dumps(status, indent=2) + '\n')
    return exit_code


if __name__ == '__main__':
    raise SystemExit(main())
