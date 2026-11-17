#!/usr/bin/env python3
"""Validate checked-in runtime sources and package QuestLore without research data."""
import argparse
from pathlib import Path
import re
import shutil
import subprocess
import xml.etree.ElementTree as ET
import zipfile

ROOT = Path(__file__).resolve().parents[1]

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--lua', required=True, help='Lua 5.1 executable')
    args = parser.parse_args()
    lua = shutil.which(args.lua) or args.lua
    version = subprocess.run([lua, '-e', 'print(_VERSION)'], check=True, capture_output=True, text=True)
    if version.stdout.strip() != 'Lua 5.1':
        raise SystemExit('Lua 5.1 is required.')
    addon = ROOT / 'QuestLore'
    toc = (addon / 'QuestLore.toc').read_text()
    for path in addon.glob('*.toc'):
        if path.read_text() != toc:
            raise SystemExit(f'TOC variants disagree: {path.name}')
    for line in toc.splitlines():
        if line and not line.startswith('#') and not (addon / line).is_file():
            raise SystemExit(f'Missing runtime file: {line}')
    for path in addon.glob('*.lua'):
        subprocess.run([lua, '-e', "assert(loadstring(io.read('*a')))"], input=path.read_text(), text=True, check=True)
    ET.parse(addon / 'Bindings.xml')
    subprocess.run([lua, str(ROOT / 'tests/run.lua'), str(ROOT)], check=True)
    subprocess.run([lua, str(ROOT / 'tests/localization.lua'), str(ROOT)], check=True)
    subprocess.run([lua, str(ROOT / 'tests/translations.lua'), str(ROOT)], check=True)
    version = re.search(r'^## Version: (.+)$', toc, re.MULTILINE).group(1).strip()
    destination = ROOT / 'dist' / f'QuestLore-{version}.zip'
    destination.parent.mkdir(exist_ok=True)
    with zipfile.ZipFile(destination, 'w', zipfile.ZIP_DEFLATED) as archive:
        for path in sorted(addon.iterdir()):
            if path.is_file() and path.suffix in {'.lua', '.xml', '.toc', '.txt'}:
                archive.write(path, path.relative_to(ROOT))
    with zipfile.ZipFile(destination) as archive:
        if archive.testzip() is not None:
            raise SystemExit('Archive integrity check failed.')
    print(f'Packaged: {destination}')

if __name__ == '__main__':
    main()
