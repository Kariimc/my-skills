# <tool name>

One line: what it does.

## Run
```
C:/Users/karii/AppData/Local/Python/pythoncore-3.14-64/python.exe main.py <target>
```
(Windows gotcha: `python` on PATH is the slow WindowsApps shim — ~1.2s/spawn vs
~0.15s. Venvs use `Scripts\activate`, not `bin/`.)

## Verify
```
python main.py --dry-run sample && echo OK
```

## Deps
Pin in `requirements.txt`; prefer stdlib until a third use forces a dependency.
