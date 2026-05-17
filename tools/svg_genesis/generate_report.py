from __future__ import annotations

import json
from datetime import datetime
from pathlib import Path
from typing import Any

from compare_overlay import CompareResult
from render_svg import RenderResult


def _rel(path: Path, base_dir: Path) -> str:
    repo_root = base_dir.parent.parent
    try:
        return path.resolve().relative_to(repo_root.resolve()).as_posix()
    except ValueError:
        return str(path)


def write_score(compare_result: CompareResult, render_result: RenderResult, base_dir: Path) -> None:
    payload = {
        "reference_png": _rel(compare_result.reference_png, base_dir),
        "rendered_png": _rel(compare_result.rendered_png, base_dir),
        "overlay_png": _rel(compare_result.overlay_png, base_dir),
        "diff_png": _rel(compare_result.diff_png, base_dir),
        "target_svg": _rel(render_result.requested_svg, base_dir),
        "selected_svg": _rel(render_result.rendered_svg, base_dir) if render_result.rendered_svg else None,
        "target_missing": render_result.target_missing,
        "used_fallback": render_result.used_fallback,
        "render_ok": render_result.render_ok,
        "renderer_used": render_result.renderer_used,
        "render_error": render_result.error,
        "metrics": compare_result.metrics,
    }
    compare_result.score_json.write_text(
        json.dumps(payload, indent=2, ensure_ascii=True) + "\n",
        encoding="utf-8",
    )


def generate_report(
    config: dict[str, Any],
    base_dir: Path,
    render_result: RenderResult,
    compare_result: CompareResult,
) -> Path:
    output_dir = (base_dir / config["output_dir"]).resolve()
    report_path = output_dir / "report_latest.md"
    rendered_svg = render_result.rendered_svg

    status_lines = [
        f"- Generated at: {datetime.now().isoformat(timespec='seconds')}",
        f"- Target SVG configured: `{_rel(render_result.requested_svg, base_dir)}`",
        f"- Target SVG exists: `{not render_result.target_missing}`",
        f"- Fallback used: `{render_result.used_fallback}`",
        f"- Render OK: `{render_result.render_ok}`",
        f"- Renderer used: `{render_result.renderer_used}`",
    ]

    if rendered_svg:
        status_lines.append(f"- SVG selected for rendering: `{_rel(rendered_svg, base_dir)}`")
    else:
        status_lines.append("- SVG selected for rendering: `none`")

    if render_result.render_ok and rendered_svg:
        status_lines.append(f"- SVG actually rendered: `{_rel(rendered_svg, base_dir)}`")
    else:
        status_lines.append("- SVG actually rendered: `none; diagnostic PNG generated instead`")

    if render_result.error:
        status_lines.append(f"- Render warning/error: `{render_result.error}`")

    metrics = compare_result.metrics
    metric_lines = [
        f"- Mean absolute difference: `{metrics['mean_absolute_difference']}`",
        f"- RMS difference: `{metrics['rms_difference']}`",
        f"- Diff bbox: `{metrics['diff_bbox']}`",
        f"- Reference alpha bbox: `{metrics['reference_alpha_bbox']}`",
        f"- SVG alpha bbox: `{metrics['svg_alpha_bbox']}`",
        f"- Alpha area ratio: `{metrics['alpha_area_ratio']}`",
    ]

    files = [
        f"- SVG render: `{_rel(compare_result.rendered_png, base_dir)}`",
        f"- Overlay: `{_rel(compare_result.overlay_png, base_dir)}`",
        f"- Diff: `{_rel(compare_result.diff_png, base_dir)}`",
        f"- Score JSON: `{_rel(compare_result.score_json, base_dir)}`",
    ]

    recommendations = [
        "- Use the overlay to inspect large alignment and scale errors.",
        "- Use the diff image for edge and silhouette mismatches.",
        "- Iterate on the target SVG, not on the PNG reference or fallback master.",
    ]

    if render_result.target_missing:
        recommendations.insert(
            0,
            "- `assets/images/hoof_logo.svg` does not exist. This run used the fallback master only to test the pipeline.",
        )

    if not render_result.render_ok:
        recommendations.insert(
            0,
            "- Install `cairosvg` plus native Cairo, or install Chrome/Edge, to enable true SVG rendering.",
        )

    report = "\n".join(
        [
            "# SVG Genesis Report",
            "",
            "## Status",
            *status_lines,
            "",
            "## Metrics",
            *metric_lines,
            "",
            "## Outputs",
            *files,
            "",
            "## Recommended Next Steps",
            *recommendations,
            "",
        ]
    )
    report_path.write_text(report, encoding="utf-8")
    return report_path
