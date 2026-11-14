"""Keep lane orchestration equivalent to the existing full validation commands."""
import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest
from unittest.mock import patch

import run


class RunnerTests(unittest.TestCase):
    def invoke(self, lane='all', fail=None):
        with tempfile.TemporaryDirectory() as tmp:
            output = Path(tmp) / 'result'
            calls = []
            def execute(command, **kwargs):
                calls.append(command)
                code = 1 if fail and fail in command else 0
                return subprocess.CompletedProcess(command, code)
            old_cwd = Path.cwd()
            try:
                with patch.object(sys, 'argv', ['run', str(output), '--lane', lane]), patch.dict(os.environ, {'GITHUB_SHA': 'test-sha', 'SIMULATOR_UDID': 'test-device'}), patch.object(run.subprocess, 'run', side_effect=execute):
                    code = run.main()
            finally:
                os.chdir(old_cwd)
            return code, calls, json.loads((output / 'lane.json').read_text())

    def test_all_keeps_both_apps_full_matrix_and_lint(self):
        code, commands, status = self.invoke()
        self.assertEqual(code, 0)
        xcode = [c for c in commands if c[:2] == ['xcodebuild', 'test']]
        self.assertEqual([c[c.index('-scheme') + 1] for c in xcode], ['MYKit-Example', 'Utilities'])
        matrix = next(c for c in commands if 'Tests/run-tests.py' in c)
        self.assertNotIn('--mode', matrix)
        self.assertIn(['bundle', 'exec', 'pod', 'lib', 'lint', '--allow-warnings'], commands)
        self.assertEqual(status['exit_code'], 0)

    def test_safe_lane_matches_manifest_and_avoids_pods(self):
        code, commands, status = self.invoke('safekit-b')
        self.assertEqual(code, 0)
        command = next(c for c in commands if 'Tests/run-tests.py' in c)
        modes = [command[i + 1] for i, value in enumerate(command) if value == '--mode']
        self.assertEqual(modes, ['KVO', 'Container', 'Timer'])
        self.assertFalse(any('bundle' in c for c in commands))
        self.assertFalse(any(c[:2] == ['xcodebuild', 'test'] for c in commands))

    def test_lint_does_not_run_app_tests(self):
        code, commands, status = self.invoke('lint')
        self.assertEqual(code, 0)
        self.assertFalse(any('test' in c or 'Tests/run-tests.py' in c for c in commands))
        self.assertFalse(any('simctl' in c for c in commands))

    def test_app_failure_marks_lane_failed(self):
        code, commands, status = self.invoke('apps', fail='MYKit-Example')
        self.assertEqual(code, 1)
        self.assertEqual(status['exit_code'], 1)
        self.assertFalse(any('Utilities' in c for c in commands))

    def test_lint_failure_marks_lane_failed(self):
        code, commands, status = self.invoke('lint', fail='lint')
        self.assertEqual(code, 1)
        self.assertEqual(status['exit_code'], 1)


if __name__ == '__main__':
    unittest.main()
