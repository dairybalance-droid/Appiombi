from __future__ import annotations

import json
import sys
from pathlib import Path

sys.dont_write_bytecode = True

from compare_overlay import compare_overlay
from generate_report import generate_report, write_score
from render_svg import render_svg


def load_config(base_dir: Path) -> dict:
    config_path = base_dir / "config.json"
    return json.loads(config_path.read_text(encoding="utf-8"))


def main() -> int:
    base_dir = Path(__file__).resolve().parent
    config = load_config(base_dir)

    render_result = render_svg(config, base_dir)
    compare_result = compare_overlay(
        config=config,
        base_dir=base_dir,
        rendered_png=render_result.output_png,
        render_ok=render_result.render_ok,
    )
    write_score(compare_result, render_result, base_dir)
    report_path = generate_report(config, base_dir, render_result, compare_result)

    print(f"SVG render: {render_result.output_png}")
    print(f"Overlay: {compare_result.overlay_png}")
    print(f"Diff: {compare_result.diff_png}")
    print(f"Score: {compare_result.score_json}")
    print(f"Report: {report_path}")

    if render_result.target_missing:
        print("Note: target SVG is missing; fallback SVG was used when available.")
    if not render_result.render_ok:
        print("Warning: true SVG rendering failed; see report for details.")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
