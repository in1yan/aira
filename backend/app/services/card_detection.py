from __future__ import annotations

from functools import lru_cache
from pathlib import Path
from typing import Any

import cv2
import numpy as np

from app.core.config import settings

IMAGE_EXTENSIONS = {".jpg", ".jpeg", ".png", ".webp", ".bmp"}


class CardDetectionError(ValueError):
    """Raised when an uploaded image cannot be decoded or analyzed."""


class CardRecognizer:
    """Recognize cards using ORB features and RANSAC homography matching."""

    def __init__(self, template_dir: Path, nfeatures: int = 3000) -> None:
        self.template_dir = template_dir
        self.orb = cv2.ORB_create(
            nfeatures=nfeatures,
            scaleFactor=1.2,
            nlevels=8,
            fastThreshold=10,
        )
        self.matcher = cv2.BFMatcher(cv2.NORM_HAMMING)
        self.templates: dict[str, dict[str, Any]] = {}
        self._load_templates()

    def _load_templates(self) -> None:
        if not self.template_dir.exists():
            raise FileNotFoundError(f"Card template directory not found: {self.template_dir}")
        if not self.template_dir.is_dir():
            raise NotADirectoryError(f"Card template path is not a directory: {self.template_dir}")

        for image_path in sorted(self.template_dir.iterdir()):
            if not image_path.is_file() or image_path.suffix.lower() not in IMAGE_EXTENSIONS:
                continue

            image = cv2.imread(str(image_path), cv2.IMREAD_COLOR)
            if image is None:
                continue

            keypoints, descriptors = self._describe(image)
            if descriptors is None:
                continue

            self.templates[image_path.stem] = {
                "keypoints": keypoints,
                "descriptors": descriptors,
            }

    def _describe(self, image: np.ndarray) -> tuple[list[cv2.KeyPoint], np.ndarray | None]:
        gray = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)
        keypoints, descriptors = self.orb.detectAndCompute(gray, None)
        return keypoints or [], descriptors

    def _match_template(
        self,
        query_keypoints: list[cv2.KeyPoint],
        query_descriptors: np.ndarray,
        template: dict[str, Any],
    ) -> dict[str, float | int]:
        try:
            matches = self.matcher.knnMatch(query_descriptors, template["descriptors"], k=2)
        except cv2.error:
            return {"matches": 0, "inliers": 0, "ratio": 0.0}

        good_matches = [
            first
            for pair in matches
            if len(pair) == 2
            for first, second in [pair]
            if first.distance < 0.70 * second.distance
        ]

        if len(good_matches) < 4:
            return {"matches": len(good_matches), "inliers": 0, "ratio": 0.0}

        query_points = np.float32(
            [query_keypoints[match.queryIdx].pt for match in good_matches]
        )
        template_points = np.float32(
            [
                template["keypoints"][match.trainIdx].pt
                for match in good_matches
            ]
        )

        try:
            _, mask = cv2.findHomography(
                template_points,
                query_points,
                cv2.RANSAC,
                5.0,
            )
        except cv2.error:
            return {"matches": len(good_matches), "inliers": 0, "ratio": 0.0}

        if mask is None:
            return {"matches": len(good_matches), "inliers": 0, "ratio": 0.0}

        inliers = int(mask.ravel().sum())
        return {
            "matches": len(good_matches),
            "inliers": inliers,
            "ratio": inliers / len(good_matches),
        }

    def recognize(
        self,
        image_bytes: bytes,
        min_inliers: int = 12,
        min_ratio: float = 0.35,
    ) -> tuple[str | None, list[dict[str, float | int | str]]]:
        encoded = np.frombuffer(image_bytes, dtype=np.uint8)
        image = cv2.imdecode(encoded, cv2.IMREAD_COLOR)
        if image is None:
            raise CardDetectionError("The uploaded file is not a valid image")

        query_keypoints, query_descriptors = self._describe(image)
        if query_descriptors is None:
            return None, []

        scores: list[dict[str, float | int | str]] = []
        for card_name, template in self.templates.items():
            result = self._match_template(query_keypoints, query_descriptors, template)
            scores.append({"card": card_name, **result})

        scores.sort(
            key=lambda result: (
                int(result["inliers"]),
                float(result["ratio"]),
                int(result["matches"]),
            ),
            reverse=True,
        )

        if not scores:
            return None, []

        best = scores[0]
        if (
            int(best["inliers"]) < min_inliers
            or float(best["ratio"]) < min_ratio
        ):
            return None, scores

        return str(best["card"]), scores


@lru_cache(maxsize=1)
def get_card_recognizer() -> CardRecognizer:
    return CardRecognizer(
        template_dir=Path(settings.CARD_TEMPLATE_DIR),
        nfeatures=settings.CARD_ORB_FEATURES,
    )
