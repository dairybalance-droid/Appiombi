# SVG Genesis Pipeline

Pipeline read-only per confrontare una PNG di riferimento con un SVG target.
Gli output vengono scritti in `tools/svg_genesis/outputs/`.

## Flusso

1. Renderizza lo SVG scelto in `svg_render_latest.png`.
2. Ridimensiona la PNG reference sul canvas configurato.
3. Genera `overlay_latest.png`.
4. Genera `diff_latest.png`.
5. Calcola metriche semplici in `score_latest.json`.
6. Scrive `report_latest.md` con input, fallback ed esito.

## Configurazione

Modifica solo `config.json` per cambiare reference, SVG target, fallback,
dimensione canvas e opacita dell'overlay.

Valori iniziali:

- `reference_png`: PNG reference principale.
- `target_svg`: SVG da migliorare nelle iterazioni successive.
- `fallback_svg`: SVG master usato solo se il target non esiste.
- `output_dir`: cartella di output relativa a questa directory.

## Dipendenze

Richiede Python 3 con:

```bash
pip install pillow cairosvg
```

`Pillow` viene usato per overlay, diff e metriche. Il rendering SVG usa questa
strategia automatica:

1. `cairosvg`, se disponibile e funzionante.
2. Chrome headless, se installato in un percorso Windows comune.
3. Edge headless, se installato in un percorso Windows comune.
4. PNG diagnostico, se nessun renderer funziona.

Su Windows, CairoSVG puo richiedere anche la libreria nativa Cairo
(`cairo-2` / `libcairo-2.dll`) disponibile nel PATH. Il fallback browser crea
`outputs/_render_svg_temp.html` e usa il browser headless per generare
`outputs/svg_render_latest.png`. Il report e `score_latest.json` indicano
sempre `renderer_used`.

## Esecuzione

Dalla root del repository:

```bash
python tools/svg_genesis/run_svg_genesis.py
```

Su Windows, se `python` non e disponibile:

```bash
py tools/svg_genesis/run_svg_genesis.py
```

## Regole operative

- Non modificare la PNG reference.
- Non modificare `assets/images/hoof_single_card_master.svg`.
- Usa `assets/images/hoof_single_card_master.svg` solo come fallback/baseline.
- Non modificare `tools/hoof_svg_trace_preview.html`: e un preview legacy
  separato dalla pipeline.
- Non rasterizzare la PNG dentro lo SVG.
- Usare il report per guidare iterazioni successive su uno SVG target separato.
