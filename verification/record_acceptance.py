import json
import os
from pathlib import Path
import subprocess
import sys

kind = sys.argv[1]
root = Path('evidence')
result = root / (kind + '.xcresult')
if not result.exists():
    raise SystemExit('No native result bundle was produced')
summary = json.loads(subprocess.check_output([
    'xcrun', 'xcresulttool', 'get', 'test-results', 'summary', '--path', str(result)
]))
(root / 'test-summary.json').write_text(json.dumps(summary, indent=2) + '\n')
folder = root / (kind + '-screenshots')
manifest = json.loads((folder / 'manifest.json').read_text())
expected = {
    'testRealEstimateFeedbackAndHistorySurviveRelaunch': ['Ready', 'Estimating', 'Feedback', 'Finished', 'Persisted history'],
    'testRelaunchInterruptsAnUnfinishedSession': ['Interrupted history'],
    'testCancelDoesNotManufactureAnEstimate': ['Cancelled history'],
    'testRepeatedPracticeRequiresEachEstimateAndExplicitAdvance': ['Repeated practice history'],
    'testPrivacyIsAvailableWithoutStartingPractice': ['About and privacy'],
    'testCalibrationComparesIntervalsAndEarlierObservations': ['Calibration comparison', 'Other interval calibration'],
    'testTrainingRepeatsAndPersistsWithoutCreatingEstimates': ['Training running', 'Training complete', 'Training history'],
    'testTrainingCancellationRetainsNoInventedCues': ['Cancelled training'],
    'testTrainingRelaunchInterruptsInsteadOfCompleting': ['Interrupted training'],
}
if kind == 'phone':
    expected['testPocketExperimentSchedulesAndCancelsSystemRequests'] = ['Pocket cues scheduled', 'Pocket cues cancelled']
else:
    expected['testQuietPracticeRejectsAWindowBeyondTheRuntimeLimit'] = ['Quiet practice limit']
media = []
missing = []
for name, captures in expected.items():
    case = next((item for item in manifest if item['testIdentifier'] == 'PracticeUITests/' + name + '()'), None)
    if case is None:
        missing.append(name + ': no attachments')
        continue
    attachments = case['attachments']
    files = [item['exportedFileName'] for item in attachments]
    videos = [name for name in files if name.endswith('.mp4') and (folder / name).stat().st_size > 1024]
    if not videos:
        missing.append(name + ': no native test recording')
    for capture in captures:
        if not any(item['suggestedHumanReadableName'].startswith(capture + '_') and item['exportedFileName'].endswith('.png') for item in attachments):
            missing.append(name + ': no ' + capture + ' screenshot')
    timing = next((item for item in attachments if item['suggestedHumanReadableName'].startswith('Launch to ready (automation)_')), None)
    seconds = None
    if timing is None:
        missing.append(name + ': no launch observation')
    else:
        seconds = float((folder / timing['exportedFileName']).read_text().strip().split('=')[1])
    media.append({'journey': name, 'videos': videos, 'captures': captures, 'launch_to_ready_seconds_including_automation': seconds})
main = next((item for item in manifest if 'testRealEstimateFeedbackAndHistorySurviveRelaunch' in item['testIdentifier']), None)
contrast = 'not_checked'
if main is not None:
    bounds = next((item for item in main['attachments'] if item['suggestedHumanReadableName'].startswith('Navigation title bounds_')), None)
    ready = next((item for item in main['attachments'] if item['suggestedHumanReadableName'].startswith('Ready_') and item['exportedFileName'].endswith('.png')), None)
    if bounds is not None and ready is not None:
        check = subprocess.run(['swift', 'verification/check_title_contrast.swift', str(folder / ready['exportedFileName']), str(folder / bounds['exportedFileName'])], text=True, capture_output=True)
        contrast = check.stdout.strip()
        print(check.stdout + check.stderr)
        if check.returncode != 0:
            missing.append('rendered navigation title contrast failed')
    else:
        missing.append('navigation title geometry or image missing')
passed = summary.get('result') == 'Passed' and summary.get('failedTests', 0) == 0 and summary.get('passedTests', 0) >= len(expected) and not missing
receipt = {
    'candidate': os.environ['GITHUB_SHA'], 'candidate_tree': subprocess.check_output(['git', 'rev-parse', 'HEAD^{tree}'], text=True).strip(), 'run': os.environ['GITHUB_RUN_ID'],
    'kind': kind, 'result': 'passed' if passed else 'failed',
    'summary': summary, 'media': media, 'missing_evidence': missing, 'title_contrast': contrast,
    'physical_haptics': 'not_run', 'store_distribution': 'not_run',
}
(root / 'receipt.json').write_text(json.dumps(receipt, indent=2) + '\n')
if not passed:
    raise SystemExit('Native acceptance incomplete: ' + '; '.join(missing or ['one or more UI journeys failed']))
print(f'PASS: {len(expected)} native journeys with their screenshots, app recordings and launch observations.')
