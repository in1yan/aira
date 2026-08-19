import argparse
from pathlib import Path

import cv2
import numpy as np


TEMPLATE_DIR = Path("templates")

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
    template_dir: Path,
    nfeatures: int = 3000,
  ):
    self.template_dir = template_dir

    # ORB feature detector
    self.orb = cv2.ORB_create(
      nfeatures=nfeatures,
      scaleFactor=1.2,
      nlevels=8,
      fastThreshold=10,
    )

    # BFMatcher for ORB's binary descriptors
    self.matcher = cv2.BFMatcher(
      cv2.NORM_HAMMING
    )

    self.templates = {}

    self.load_templates()

  # ----------------------------------------------------------
  # Load templates
  # ----------------------------------------------------------

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
        f"{animal:<20} "
        f"{len(keypoints)} features"
      )

    print(
      f"\nLoaded "
      f"{len(self.templates)} templates.\n"
    )

  # ----------------------------------------------------------
  # Match query image against one template
  # ----------------------------------------------------------

  def match_template(
    self,
    query_keypoints,
    query_descriptors,
    template,
  ):

    # KNN matching
    matches = self.matcher.knnMatch(
      query_descriptors,
      template["descriptors"],
      k=2,
    )

    # --------------------------------------------------------
    # Lowe's ratio test
    # --------------------------------------------------------

    good_matches = []

    for pair in matches:

      if len(pair) != 2:
        continue

      first, second = pair

      if first.distance < 0.70 * second.distance:
        good_matches.append(first)

    # Homography requires at least 4 points
    if len(good_matches) < 4:
      return {
        "matches": len(good_matches),
        "inliers": 0,
        "ratio": 0.0,
      }

    # --------------------------------------------------------
    # Get coordinates of matched points
    # --------------------------------------------------------

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

    # --------------------------------------------------------
    # RANSAC homography
    # --------------------------------------------------------

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

    # Number of geometrically consistent matches
    inliers = int(
      mask.ravel().sum()
    )

    # Percentage of good matches that are
    # geometrically consistent
    inlier_ratio = (
      inliers / len(good_matches)
    )

    return {
      "matches": len(good_matches),
      "inliers": inliers,
      "ratio": inlier_ratio,
    }

  # ----------------------------------------------------------
  # Recognize image
  # ----------------------------------------------------------

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

    # --------------------------------------------------------
    # Compare against every template
    # --------------------------------------------------------

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

    # --------------------------------------------------------
    # Sort by geometric consistency
    # --------------------------------------------------------

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

    # --------------------------------------------------------
    # Reject weak matches
    # --------------------------------------------------------

    if (
      best["inliers"] < min_inliers
      or best["ratio"] < min_ratio
    ):
      return None, scores

    return best["animal"], scores

  # ----------------------------------------------------------
  # Draw matching result
  # ----------------------------------------------------------

  def save_match_visualization(
    self,
    image_path: Path,
    animal: str,
    output_path: Path,
  ):

    if animal not in self.templates:
      return

    query = cv2.imread(
      str(image_path)
    )

    template = self.templates[animal]["image"]

    query_gray = cv2.cvtColor(
      query,
      cv2.COLOR_BGR2GRAY
    )

    template_gray = cv2.cvtColor(
      template,
      cv2.COLOR_BGR2GRAY
    )

    query_kp, query_desc = (
      self.orb.detectAndCompute(
        query_gray,
        None
      )
    )

    template_kp, template_desc = (
      self.orb.detectAndCompute(
        template_gray,
        None
      )
    )

    matches = self.matcher.knnMatch(
      query_desc,
      template_desc,
      k=2,
    )

    good_matches = []

    for pair in matches:

      if len(pair) != 2:
        continue

      first, second = pair

      if first.distance < 0.70 * second.distance:
        good_matches.append(first)

    # Draw the best matches
    visualization = cv2.drawMatches(
      query,
      query_kp,
      template,
      template_kp,
      good_matches[:50],
      None,
      flags=cv2.DrawMatchesFlags_NOT_DRAW_SINGLE_POINTS,
    )

    cv2.imwrite(
      str(output_path),
      visualization,
    )


def main():

  parser = argparse.ArgumentParser(
    description=(
      "Recognize a card using "
      "ORB feature matching + RANSAC."
    )
  )

  parser.add_argument(
    "image",
    type=Path,
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
    "--min-inliers",
    type=int,
    default=12,
    help=(
      "Minimum number of RANSAC inliers "
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

  parser.add_argument(
    "--visualize",
    action="store_true",
    help=(
      "Save visualization of matched features"
    ),
  )

  parser.add_argument(
    "--output",
    type=Path,
    default=Path("orb_matches.jpg"),
    help=(
      "Visualization output path "
      "(default: orb_matches.jpg)"
    ),
  )

  args = parser.parse_args()

  # ----------------------------------------------------------
  # Validate input
  # ----------------------------------------------------------

  if not args.image.exists():
    parser.error(
      f"Image not found: {args.image}"
    )

  # ----------------------------------------------------------
  # Header
  # ----------------------------------------------------------

  print()
  print("=" * 60)
  print("             CARD RECOGNITION")
  print("=" * 60)
  print()

  print(f"Input     : {args.image}")
  print(f"Templates : {args.templates}")
  print(f"Features  : {args.features}")
  print(f"Min inliers : {args.min_inliers}")
  print(f"Min ratio   : {args.min_ratio}")
  print()

  # ----------------------------------------------------------
  # Initialize recognizer
  # ----------------------------------------------------------

  recognizer = AnimalRecognizer(
    template_dir=args.templates,
    nfeatures=args.features,
  )

  # ----------------------------------------------------------
  # Recognize
  # ----------------------------------------------------------

  animal, scores = recognizer.recognize(
    args.image,
    min_inliers=args.min_inliers,
    min_ratio=args.min_ratio,
  )

  # ----------------------------------------------------------
  # Print results
  # ----------------------------------------------------------

  print()
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

  # ----------------------------------------------------------
  # Final result
  # ----------------------------------------------------------

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
      f"Good matches : {best['matches']}"
    )

    print(
      f"RANSAC inliers: {best['inliers']}"
    )

    print(
      f"Inlier ratio : {best['ratio']:.2%}"
    )

  # ----------------------------------------------------------
  # Optional visualization
  # ----------------------------------------------------------

  if (
    args.visualize
    and animal is not None
  ):

    recognizer.save_match_visualization(
      args.image,
      animal,
      args.output,
    )

    print()
    print(
      f"Visualization saved to: "
      f"{args.output}"
    )

  print()


if __name__ == "__main__":
  main()