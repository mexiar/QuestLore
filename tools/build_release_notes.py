#!/usr/bin/env python3
"""Bundle the five most recent installed-release notes, newest first."""
import json,re
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
LANGUAGES=('es','en','fr','de','pt','pl','ru')
def key(version):
    match=re.fullmatch(r'(\d+)\.(\d+)\.(\d+)(?:-(alpha|beta|rc)(\d+))?',version)
    assert match,version
    return tuple(map(int,match.group(1,2,3)))+({'alpha':1,'beta':2,'rc':3,None:4}[match[4]],int(match[5] or 0))
def main():
    installed=re.search(r'^## Version: (.+)$',(ROOT/'QuestLore/QuestLore.toc').read_text(),re.M)[1]
    records=[json.loads(p.read_text()) for p in (ROOT/'docs/release-notes').glob('*.json')]
    records=sorted((r for r in records if key(r['version'])<=key(installed)),key=lambda r:key(r['version']),reverse=True)[:5]
    assert len(records)==5 and records[0]['version']==installed
    for record in records:assert set(record['notes'])==set(LANGUAGES) and all(record['notes'].values())
    def notes(values):return '{\n'+''.join('        '+lang+' = '+ '[['+values[lang]+']],\n' for lang in LANGUAGES)+'    }'
    text='local _, ns = ...\n-- Generated from docs/release-notes; the last five installed releases only.\nns.ReleaseNotes = {\n    version = '+json.dumps(installed)+',\n    notes = '+notes(records[0]['notes'])+',\n    history = {\n'
    for record in records:text+='        {version='+json.dumps(record['version'])+', notes='+notes(record['notes'])+'},\n'
    text+='    },\n}\n';(ROOT/'QuestLore/ReleaseNotes.lua').write_text(text)
    print('Release archive:',', '.join(r['version'] for r in records))
if __name__=='__main__':main()
