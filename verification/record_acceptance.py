import json
import os
from pathlib import Path
import subprocess
import sys

kind=sys.argv[1]
result=Path('evidence')/(kind+'.xcresult')
if not result.exists():raise SystemExit('No native result bundle was produced')
summary=json.loads(subprocess.check_output(['xcrun','xcresulttool','get','test-results','summary','--path',str(result)]))
Path('evidence/test-summary.json').write_text(json.dumps(summary,indent=2)+'\n')
passed=summary.get('result')=='Passed' and summary.get('failedTests',0)==0 and summary.get('passedTests',0)>=5
receipt={'candidate':os.environ['GITHUB_SHA'],'run':os.environ['GITHUB_RUN_ID'],'kind':kind,'result':'passed' if passed else 'failed','summary':summary,'physical_haptics':'not_run','store_distribution':'not_run'}
Path('evidence/receipt.json').write_text(json.dumps(receipt,indent=2)+'\n')
if not passed:raise SystemExit('Native acceptance did not establish five passing UI journeys')
