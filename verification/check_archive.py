import json
import os
from pathlib import Path
import plistlib
import subprocess
import sys

archive = Path(sys.argv[1])
phone = archive / 'Products/Applications/Chronoception.app'
watch = phone / 'Watch/ChronoceptionWatch.app'
archive_info = plistlib.loads((archive / 'Info.plist').read_bytes())
assert set(path.name for path in (archive / 'Products/Applications').iterdir()) == {'Chronoception.app'}, 'Archive must contain one top-level app with Watch embedded'
assert archive_info['ApplicationProperties']['ApplicationPath'] == 'Applications/Chronoception.app'
expected = [(phone, 'io.mjjt.chronoception'), (watch, 'io.mjjt.chronoception.watchkitapp')]
products = []
for path, identifier in expected:
    info = plistlib.loads((path / 'Info.plist').read_bytes())
    assert info['CFBundleIdentifier'] == identifier, info
    executable = path / info['CFBundleExecutable']
    assert executable.is_file(), executable
    architectures = subprocess.check_output(['xcrun', 'lipo', '-archs', str(executable)], text=True).strip()
    products.append({'bundle': identifier, 'version': info['CFBundleShortVersionString'], 'architectures': architectures})
watch_info = plistlib.loads((watch / 'Info.plist').read_bytes())
assert watch_info['WKApplication'] is True
assert watch_info['WKRunsIndependentlyOfCompanionApp'] is True
assert watch_info['WKCompanionAppBundleIdentifier'] == expected[0][1]
Path('evidence').mkdir(exist_ok=True)
Path('evidence/archive.json').write_text(json.dumps({
    'candidate': os.environ.get('GITHUB_SHA'),
    'result': 'compiled_unsigned',
    'products': products,
    'distribution': 'not_run'
}, indent=2) + '\n')
print('Release archive contains both native applications; signing and distribution remain separate.')
