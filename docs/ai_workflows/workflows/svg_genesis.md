# SVG Genesis Workflow

Workflow per usare `tools/svg_genesis/`.

## Scopo

Confrontare una PNG reference con uno SVG target e generare:

- render PNG dello SVG;
- overlay;
- diff;
- score JSON;
- report markdown.

## Config

Modificare solo `tools/svg_genesis/config.json` per cambiare:

- `reference_png`;
- `target_svg`;
- `fallback_svg`;
- `output_dir`;
- `canvas_width`;
- `canvas_height`;
- `svg_initial_opacity`.

## Renderer

La pipeline prova in ordine:

1. CairoSVG;
2. Chrome headless;
3. Edge headless;
4. diagnostic fallback.

Su Windows CairoSVG puo fallire se manca la libreria nativa Cairo.

## Fallback

Se `target_svg` non esiste, la pipeline puo usare `fallback_svg`. Il report deve indicare:

- `target_missing`;
- `used_fallback`;
- `selected_svg`;
- `renderer_used`;
- `render_ok`.

## Output

Gli output stanno in:

```text
tools/svg_genesis/outputs/
```

Da non committare:

- `svg_render_latest.png`;
- `overlay_latest.png`;
- `diff_latest.png`;
- `score_latest.json`;
- `report_latest.md`;
- file temporanei.

Da committare:

- script;
- README;
- config;
- prompt;
- `.gitkeep`;
- `.gitignore` degli output.

## Comando

```bash
python tools/svg_genesis/run_svg_genesis.py
```

Su ambienti senza Python nel PATH, usare il runtime indicato dall'utente.
