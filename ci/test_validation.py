"""Coverage gates must reject incomplete or misleading parallel results."""
import copy
import json
from pathlib import Path
import tempfile
import unittest

import validation

ROOT = Path(__file__).resolve().parents[1]

class ValidationTests(unittest.TestCase):
    def setUp(self):
        self.lanes = json.loads((ROOT / 'ci/lanes.json').read_text())
        self.matrix = json.loads((ROOT / 'Tests/matrix.json').read_text())

    def test_partition_contains_every_mode_once(self):
        validation.validate_lanes(self.lanes, self.matrix)

    def test_missing_duplicate_and_unknown_modes_fail(self):
        for change in ('missing', 'duplicate', 'unknown'):
            with self.subTest(change=change):
                lanes = copy.deepcopy(self.lanes)
                if change == 'missing': lanes[1]['modes'].pop()
                if change == 'duplicate': lanes[2]['modes'].append('Native')
                if change == 'unknown': lanes[1]['modes'][0] = 'UnknownMode'
                with self.assertRaises(ValueError): validation.validate_lanes(lanes, self.matrix)

    def test_missing_non_safekit_lane_fails(self):
        for kind in ('apps', 'lint'):
            with self.assertRaises(ValueError):
                validation.validate_lanes([x for x in self.lanes if x['kind'] != kind], self.matrix)

    def test_failed_cancelled_skipped_or_missing_job_fails(self):
        good = {'prepare': {'result': 'success'}, 'validate': {'result': 'success'}}
        validation.validate_job_results(good)
        for status in ('failure', 'cancelled', 'skipped'):
            for job in good:
                needs = copy.deepcopy(good);needs[job]['result'] = status
                with self.assertRaises(ValueError): validation.validate_job_results(needs)
        with self.assertRaises(ValueError): validation.validate_job_results({})

    def fixture(self, root):
        def write(path, value):
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text(json.dumps(value))
        def tree(names):
            return {'testNodes': [{'nodeType': 'Test Case', 'nodeIdentifier': n, 'result': 'Passed'} for n in names]}
        for lane in self.lanes:
            directory = root / ('ios-validation-' + lane['name'])
            write(directory / 'lane.json', {**lane, 'exit_code': 0, 'head_sha': 'test-sha'})
            if lane['kind'] == 'safekit':
                for mode in lane['modes']:
                    write(directory / 'safekit' / mode / 'tests.json', tree(['SafeKitTests/' + n for n in self.matrix[mode]]))
            elif lane['kind'] == 'apps':
                for suite, path in [('example', ROOT / 'Example/Tests/acceptance.json'), ('utilities', ROOT / 'Tests/acceptance/Utilities.json')]:
                    write(directory / suite / 'tests.json', tree(validation.required_tests(path)))
            else:
                write(directory / 'lint-result.json', {'exit_code': 0})
        return root

    def test_complete_results_keep_all_169_executions(self):
        with tempfile.TemporaryDirectory() as tmp:
            result = validation.aggregate(self.fixture(Path(tmp)), ROOT, 'test-sha')
            self.assertEqual(result['total_tests'], 169)
            self.assertEqual(result['safekit_modes'], 11)
            self.assertTrue(result['passed'])

    def test_missing_wrong_skipped_failed_and_duplicate_test_fail(self):
        for fault in ('missing', 'wrong', 'Skipped', 'Failed', 'duplicate'):
            with self.subTest(fault=fault), tempfile.TemporaryDirectory() as tmp:
                root = self.fixture(Path(tmp))
                path = root / 'ios-validation-safekit-a/safekit/Native/tests.json'
                data = json.loads(path.read_text())
                if fault == 'missing': data['testNodes'].pop()
                elif fault == 'wrong': data['testNodes'][0]['nodeIdentifier'] = 'SafeKitTests/notTheSelectedTest'
                elif fault == 'duplicate': data['testNodes'].append(data['testNodes'][0])
                else: data['testNodes'][0]['result'] = fault
                path.write_text(json.dumps(data))
                with self.assertRaises(ValueError): validation.aggregate(root, ROOT, 'test-sha')

    def test_missing_artifact_and_failed_lane_and_wrong_commit_fail(self):
        for fault in ('missing', 'failed', 'commit'):
            with self.subTest(fault=fault), tempfile.TemporaryDirectory() as tmp:
                root = self.fixture(Path(tmp)); path = root / 'ios-validation-apps/lane.json'
                if fault == 'missing': path.unlink()
                else:
                    data = json.loads(path.read_text());data['exit_code' if fault == 'failed' else 'head_sha'] = 1 if fault == 'failed' else 'old-sha';path.write_text(json.dumps(data))
                with self.assertRaises((ValueError, FileNotFoundError)): validation.aggregate(root, ROOT, 'test-sha')

    def test_lint_failure_cannot_pass(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = self.fixture(Path(tmp));(root/'ios-validation-lint/lint-result.json').write_text('{"exit_code": 1}')
            with self.assertRaises(ValueError): validation.aggregate(root, ROOT, 'test-sha')

if __name__ == '__main__':
    unittest.main()
