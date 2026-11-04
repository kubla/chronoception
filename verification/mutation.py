from pathlib import Path
import json
import os
import subprocess
import tempfile

root = Path(__file__).resolve().parents[1]
cases = [
    ('error-sign', root/'Shared/Sources/ChronoceptionCore/Attempt.swift', 'elapsedSeconds - Double(interval.seconds)', 'Double(interval.seconds) - elapsedSeconds', 'testEarlyLateAndExactFeedback'),
    ('cancel-completes', root/'Shared/Sources/ChronoceptionCore/SessionEngine.swift', 'phase = .cancelled', 'phase = .completed', 'testCancellationIsTerminalAndKeepsCompletedAttempts'),
]
results=[]
with tempfile.TemporaryDirectory(prefix='chronoception-mutation-') as scratch:
    for name,path,old,new,test in cases:
        source=path.read_text()
        assert source.count(old)==1,(name,'mutation site changed')
        try:
            path.write_text(source.replace(old,new))
            result=subprocess.run(['swift','test','--package-path',str(root/'Shared'),'--scratch-path',scratch,'--filter',test],text=True,capture_output=True)
            output=result.stdout+result.stderr
            killed=result.returncode!=0 and test in output and ' failed ' in output and 'error: emit-module' not in output
            results.append({'mutation':name,'detected':killed,'test':test})
            print(output[-4500:])
            if not killed:raise RuntimeError('Meaningful mutation not detected: '+name)
        finally:
            path.write_text(source)
(root/'evidence').mkdir(exist_ok=True)
(root/'evidence/mutation.json').write_text(json.dumps(results,indent=2)+'\n')
print('PASS: both meaningful seeded faults were rejected by the production-core tests.')
