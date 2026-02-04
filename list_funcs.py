import re
from pathlib import Path
root = Path("aliases.d")
for path in sorted(root.glob('*.sh')):
    text = path.read_text().splitlines()
    funcs = []
    for line in text:
        m = re.match(r"\s*([A-Za-z0-9_]+)\s*\(\)\s*{", line)
        if m:
            funcs.append(m.group(1))
    aliases = []
    for line in text:
        line = line.strip()
        if line.startswith('alias '):
            name = line.split('=',1)[0].split()[1]
            aliases.append(name)
    print(path.name)
    print(' functions:', ', '.join(funcs))
    print(' aliases:', ', '.join(aliases))
    print()
