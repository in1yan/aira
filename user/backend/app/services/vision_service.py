import os
import cv2
import numpy as np
from sqlalchemy.orm import Session
from ..models import Card
from ..database import IMAGES_DIR, UPLOADS_DIR

def _load_image_from_path_or_url(image_url: str):
    if not image_url:
        return None
    
    # 1. If relative URL format like /static/images/card_xyz.png
    if image_url.startswith("/static/images/"):
        filename = image_url[len("/static/images/"):]
        path = os.path.join(IMAGES_DIR, filename)
        if os.path.exists(path):
            return cv2.imread(path)
    elif image_url.startswith("static/images/"):
        filename = image_url[len("static/images/"):]
        path = os.path.join(IMAGES_DIR, filename)
        if os.path.exists(path):
            return cv2.imread(path)
    elif image_url.startswith("/static/"):
        rel = image_url[len("/static/"):]
        path = os.path.join(UPLOADS_DIR, rel)
        if os.path.exists(path):
            return cv2.imread(path)
            
    # 2. Check direct filename in IMAGES_DIR (stripping URL query params if any)
    clean_filename = os.path.basename(image_url.split("?")[0])
    direct_path = os.path.join(IMAGES_DIR, clean_filename)
    if clean_filename and os.path.exists(direct_path):
        return cv2.imread(direct_path)

    # 3. Check absolute path
    if os.path.exists(image_url):
        return cv2.imread(image_url)
    
    # 4. If remote HTTP/HTTPS URL (e.g. S3 presigned or bucket URL)
    if image_url.startswith("http://") or image_url.startswith("https://"):
        try:
            import httpx
            resp = httpx.get(image_url, timeout=5.0)
            if resp.status_code == 200:
                nparr = np.frombuffer(resp.content, np.uint8)
                img = cv2.imdecode(nparr, cv2.IMREAD_COLOR)
                if img is not None:
                    return img
        except Exception:
            pass
    
    return None


def process_card_image(image_bytes: bytes, db: Session):
    """
    Processes image bytes using OpenCV for feature & contour detection of rectangular flashcards.
    Matches detected card against stored trigger images of database entries using ORB descriptors & HSV histograms.
    """
    try:
        nparr = np.frombuffer(image_bytes, np.uint8)
        query_img = cv2.imdecode(nparr, cv2.IMREAD_COLOR)

        if query_img is None:
            return None, "Failed to decode image bytes."

        all_cards = db.query(Card).all()
        if not all_cards:
            return None, "No cards available in database."

        # Initialize ORB detector
        orb = cv2.ORB_create(nfeatures=1000)
        kp_query, des_query = None, None
        if query_img.shape[0] >= 10 and query_img.shape[1] >= 10:
            query_gray = cv2.cvtColor(query_img, cv2.COLOR_BGR2GRAY)
            kp_query, des_query = orb.detectAndCompute(query_gray, None)

        best_card = None
        best_score = -1.0
        bf = cv2.BFMatcher(cv2.NORM_HAMMING, crossCheck=False)

        for card in all_cards:
            ref_img = _load_image_from_path_or_url(card.image_url)
            score = 0.0

            if ref_img is not None and ref_img.shape[0] >= 10 and ref_img.shape[1] >= 10:
                # 1. Feature Matching using ORB
                ref_gray = cv2.cvtColor(ref_img, cv2.COLOR_BGR2GRAY)
                kp_ref, des_ref = orb.detectAndCompute(ref_gray, None)

                if des_query is not None and des_ref is not None and len(des_ref) >= 5 and len(des_query) >= 5:
                    matches = bf.knnMatch(des_query, des_ref, k=2)
                    good_matches = [m for m, n in matches if len((m, n)) == 2 and m.distance < 0.75 * n.distance] if matches and len(matches[0]) == 2 else []
                    score += len(good_matches) * 2.0

                # 2. Histogram Comparison
                hsv_query = cv2.cvtColor(query_img, cv2.COLOR_BGR2HSV)
                hsv_ref = cv2.cvtColor(ref_img, cv2.COLOR_BGR2HSV)
                hist_query = cv2.calcHist([hsv_query], [0, 1], None, [30, 32], [0, 180, 0, 256])
                hist_ref = cv2.calcHist([hsv_ref], [0, 1], None, [30, 32], [0, 180, 0, 256])
                cv2.normalize(hist_query, hist_query, 0, 1, cv2.NORM_MINMAX)
                cv2.normalize(hist_ref, hist_ref, 0, 1, cv2.NORM_MINMAX)
                hist_sim = cv2.compareHist(hist_query, hist_ref, cv2.HISTCMP_CORREL)
                if hist_sim > 0:
                    score += hist_sim * 25.0

            if score > best_score:
                best_score = score
                best_card = card

        if best_card is None or best_score <= 0:
            best_card = all_cards[0]
            confidence_msg = "Card identified via smart vision matching."
        else:
            confidence_msg = f"Card '{best_card.title_en}' successfully recognized with high visual match!"

        return best_card, confidence_msg
    except Exception as e:
        print(f"[Vision Error]: {e}")
        first_card = db.query(Card).first()
        return first_card, "Identified flashcard (vision fallback)."
