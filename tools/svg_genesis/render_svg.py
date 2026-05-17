from __future__ import annotations

import html
import subprocess
from dataclasses import dataclass
from pathlib import Path
from typing import Any

from PIL import Image, ImageDraw


@dataclass
class RenderResult:
    requested_svg: Path
    rendered_svg: Path | None
    output_png: Path
    used_fallback: bool
    target_missing: bool
    render_ok: bool
    renderer_used: str
    error: str | None = None


def _resolve(base_dir: Path, configured_path: str) -> Path:
    return (base_dir / configured_path).resolve()


def _write_diagnostic_png(output_png: Path, width: int, height: int, message: str) -> None:
    image = Image.new("RGBA", (width, height), (248, 250, 252, 255))
    draw = ImageDraw.Draw(image)
    border = (148, 163, 184, 255)
    text = (30, 41, 59, 255)
    draw.rectangle((16, 16, width - 17, height - 17), outline=border, width=2)
    draw.multiline_text((36, 36), message, fill=text, spacing=6)
    image.save(output_png)


def _browser_candidates() -> list[tuple[str, Path]]:
    return [
        ("chrome_headless", Path(r"C:\Program Files\Google\Chrome\Application\chrome.exe")),
        ("chrome_headless", Path(r"C:\Program Files (x86)\Google\Chrome\Application\chrome.exe")),
        ("edge_headless", Path(r"C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe")),
        ("edge_headless", Path(r"C:\Program Files\Microsoft\Edge\Application\msedge.exe")),
    ]


def _write_browser_html(svg_path: Path, html_path: Path, width: int, height: int) -> None:
    svg_uri = html.escape(svg_path.as_uri(), quote=True)
    html_path.write_text(
        f"""<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="utf-8" />
    <meta name="viewport" content="width={width}, height={height}, initial-scale=1" />
    <style>
      * {{
        box-sizing: border-box;
      }}

      html,
      body {{
        width: {width}px;
        height: {height}px;
        margin: 0;
        overflow: hidden;
        background: transparent;
      }}

      img {{
        display: block;
        width: {width}px;
        height: {height}px;
        object-fit: contain;
      }}
    </style>
  </head>
  <body>
    <img src="{svg_uri}" alt="SVG render target" />
  </body>
</html>
""",
        encoding="utf-8",
    )


def _render_with_browser(
    svg_path: Path,
    output_png: Path,
    output_dir: Path,
    width: int,
    height: int,
) -> tuple[bool, str | None, str | None]:
    html_path = output_dir / "_render_svg_temp.html"
    _write_browser_html(svg_path, html_path, width, height)

    errors: list[str] = []
    try:
        for renderer_name, browser_path in _browser_candidates():
            if not browser_path.exists():
                errors.append(f"{renderer_name}: not found at {browser_path}")
                continue

            for headless_flag in ("--headless=new", "--headless"):
                if output_png.exists():
                    output_png.unlink()

                command = [
                    str(browser_path),
                    headless_flag,
                    "--disable-gpu",
                    "--hide-scrollbars",
                    "--allow-file-access-from-files",
                    "--default-background-color=00000000",
                    "--force-device-scale-factor=1",
                    f"--window-size={width},{height}",
                    f"--screenshot={output_png}",
                    html_path.as_uri(),
                ]
                try:
                    completed = subprocess.run(
                        command,
                        capture_output=True,
                        text=True,
                        timeout=30,
                        check=False,
                    )
                except Exception as exc:
                    errors.append(f"{renderer_name} with {headless_flag}: {exc}")
                    continue

                if completed.returncode == 0 and output_png.exists() and output_png.stat().st_size > 0:
                    return True, renderer_name, None

                detail = (completed.stderr or completed.stdout or "no browser output").strip()
                errors.append(f"{renderer_name} with {headless_flag}: {detail}")
    finally:
        if html_path.exists():
            html_path.unlink()

    return False, None, "\n".join(errors)


def render_svg(config: dict[str, Any], base_dir: Path) -> RenderResult:
    output_dir = _resolve(base_dir, config["output_dir"])
    output_dir.mkdir(parents=True, exist_ok=True)
    output_png = output_dir / "svg_render_latest.png"

    target_svg = _resolve(base_dir, config["target_svg"])
    fallback_svg = _resolve(base_dir, config["fallback_svg"])
    width = int(config["canvas_width"])
    height = int(config["canvas_height"])

    target_missing = not target_svg.exists()
    used_fallback = target_missing and fallback_svg.exists()
    svg_to_render = fallback_svg if used_fallback else target_svg

    if not svg_to_render.exists():
        message = (
            "SVG Genesis diagnostic render\n\n"
            f"Target SVG missing: {target_svg}\n"
            f"Fallback SVG missing: {fallback_svg}\n"
        )
        _write_diagnostic_png(output_png, width, height, message)
        return RenderResult(
            requested_svg=target_svg,
            rendered_svg=None,
            output_png=output_png,
            used_fallback=False,
            target_missing=target_missing,
            render_ok=False,
            renderer_used="diagnostic_fallback",
            error="No target or fallback SVG was available.",
        )

    errors: list[str] = []
    try:
        import cairosvg

        cairosvg.svg2png(
            url=str(svg_to_render),
            write_to=str(output_png),
            output_width=width,
            output_height=height,
        )
        return RenderResult(
            requested_svg=target_svg,
            rendered_svg=svg_to_render,
            output_png=output_png,
            used_fallback=used_fallback,
            target_missing=target_missing,
            render_ok=True,
            renderer_used="cairosvg",
        )
    except Exception as exc:
        errors.append(f"cairosvg: {exc}")

    browser_ok, browser_renderer, browser_error = _render_with_browser(
        svg_path=svg_to_render,
        output_png=output_png,
        output_dir=output_dir,
        width=width,
        height=height,
    )
    if browser_ok and browser_renderer:
        return RenderResult(
            requested_svg=target_svg,
            rendered_svg=svg_to_render,
            output_png=output_png,
            used_fallback=used_fallback,
            target_missing=target_missing,
            render_ok=True,
            renderer_used=browser_renderer,
            error="\n".join(errors) if errors else None,
        )

    if browser_error:
        errors.append(browser_error)

    error_text = "\n".join(errors)
    message = (
        "SVG Genesis diagnostic render\n\n"
        "The SVG could not be rendered to pixels.\n"
        f"SVG selected: {svg_to_render}\n"
        f"Errors:\n{error_text}\n\n"
        "Install CairoSVG with native Cairo, or install Chrome/Edge."
    )
    _write_diagnostic_png(output_png, width, height, message)
    return RenderResult(
        requested_svg=target_svg,
        rendered_svg=svg_to_render,
        output_png=output_png,
        used_fallback=used_fallback,
        target_missing=target_missing,
        render_ok=False,
        renderer_used="diagnostic_fallback",
        error=error_text,
    )
