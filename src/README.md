#

## Environment Setup

### MacOS & VS Code

1. install and setup [MikTex](https://miktex.org/download)
2. install [LaTeX Workshop](https://marketplace.visualstudio.com/items?itemName=James-Yu.latex-workshop)
3. Add the following to VS code settings if latex workshop is used

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

4. install `inkscape` to auto convert `svg` to `pdf` and include it

    ```shell
    brew install --cask inkscape
    ```

5. restart code if already open to update `$PATH` env with the new executables.
