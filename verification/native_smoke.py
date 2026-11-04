import json
from pathlib import Path
import subprocess
import sys

kind, device, derived = sys.argv[1:]
name = 'Chronoception' if kind == 'phone' else 'ChronoceptionWatch'
platform = 'iphonesimulator' if kind == 'phone' else 'watchsimulator'
bundle = 'io.mjjt.chronoception' + ('.watchkitapp' if kind == 'watch' else '')
product = Path(derived) / ('Build/Products/Debug-' + platform) / (name + '.app')
def run(*args):
    print('Running:', ' '.join(args), flush=True)
    result = subprocess.run(args, timeout=120, capture_output=True, text=True)
    print(result.stdout + result.stderr, flush=True)
    result.check_returncode()
    return result
run('xcrun', 'simctl', 'install', device, str(product))
launched = run('xcrun', 'simctl', 'launch', device, bundle)
print(launched.stdout, flush=True)
run('xcrun', 'simctl', 'io', device, 'screenshot', 'evidence/' + kind + '-launch.png')
run('xcrun', 'simctl', 'terminate', device, bundle)
Path('evidence/launch.json').write_text(json.dumps({
    'kind': kind, 'bundle': bundle, 'launched': True,
    'meaning': 'Process launch only; native UI acceptance must still pass.'
}, indent=2) + '\n')
