#!/usr/bin/env python3
"""Isolated non-owner Plasma loader; no live bus, GPU or network access."""
from pathlib import Path
import os, shutil, subprocess, sys, tempfile
base = Path(__file__).resolve().parents[2]
root = Path(tempfile.mkdtemp(prefix='ffxi-test-', dir=Path.home()))
print('EVIDENCE',root,flush=True)
env = os.environ.copy()
for key in ['DISPLAY','WAYLAND_DISPLAY','DBUS_SESSION_BUS_ADDRESS','SESSION_MANAGER']:
    env.pop(key,None)
for key, name in [('XDG_DATA_HOME','data'),('XDG_CONFIG_HOME','config'),('XDG_CACHE_HOME','cache'),('XDG_RUNTIME_DIR','run')]:
    p=root/name; p.mkdir(mode=0o700); env[key]=str(p)
shutil.copyfile('/usr/share/color-schemes/BreezeDark.colors',root/'config/kdeglobals')
env.update(QT_QPA_PLATFORMTHEME='kde',QT_QPA_PLATFORM='offscreen',QT_QUICK_BACKEND='software',QT_FORCE_STDERR_LOGGING='1',QT_LOGGING_RULES='*.debug=false;qml.debug=true;*.warning=true;*.critical=true',TZ='America/Chicago')
pkg=root/'data/plasma/plasmoids/com.pennywiseops.ffxitimers'
source=Path(sys.argv[1]) if len(sys.argv)>1 else base/'plasmoid/FFXITimers'
shutil.copytree(source,pkg)
bus=root/'bus.conf'; bus.write_text('<busconfig><type>session</type><listen>unix:tmpdir='+str(root/'run')+'</listen><auth>EXTERNAL</auth><policy context="default"><allow send_destination="*"/><allow eavesdrop="true"/><allow own="*"/></policy></busconfig>')
cmd=['dbus-run-session','--config-file='+str(bus),'--',str(base/'tests/plasma/build/ffxi-widget-test'),str(base/'tests/plasma/Runner.qml')]
if len(sys.argv)>2: cmd.append(sys.argv[2])
r=subprocess.run(cmd,env=env,cwd=root,stdout=subprocess.PIPE,stderr=subprocess.STDOUT,text=True,timeout=30)
(root/'run.log').write_text(r.stdout)
print(r.stdout,flush=True)
sys.exit(r.returncode)
