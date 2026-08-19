import argparse
from pathlib import Path

import cv2
import numpy as np


TEMPLATE_DIR = Path("templates")
DEFAULT_INDEX = Path("orb_index.npz")

IMAGE_EXTENSIONS = {
  ".jpg",
  ".jpeg",
  ".png",
  ".webp",
  ".bmp",
}


class AnimalRecognizer:

  def __init__(
    self,
    template_dir: Path = TEMPLATE_DIR,
    nfeatures: int = 3000,
    index_path: Path | None = None,
  ):
    self.template_dir = template_dir

    self.orb = cv2.ORB_create(
      nfeatures=nfeatures,
      scaleFactor=1.2,
      nlevels=8,
      fastThreshold=10,
    )

    self.matcher = cv2.BFMatcher(
      cv2.NORM_HAMMING
    )

    self.templates = {}

    if index_path is not None:
      self.load_index(index_path)
    else:
      self.load_templates()

  # ==========================================================
  # LOAD TEMPLATES
  # ==========================================================

  def load_templates(self):

    if not self.template_dir.exists():
      raise FileNotFoundError(
        f"Template directory not found: "
        f"{self.template_dir}"
      )

    print("Loading templates...\n")

    for image_path in sorted(
      self.template_dir.iterdir()
    ):

      if (
        not image_path.is_file()
        or image_path.suffix.lower()
        not in IMAGE_EXTENSIONS
      ):
        continue

      image = cv2.imread(
        str(image_path)
      )

      if image is None:
        print(
          f"[!] Could not read: "
          f"{image_path}"
        )
        continue

      gray = cv2.cvtColor(
        image,
        cv2.COLOR_BGR2GRAY
      )

      keypoints, descriptors = (
        self.orb.detectAndCompute(
          gray,
          None
        )
      )

      if descriptors is None:
        print(
          f"[!] No features found: "
          f"{image_path.name}"
        )
        continue

      animal = image_path.stem

      self.templates[animal] = {
        "image": image,
        "keypoints": keypoints,
        "descriptors": descriptors,
      }

      print(
        f"{animal:<25} "
        f"{len(keypoints)} features"
      )

    print(
      f"\nLoaded "
      f"{len(self.templates)} templates.\n"
    )

  # ==========================================================
  # SAVE INDEX
  # ==========================================================

  def save_index(self, index_path: Path):

    if not self.templates:
      raise RuntimeError(
        "No templates loaded. "
        "Cannot create index."
      )

    arrays = {}

    # Store the number of templates
    arrays["template_count"] = np.array(
      [len(self.templates)],
      dtype=np.int32,
    )

    for index, (name, template) in enumerate(
      self.templates.items()
    ):

      keypoints = template["keypoints"]
      descriptors = template["descriptors"]

      # Store template name
      arrays[f"name_{index}"] = np.array(
        name
      )

      # Store keypoint coordinates
      points = np.array(
        [kp.pt for kp in keypoints],
        dtype=np.float32,
      )

      arrays[f"keypoints_{index}"] = points

      # Store ORB descriptors
      arrays[f"descriptors_{index}"] = (
        descriptors
      )

    np.savez_compressed(
      index_path,
      **arrays,
    )

    print(
      f"\nSaved descriptor index to:"
      f"\n  {index_path}"
    )

    print(
      f"Templates saved: "
      f"{len(self.templates)}"
    )

  # ==========================================================
  # LOAD INDEX
  # ==========================================================

  def load_index(self, index_path: Path):

    if not index_path.exists():
      raise FileNotFoundError(
        f"Index file not found: "
        f"{index_path}"
      )

    print(
      f"Loading descriptor index:"
      f"\n  {index_path}\n"
    )

    data = np.load(
      index_path,
      allow_pickle=False,
    )

    template_count = int(
      data["template_count"][0]
    )

    for index in range(template_count):

      name = str(
        data[f"name_{index}"]
      )

      points = data[
        f"keypoints_{index}"
      ]

      descriptors = data[
        f"descriptors_{index}"
      ]

      # Reconstruct OpenCV KeyPoint objects
      keypoints = [
        cv2.KeyPoint(
          float(x),
          float(y),
          1.0,
        )
        for x, y in points
      ]

      self.templates[name] = {
        "keypoints": keypoints,
        "descriptors": descriptors,
      }

      print(
        f"{name:<25} "
        f"{len(keypoints)} features"
      )

    print(
      f"\nLoaded "
      f"{len(self.templates)} templates.\n"
    )

  # ==========================================================
  # MATCH TEMPLATE
  # ==========================================================

  def match_template(
    self,
    query_keypoints,
    query_descriptors,
    template,
  ):

    matches = self.matcher.knnMatch(
      query_descriptors,
      template["descriptors"],
      k=2,
    )

    good_matches = []

    for pair in matches:

      if len(pair) != 2:
        continue

      first, second = pair

      if first.distance < 0.70 * second.distance:
        good_matches.append(first)

    if len(good_matches) < 4:
      return {
        "matches": len(good_matches),
        "inliers": 0,
        "ratio": 0.0,
      }

    query_points = np.float32([
      query_keypoints[
        match.queryIdx
      ].pt
      for match in good_matches
    ])

    template_points = np.float32([
      template["keypoints"][
        match.trainIdx
      ].pt
      for match in good_matches
    ])

    try:

      homography, mask = cv2.findHomography(
        template_points,
        query_points,
        cv2.RANSAC,
        5.0,
      )

    except cv2.error:

      return {
        "matches": len(good_matches),
        "inliers": 0,
        "ratio": 0.0,
      }

    if mask is None:
      return {
        "matches": len(good_matches),
        "inliers": 0,
        "ratio": 0.0,
      }

    inliers = int(
      mask.ravel().sum()
    )

    inlier_ratio = (
      inliers / len(good_matches)
    )

    return {
      "matches": len(good_matches),
      "inliers": inliers,
      "ratio": inlier_ratio,
    }

  # ==========================================================
  # RECOGNIZE
  # ==========================================================

  def recognize(
    self,
    image_path: Path,
    min_inliers: int = 12,
    min_ratio: float = 0.35,
  ):

    image = cv2.imread(
      str(image_path)
    )

    if image is None:
      raise ValueError(
        f"Could not read image: "
        f"{image_path}"
      )

    gray = cv2.cvtColor(
      image,
      cv2.COLOR_BGR2GRAY
    )

    query_keypoints, query_descriptors = (
      self.orb.detectAndCompute(
        gray,
        None
      )
    )

    if query_descriptors is None:
      return None, []

    scores = []

    for animal, template in (
      self.templates.items()
    ):

      result = self.match_template(
        query_keypoints,
        query_descriptors,
        template,
      )

      scores.append({
        "animal": animal,
        "matches": result["matches"],
        "inliers": result["inliers"],
        "ratio": result["ratio"],
      })

    scores.sort(
      key=lambda result: (
        result["inliers"],
        result["ratio"],
        result["matches"],
      ),
      reverse=True,
    )

    if not scores:
      return None, []

    best = scores[0]

    if (
      best["inliers"] < min_inliers
      or best["ratio"] < min_ratio
    ):
      return None, scores

    return best["animal"], scores


