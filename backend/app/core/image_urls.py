from __future__ import annotations

from pathlib import PurePosixPath


CARD_IMAGE_URL_PREFIX = "/static/card-images"


def to_public_image_url(value: str | None) -> str | None:
    """Return a browser-accessible URL for a stored card image path.

    New records store the public URL directly. The legacy path conversion keeps
    records created before static file support displayable as well.
    """
    if not value:
        return value

    normalized = value.replace("\\", "/")
    if normalized.startswith(("http://", "https://", CARD_IMAGE_URL_PREFIX + "/")):
        return normalized

    marker = "/images/"
    if marker in normalized:
        filename = normalized.split(marker, 1)[1]
        if filename and "/" not in filename:
            return f"{CARD_IMAGE_URL_PREFIX}/{PurePosixPath(filename).name}"

    return normalized
