from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path
from typing import Any

from PIL import Image, ImageChops, ImageStat


@dataclass
class CompareResult:
    reference_png: Path
    rendered_png: Path
    overlay_png: Path
    diff_png: Path
    score_json: Path
    metrics: dict[str, Any]


def _resolve(base_dir: Path, configured_path: str) -> Path:
    return (base_dir / configured_path).resolve()


def _fit_to_canvas(image: Image.Image, width: int, height: int) -> Image.Image:
    image = image.convert("RGBA")
    image.thumbnail((width, height), Image.Resampling.LANCZOS)
    canvas = Image.new("RGBA", (width, height), (255, 255, 255, 0))
    x = (width - image.width) // 2
    y = (height - image.height) // 2
    canvas.alpha_composite(image, (x, y))
    return canvas


def _alpha_bbox_area(image: Image.Image) -> tuple[list[int] | None, int]:
    alpha = image.convert("RGBA").getchannel("A")
    bbox = alpha.getbbox()
    if not bbox:
        return None, 0
    left, top, right, bottom = bbox
    return [left, top, right, bottom], (right - left) * (bottom - top)


def compare_overlay(
    config: dict[str, Any],
    base_dir: Path,
    rendered_png: Path,
    render_ok: bool,
) -> CompareResult:
    output_dir = _resolve(base_dir, config["output_dir"])
    output_dir.mkdir(parents=True, exist_ok=True)

    width = int(config["canvas_width"])
    height = int(config["canvas_height"])
    opacity = float(config["svg_initial_opacity"])
    reference_png = _resolve(base_dir, config["reference_png"])

    reference = _fit_to_canvas(Image.open(reference_png), width, height)
    rendered = _fit_to_canvas(Image.open(rendered_png), width, height)

    reference_rgb = reference.convert("RGB")
    rendered_rgb = rendered.convert("RGB")

    overlay = Image.blend(reference_rgb, rendered_rgb, opacity)
    overlay_png = output_dir / "overlay_latest.png"
    overlay.save(overlay_png)

    diff = ImageChops.difference(reference_rgb, rendered_rgb)
    diff_png = output_dir / "diff_latest.png"
    diff.save(diff_png)

    stat = ImageStat.Stat(diff)
    mean_abs = sum(stat.mean) / len(stat.mean)
    rms = sum(value**2 for value in stat.rms) ** 0.5 / len(stat.rms)
    nonzero_bbox = diff.getbbox()
    ref_bbox, ref_area = _alpha_bbox_area(reference)
    svg_bbox, svg_area = _alpha_bbox_area(rendered)

    metrics: dict[str, Any] = {
        "render_ok": render_ok,
        "canvas_width": width,
        "canvas_height": height,
        "overlay_opacity": opacity,
        "mean_absolute_difference": round(mean_abs, 4),
        "rms_difference": round(rms, 4),
        "diff_bbox": list(nonzero_bbox) if nonzero_bbox else None,
        "reference_alpha_bbox": ref_bbox,
        "svg_alpha_bbox": svg_bbox,
        "reference_alpha_area": ref_area,
        "svg_alpha_area": svg_area,
        "alpha_area_delta": svg_area - ref_area,
        "alpha_area_ratio": round(svg_area / ref_area, 6) if ref_area else None,
    }

    score_json = output_dir / "score_latest.json"
    return CompareResult(
        reference_png=reference_png,
        rendered_png=rendered_png,
        overlay_png=overlay_png,
        diff_png=diff_png,
        score_json=score_json,
        metrics=metrics,
    )
