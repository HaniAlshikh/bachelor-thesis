#

## Setup environment

### SVG

install `inkscape` to auto convert `svg` to `pdf` and include it

```shell
brew install --cask inkscape
```

### Glossary

#### VS Code Latex workshop

the following need to be added to VS code settings if latex workshop is used

```json
"latex-workshop.latex.recipes":[
    {
        "name": "pdflatex, bibtex, makeglossaries, pdflatex",
        "tools": [
            "pdflatex",
            "bibtex",
            "makeglossaries",
            "pdflatex"
        ]
    },
],
"latex-workshop.latex.tools":[
    {
        "name": "pdflatex",
        "command": "pdflatex",
        "args": [
            "-shell-escape", # needed when using inkscape
            "-synctex=1",
            "-interaction=nonstopmode",
            "-file-line-error",
            "%DOCFILE%"
        ]
    },
    {
        "name": "bibtex",
        "command": "bibtex",
        "args": [
            "%DOCFILE%"
        ]
    },
    {
        "name": "makeglossaries",
        "command": "makeglossaries",
        "args": [
            "%DOCFILE%"
        ]
        }
]
```
