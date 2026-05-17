# Codex SVG Refinement Prompt

You are refining the Appiombi hoof logo SVG using the SVG Genesis pipeline.

Inputs:

- Reference PNG: `assets/images/hoof_single_card_reference.png`
- Target SVG: `assets/images/hoof_logo.svg`
- Fallback/master SVG: `assets/images/hoof_single_card_master.svg`
- Latest report: `tools/svg_genesis/outputs/report_latest.md`
- Latest score: `tools/svg_genesis/outputs/score_latest.json`
- Latest overlay: `tools/svg_genesis/outputs/overlay_latest.png`
- Latest diff: `tools/svg_genesis/outputs/diff_latest.png`

Rules:

- Do not modify the reference PNG.
- Do not modify `assets/images/hoof_single_card_master.svg`.
- Do not modify `tools/hoof_svg_trace_preview.html`.
- Do not embed or rasterize the PNG inside the SVG.
- Make small, reviewable SVG geometry changes.
- Re-run `python tools/svg_genesis/run_svg_genesis.py` after each iteration.
- Use the report metrics to describe whether alignment improved.

Recommended loop:

1. Read `report_latest.md` and `score_latest.json`.
2. Inspect overlay and diff visually.
3. Adjust only `assets/images/hoof_logo.svg`.
4. Re-run the pipeline.
5. Compare metrics and summarize the change.
