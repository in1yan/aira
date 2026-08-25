"""
Extract individual flash cards from a PDF by detecting the blue border
around each card and splitting each page into a grid of card images.

How it works:
  1. Each PDF page is rendered to a high-resolution image (not read as an
     embedded image, since the whole page is usually one big embedded
     image -- rendering gives us full control over resolution and lets
     us crop precisely).
  2. Pixels matching the card's blue border colour are masked out and
     turned into contours; contours large enough to be a real border
     (not the little hand-icon or the decorative corner triangle) are
     kept as candidate card boxes.
  3. Two crop modes:
       - "border" (default): crop tightly to the detected blue border
         box itself -- just what's inside (and including) the blue
         rectangle, no title text, no yellow margin, no rotated ISBN text.
       - "full": cluster the boxes into rows/columns (handles 1-up, 2-up,
         2x2, 3x2, etc. layouts) and crop each card out to the midpoint
         between it and its neighbours, so the crop includes the title
         text above the border and the word/label line below it.
  4. Each cropped card is saved as its own image file.

Usage:
    python3 extract_cards.py input.pdf -o cards/
    python3 extract_cards.py input.pdf -o cards/ --border-color "8c2222"  # red border
    python3 extract_cards.py input.pdf -o cards/ --crop-mode full
    python3 extract_cards.py input.pdf -o cards/ --start 6 --end 6
    python3 extract_cards.py input.pdf -o cards/ --debug   # saves a page
                                                             # with detected
                                                             # boxes drawn,
                                                             # to sanity-check
                                                             # detection.
"""

import argparse
from pathlib import Path

import cv2
import pymupdf as fitz  # PyMuPDF
import numpy as np


def render_page(page: "fitz.Page", zoom: float) -> np.ndarray:
    """Render a PDF page to a BGR numpy image (OpenCV format)."""
    pix = page.get_pixmap(matrix=fitz.Matrix(zoom, zoom))
    img = np.frombuffer(pix.samples, dtype=np.uint8).reshape(
        pix.height, pix.width, pix.n
    )
    if pix.n == 4:  # RGBA -> BGR
        img = cv2.cvtColor(img, cv2.COLOR_RGBA2BGR)
    else:  # RGB -> BGR
        img = cv2.cvtColor(img, cv2.COLOR_RGB2BGR)
    return img


def parse_color(value: str) -> tuple[int, int, int]:
    """Parse a colour given as '#RRGGBB', 'RRGGBB', or 'R,G,B' into BGR (OpenCV order)."""
    value = value.strip()
    if "," in value:
        parts = [int(p) for p in value.split(",")]
        if len(parts) != 3:
            raise argparse.ArgumentTypeError("Color as R,G,B needs exactly 3 values")
        r, g, b = parts
    else:
        hex_str = value.lstrip("#")
        if len(hex_str) != 6:
            raise argparse.ArgumentTypeError(
                "Color as hex needs 6 digits, e.g. '111060' or '#111060'"
            )
        r = int(hex_str[0:2], 16)
        g = int(hex_str[2:4], 16)
        b = int(hex_str[4:6], 16)
    for v in (r, g, b):
        if not 0 <= v <= 255:
            raise argparse.ArgumentTypeError("Color values must be 0-255")
    return (b, g, r)  # OpenCV uses BGR


