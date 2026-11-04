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
}
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
passed = summary.get('result') == 'Passed' and summary.get('failedTests', 0) == 0 and summary.get('passedTests', 0) >= len(expected) and not missing
receipt = {
    'candidate': os.environ['GITHUB_SHA'], 'run': os.environ['GITHUB_RUN_ID'],
    'kind': kind, 'result': 'passed' if passed else 'failed',
    'summary': summary, 'media': media, 'missing_evidence': missing,
    'physical_haptics': 'not_run', 'store_distribution': 'not_run',
}
(root / 'receipt.json').write_text(json.dumps(receipt, indent=2) + '\n')
if not passed:
    raise SystemExit('Native acceptance incomplete: ' + '; '.join(missing or ['one or more UI journeys failed']))
print('PASS: five native journeys with their screenshots, app recordings and launch observations.')
