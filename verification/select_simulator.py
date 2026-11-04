import json
import os
from pathlib import Path
import re
import subprocess
import sys

kind=sys.argv[1]
inventory=json.loads(subprocess.check_output(['xcrun','simctl','list','-j']))
def choose(platform):
    sdk = 'iphonesimulator' if platform == 'iOS' else 'watchsimulator'
    version = subprocess.check_output(['xcrun', '--sdk', sdk, '--show-sdk-version'], text=True).strip()
    compatible = tuple(map(int, version.split('.')[:2]))
    groups=[(key,devices)for key,devices in inventory['devices'].items()if platform in key and tuple(map(int,re.findall(r'\d+',key)[:2])) == compatible]
    groups.sort(key=lambda item:tuple(map(int,re.findall(r'\d+',item[0]))),reverse=True)
    for runtime,devices in groups:
        candidates=[d for d in devices if d.get('isAvailable') and ('iPhone' in d['name'] if platform=='iOS' else 'Apple Watch' in d['name'])]
        if candidates:return candidates[0]
    raise RuntimeError('No available '+platform+' simulator matching SDK '+version)
phone=choose('iOS')
selected=phone if kind=='phone' else choose('watchOS')
if kind=='watch':
    existing=next((p for p in inventory.get('pairs',{}).values()if p.get('watch',{}).get('udid')==selected['udid']),None)
    if existing:phone={'udid':existing['phone']['udid'],'name':existing['phone'].get('name','paired iPhone')}
    else:subprocess.run(['xcrun','simctl','pair',selected['udid'],phone['udid']],check=True)
    subprocess.run(['xcrun','simctl','bootstatus',phone['udid'],'-b'],check=True)
subprocess.run(['xcrun','simctl','bootstatus',selected['udid'],'-b'],check=True)
with open(os.environ['GITHUB_OUTPUT'],'a')as output:output.write('device='+selected['udid']+'\n')
Path('evidence').mkdir(exist_ok=True)
Path('evidence/device.json').write_text(json.dumps({'kind':kind,'selected':selected,'phone':phone},indent=2))
print('Selected',selected['name'],selected['udid'])