def detect_border_boxes(
    img: np.ndarray,
    min_area_frac: float,
    border_color_bgr: tuple[int, int, int],
    hue_tolerance: int,
    sat_min: int,
    val_min: int,
    close_kernel: int,
) -> list[tuple[int, int, int, int]]:
    """Find bounding boxes of the card-border rectangles matching `border_color_bgr`."""
    h, w = img.shape[:2]
    page_area = h * w

    hsv = cv2.cvtColor(img, cv2.COLOR_BGR2HSV)
    target_hsv = cv2.cvtColor(
        np.uint8([[border_color_bgr]]), cv2.COLOR_BGR2HSV
    )[0, 0]
    target_hue = int(target_hsv[0])

    lower_sv = np.array([0, sat_min, val_min])
    upper_sv = np.array([179, 255, 255])

    lo = target_hue - hue_tolerance
    hi = target_hue + hue_tolerance
    if lo < 0 or hi > 179:
        # Hue wraps around (only relevant near red, hue 0/179) -- combine
        # two ranges instead of one.
        mask1 = cv2.inRange(
            hsv, np.array([max(0, lo) % 180, sat_min, val_min]), np.array([179, 255, 255])
        )
        mask2 = cv2.inRange(
            hsv, np.array([0, sat_min, val_min]), np.array([hi % 180, 255, 255])
        )
        mask = cv2.bitwise_or(mask1, mask2)
    else:
        mask = cv2.inRange(
            hsv, np.array([lo, sat_min, val_min]), np.array([hi, 255, 255])
        )

    # Close small gaps in the outline (anti-aliasing, thin strokes) so each
    # border forms one solid contour.
    kernel = cv2.getStructuringElement(
        cv2.MORPH_RECT, (close_kernel, close_kernel)
    )
    closed = cv2.morphologyEx(mask, cv2.MORPH_CLOSE, kernel, iterations=2)

    contours, _ = cv2.findContours(
        closed, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE
    )

    boxes = []
    for c in contours:
        area = cv2.contourArea(c)
        if area / page_area < min_area_frac:
            continue  # too small: hand icon, decorative triangle, noise
        x, y, cw, ch = cv2.boundingRect(c)
        boxes.append((x, y, cw, ch))
    return boxes


def cluster_1d(values: list[float], tol: float) -> list[list[float]]:
    """Group nearby scalar values into clusters (sorted input not required)."""
    values = sorted(values)
    clusters = [[values[0]]]
    for v in values[1:]:
        if v - clusters[-1][-1] <= tol:
            clusters[-1].append(v)
        else:
            clusters.append([v])
    return clusters


def assign_cluster(val: float, clusters: list[list[float]]) -> int:
    for i, c in enumerate(clusters):
        if min(c) - 1 <= val <= max(c) + 1:
            return i
    return -1