# ============================================================
# CLI
# ============================================================

def main():

  parser = argparse.ArgumentParser(
    description=(
      "ORB card recognition using "
      "RANSAC + saved descriptors."
    )
  )

  # Image is optional because --save-index
  # doesn't require a query image.
  parser.add_argument(
    "image",
    type=Path,
    nargs="?",
    help="Image containing the card",
  )

  parser.add_argument(
    "--templates",
    type=Path,
    default=TEMPLATE_DIR,
    help=(
      "Directory containing card templates "
      "(default: templates)"
    ),
  )

  parser.add_argument(
    "--save-index",
    type=Path,
    metavar="FILE",
    help=(
      "Extract features from templates "
      "and save them to FILE"
    ),
  )

  parser.add_argument(
    "--load-index",
    type=Path,
    metavar="FILE",
    help=(
      "Load previously saved feature index"
    ),
  )

  parser.add_argument(
    "--min-inliers",
    type=int,
    default=12,
    help=(
      "Minimum RANSAC inliers "
      "(default: 12)"
    ),
  )

  parser.add_argument(
    "--min-ratio",
    type=float,
    default=0.35,
    help=(
      "Minimum inlier ratio "
      "(default: 0.35)"
    ),
  )

  parser.add_argument(
    "--features",
    type=int,
    default=3000,
    help=(
      "Number of ORB features "
      "(default: 3000)"
    ),
  )

  args = parser.parse_args()

  # ==========================================================
  # SAVE INDEX MODE
  # ==========================================================

  if args.save_index:

    print()
    print("=" * 60)
    print("BUILDING ORB DESCRIPTOR INDEX")
    print("=" * 60)
    print()

    recognizer = AnimalRecognizer(
      template_dir=args.templates,
      nfeatures=args.features,
    )

    recognizer.save_index(
      args.save_index
    )

    return

  # ==========================================================
  # RECOGNITION MODE
  # ==========================================================

  if args.image is None:
    parser.error(
      "An image is required unless "
      "--save-index is used."
    )

  if not args.image.exists():
    parser.error(
      f"Image not found: {args.image}"
    )

  # ----------------------------------------------------------
  # Load from saved index
  # ----------------------------------------------------------

  if args.load_index:

    recognizer = AnimalRecognizer(
      nfeatures=args.features,
      index_path=args.load_index,
    )

  # ----------------------------------------------------------
  # Load directly from templates
  # ----------------------------------------------------------

  else:

    recognizer = AnimalRecognizer(
      template_dir=args.templates,
      nfeatures=args.features,
    )

  print()
  print("=" * 60)
  print("CARD RECOGNITION")
  print("=" * 60)
  print()

  animal, scores = recognizer.recognize(
    args.image,
    min_inliers=args.min_inliers,
    min_ratio=args.min_ratio,
  )

  print("MATCH RESULTS")
  print("=" * 60)

  print(
    f"{'Card':<25}"
    f"{'Matches':>10}"
    f"{'Inliers':>10}"
    f"{'Ratio':>10}"
  )

  print("-" * 60)

  for result in scores:

    print(
      f"{result['animal']:<25}"
      f"{result['matches']:>10}"
      f"{result['inliers']:>10}"
      f"{result['ratio']:>9.2f}"
    )

  print("=" * 60)

  print()

  if animal is None:

    print("RESULT: UNKNOWN")
    print(
      "No reliable card match was found."
    )

  else:

    best = scores[0]

    print(
      f"RESULT: {animal}"
    )

    print(
      f"Good matches : "
      f"{best['matches']}"
    )

    print(
      f"RANSAC inliers: "
      f"{best['inliers']}"
    )

    print(
      f"Inlier ratio : "
      f"{best['ratio']:.2%}"
    )


if __name__ == "__main__":
  main()