def boxes_to_card_crops(
    boxes: list[tuple[int, int, int, int]],
    page_w: int,
    page_h: int,
    grid_tol_frac: float,
) -> list[tuple[int, int, int, int]]:
    """
    Turn detected border boxes into non-overlapping full-card crop regions
    by snapping each card to a row/column grid and splitting at the
    midpoint between neighbouring cards (or the page edge).

    Returns a list of (x0, y0, x1, y1) crop rectangles, one per input box,
    in the same order as `boxes`.
    """
    cx = [x + cw / 2 for x, y, cw, ch in boxes]
    cy = [y + ch / 2 for x, y, cw, ch in boxes]

    col_clusters = cluster_1d(cx, page_w * grid_tol_frac)
    row_clusters = cluster_1d(cy, page_h * grid_tol_frac)

    def extent(clusters, get_center, get_lo, get_hi):
        lo = [
            min(get_lo(b) for b in boxes if assign_cluster(get_center(b), clusters) == i)
            for i in range(len(clusters))
        ]
        hi = [
            max(get_hi(b) for b in boxes if assign_cluster(get_center(b), clusters) == i)
            for i in range(len(clusters))
        ]
        return lo, hi

    col_left, col_right = extent(
        col_clusters,
        lambda b: b[0] + b[2] / 2,
        lambda b: b[0],
        lambda b: b[0] + b[2],
    )
    row_top, row_bot = extent(
        row_clusters,
        lambda b: b[1] + b[3] / 2,
        lambda b: b[1],
        lambda b: b[1] + b[3],
    )

    col_bounds = (
        [0]
        + [(col_right[i] + col_left[i + 1]) // 2 for i in range(len(col_clusters) - 1)]
        + [page_w]
    )
    row_bounds = (
        [0]
        + [(row_bot[i] + row_top[i + 1]) // 2 for i in range(len(row_clusters) - 1)]
        + [page_h]
    )

    crops = []
    for x, y, cw, ch in boxes:
        ci = assign_cluster(x + cw / 2, col_clusters)
        ri = assign_cluster(y + ch / 2, row_clusters)
        x0, x1 = int(col_bounds[ci]), int(col_bounds[ci + 1])
        y0, y1 = int(row_bounds[ri]), int(row_bounds[ri + 1])
        crops.append((x0, y0, x1, y1))
    return crops


def boxes_to_border_crops(
    boxes: list[tuple[int, int, int, int]],
    page_w: int,
    page_h: int,
    padding_frac: float,
) -> list[tuple[int, int, int, int]]:
    """
    Crop each card to just its detected border box (plus optional padding).
    padding_frac is a fraction of the box's own width/height: 0 crops right
    at the outer edge of the blue border; negative insets inside the border
    (excludes the border stroke); positive adds a small margin outside it.
    """
    crops = []
    for x, y, cw, ch in boxes:
        pad_x = int(cw * padding_frac)
        pad_y = int(ch * padding_frac)
        x0 = max(0, x - pad_x)
        y0 = max(0, y - pad_y)
        x1 = min(page_w, x + cw + pad_x)
        y1 = min(page_h, y + ch + pad_y)
        crops.append((x0, y0, x1, y1))
    return crops


def process_pdf(
    pdf_path: Path,
    output_dir: Path,
    start_page: int,
    end_page: int,
    zoom: float,
    min_area_frac: float,
    border_color_bgr: tuple[int, int, int],
    hue_tolerance: int,
    sat_min: int,
    val_min: int,
    close_kernel: int,
    grid_tol_frac: float,
    crop_mode: str,
    border_padding_frac: float,
    debug: bool,
):
    doc = fitz.open(pdf_path)
    start_index = start_page - 1
    end_index = min(end_page, len(doc))

    output_dir.mkdir(parents=True, exist_ok=True)
    if debug:
        debug_dir = output_dir / "debug"
        debug_dir.mkdir(parents=True, exist_ok=True)

    total_cards = 0

    for page_index in range(start_index, end_index):
        page_num = page_index + 1
        page = doc[page_index]
        img = render_page(page, zoom)

        boxes = detect_border_boxes(
            img, min_area_frac, border_color_bgr, hue_tolerance, sat_min, val_min, close_kernel
        )

        if not boxes:
            print(f"Page {page_num}: no card borders detected, skipping.")
            continue

        if crop_mode == "border":
            crops = boxes_to_border_crops(
                boxes, img.shape[1], img.shape[0], border_padding_frac
            )
        else:
            crops = boxes_to_card_crops(boxes, img.shape[1], img.shape[0], grid_tol_frac)

        # Order cards left-to-right, top-to-bottom for stable numbering.
        order = sorted(
            range(len(crops)), key=lambda i: (crops[i][1], crops[i][0])
        )

        if debug:
            dbg = img.copy()
            for x, y, cw, ch in boxes:
                cv2.rectangle(dbg, (x, y), (x + cw, y + ch), (0, 0, 255), 4)
            for x0, y0, x1, y1 in crops:
                cv2.rectangle(dbg, (x0, y0), (x1, y1), (0, 255, 0), 4)
            cv2.imwrite(str(debug_dir / f"page_{page_num}_debug.jpg"), dbg)

        for card_num, idx in enumerate(order, start=1):
            x0, y0, x1, y1 = crops[idx]
            crop = img[y0:y1, x0:x1]
            out_file = output_dir / f"page_{page_num}_card_{card_num}.jpg"
            cv2.imwrite(str(out_file), crop, [cv2.IMWRITE_JPEG_QUALITY, 95])
            print(f"Saved: {out_file}")
            total_cards += 1

    doc.close()
    print(f"\nDone. Extracted {total_cards} card(s).")


def main():
    parser = argparse.ArgumentParser(
        description="Extract individual cards from a PDF by detecting their blue borders."
    )
    parser.add_argument("pdf", type=Path, help="Path to the PDF file")
    parser.add_argument(
        "-o", "--output", type=Path, default=Path("extracted_cards"),
        help="Output directory (default: extracted_cards)",
    )
    parser.add_argument("--start", type=int, default=1, help="First page (1-based, default: 1)")
    parser.add_argument("--end", type=int, default=None, help="Last page (1-based, inclusive)")
    parser.add_argument(
        "--zoom", type=float, default=3.0,
        help="Render zoom factor / resolution multiplier (default: 3.0)",
    )
    parser.add_argument(
        "--border-color", type=str, default="111060",
        help="Border colour to detect, as hex ('111060' or '#111060') or "
             "'R,G,B' (default: '111060', a navy blue). Sample a border "
             "pixel from your PDF/image in any image editor to get the value.",
    )
    parser.add_argument(
        "--hue-tolerance", type=int, default=15,
        help="How far (in HSV hue units, 0-179 scale) a pixel's hue may "
             "stray from --border-color and still count as border colour "
             "(default: 15). Raise if borders are being missed; lower if "
             "other similarly-coloured content is getting picked up.",
    )
    parser.add_argument(
        "--sat-min", type=int, default=40,
        help="Minimum HSV saturation (0-255) for a pixel to count as border "
             "colour, filters out washed-out/grey pixels (default: 40).",
    )
    parser.add_argument(
        "--val-min", type=int, default=40,
        help="Minimum HSV value/brightness (0-255) for a pixel to count as "
             "border colour, filters out near-black pixels (default: 40).",
    )
    parser.add_argument(
        "--min-area-frac", type=float, default=0.02,
        help="Minimum contour area as a fraction of page area to count as a "
             "card border, filters out small icons/decorations (default: 0.02)",
    )
    parser.add_argument(
        "--close-kernel", type=int, default=9,
        help="Morphological closing kernel size, connects broken border "
             "strokes into one contour (default: 9).",
    )
    parser.add_argument(
        "--grid-tol-frac", type=float, default=0.15,
        help="Tolerance (as a fraction of page width/height) for clustering "
             "cards into grid rows/columns (default: 0.15).",
    )
    parser.add_argument(
        "--crop-mode", choices=["border", "full"], default="border",
        help="'border' (default): crop tightly to just inside/around the "
             "blue border, no title/label/yellow margin. 'full': crop the "
             "whole card cell (title above, label below, split at the "
             "midpoint to neighbouring cards).",
    )
    parser.add_argument(
        "--border-padding-frac", type=float, default=0.0,
        help="Only used with --crop-mode border. Fraction of the border "
             "box's own width/height to pad by: 0 (default) crops right at "
             "the border's outer edge; negative insets inside the border "
             "(e.g. -0.02 excludes the blue stroke itself); positive adds "
             "a small margin outside it.",
    )
    parser.add_argument(
        "--debug", action="store_true",
        help="Also save a debug image per page with detected borders (red) "
             "and final crop regions (green) drawn on it.",
    )

    args = parser.parse_args()

    if not args.pdf.exists():
        parser.error(f"PDF not found: {args.pdf}")
    if args.start < 1:
        parser.error("--start must be >= 1")

    doc = fitz.open(args.pdf)
    page_count = len(doc)
    doc.close()

    if args.start > page_count:
        parser.error(f"--start cannot be greater than the PDF page count ({page_count})")

    end_page = args.end or page_count
    if end_page < args.start:
        parser.error("--end must be greater than or equal to --start")
    if end_page > page_count:
        parser.error(f"--end cannot be greater than the PDF page count ({page_count})")

    try:
        border_color_bgr = parse_color(args.border_color)
    except argparse.ArgumentTypeError as e:
        parser.error(str(e))

    process_pdf(
        args.pdf,
        args.output,
        args.start,
        end_page,
        args.zoom,
        args.min_area_frac,
        border_color_bgr,
        args.hue_tolerance,
        args.sat_min,
        args.val_min,
        args.close_kernel,
        args.grid_tol_frac,
        args.crop_mode,
        args.border_padding_frac,
        args.debug,
    )


if __name__ == "__main__":
    main()
