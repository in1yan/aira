#!/usr/bin/env python3
"""
Aira Storage Bucket Sync Script
Uploads flashcard images to AWS S3 storage bucket and updates them in the database with permanent public URLs.

Usage:
    python upload_images_to_s3.py
"""

import os
import sys
import mimetypes
import boto3
from dotenv import load_dotenv

# Path setup
ROOT_DIR = os.path.dirname(os.path.abspath(__file__))
load_dotenv(os.path.join(ROOT_DIR, ".env"))

# Import database models and storage service from backend
sys.path.insert(0, ROOT_DIR)
from backend.app.database import SessionLocal, IMAGES_DIR, engine, IS_SQLITE
from backend.app.models import Card, CardAttribute, Category
from backend.app.services.storage_service import upload_bytes_to_s3, get_public_url, get_s3_config, get_s3_client

def upload_and_update_database():
    config = get_s3_config()
    bucket = config["bucket"]
    region = config["region"]

    print("=" * 70)
    print("  AIRA FLASHCARDS - S3 STORAGE UPLOAD & DB UPDATE (PUBLIC URLS)")
    print("=" * 70)
    print(f"  Target S3 Bucket : {bucket}")
    print(f"  AWS Region       : {region}")
    print(f"  Images Directory : {IMAGES_DIR}")
    print(f"  Database Engine  : {'SQLite' if IS_SQLITE else 'Remote PostgreSQL'}")
    print("=" * 70)

    # Initialize S3 client
    s3 = get_s3_client()

    VALID_EXTS = {".png", ".jpg", ".jpeg", ".webp", ".svg", ".gif"}
    image_url_map = {}

    if os.path.exists(IMAGES_DIR):
        image_files = [
            f for f in os.listdir(IMAGES_DIR) 
            if os.path.isfile(os.path.join(IMAGES_DIR, f)) and os.path.splitext(f)[1].lower() in VALID_EXTS
        ]
        print(f"\n[1/3] Found {len(image_files)} image files in '{IMAGES_DIR}'. Uploading to S3 bucket '{bucket}'...")
        
        for idx, filename in enumerate(image_files, 1):
            file_path = os.path.join(IMAGES_DIR, filename)
            key = f"uploads/images/{filename}"
            content_type, _ = mimetypes.guess_type(file_path)
            content_type = content_type or "image/jpeg"

            try:
                with open(file_path, "rb") as f:
                    file_bytes = f.read()

                url, s3_key = upload_bytes_to_s3(
                    file_bytes=file_bytes,
                    key=key,
                    content_type=content_type,
                    bucket_name=bucket,
                    use_presigned=False
                )

                image_url_map[filename] = url
                print(f"  [{idx}/{len(image_files)}] Uploaded: {key}")
                print(f"      [public url] {url}")

            except Exception as e:
                print(f"  [{idx}/{len(image_files)}] Failed to upload {filename}: {e}")

    # Step 2: Update Database Records (Cards & Card Attributes)
    db = SessionLocal()
    try:
        print("\n[2/3] Updating Flashcards in database with permanent S3 public URLs...")
        cards = db.query(Card).all()
        updated_cards_count = 0

        for card in cards:
            if card.image_url:
                clean_name = os.path.basename(card.image_url.split("?")[0])
                if clean_name in image_url_map:
                    card.image_url = image_url_map[clean_name]
                    updated_cards_count += 1
                    print(f"  - Card #{card.id} ('{card.title_en}') -> image_url updated to: {card.image_url}")
                else:
                    card_file_path = os.path.join(IMAGES_DIR, clean_name)
                    if os.path.exists(card_file_path):
                        key = f"uploads/images/{clean_name}"
                        with open(card_file_path, "rb") as f:
                            url, _ = upload_bytes_to_s3(f.read(), key=key, bucket_name=bucket, use_presigned=False)
                        card.image_url = url
                        image_url_map[clean_name] = url
                        updated_cards_count += 1
                        print(f"  - Card #{card.id} ('{card.title_en}') -> uploaded and image_url updated: [public url] {url}")
                    elif "s3." in card.image_url or "amazonaws.com" in card.image_url:
                        correct_url = get_public_url(f"uploads/images/{clean_name}", bucket_name=bucket)
                        if card.image_url != correct_url:
                            card.image_url = correct_url
                            updated_cards_count += 1
                            print(f"  - Card #{card.id} ('{card.title_en}') -> normalized to endpoint URL: {card.image_url}")

        print(f"  Total cards updated: {updated_cards_count}/{len(cards)}")

        print("\n[3/3] Updating Card Attributes in database with permanent S3 public URLs...")
        attributes = db.query(CardAttribute).all()
        updated_attrs_count = 0

        for attr in attributes:
            if attr.image_url:
                clean_name = os.path.basename(attr.image_url.split("?")[0])
                if clean_name in image_url_map:
                    attr.image_url = image_url_map[clean_name]
                    updated_attrs_count += 1
                    print(f"  - Attribute #{attr.id} (Card #{attr.card_id}, key '{attr.key}') -> image_url updated to: {attr.image_url}")
                else:
                    attr_file_path = os.path.join(IMAGES_DIR, clean_name)
                    if os.path.exists(attr_file_path):
                        key = f"uploads/images/{clean_name}"
                        with open(attr_file_path, "rb") as f:
                            url, _ = upload_bytes_to_s3(f.read(), key=key, bucket_name=bucket, use_presigned=False)
                        attr.image_url = url
                        image_url_map[clean_name] = url
                        updated_attrs_count += 1
                        print(f"  - Attribute #{attr.id} (Card #{attr.card_id}, key '{attr.key}') -> uploaded and image_url updated: [public url] {url}")
                    elif "s3." in attr.image_url or "amazonaws.com" in attr.image_url:
                        correct_url = get_public_url(f"uploads/images/{clean_name}", bucket_name=bucket)
                        if attr.image_url != correct_url:
                            attr.image_url = correct_url
                            updated_attrs_count += 1
                            print(f"  - Attribute #{attr.id} (Card #{attr.card_id}, key '{attr.key}') -> normalized to endpoint URL: {attr.image_url}")

        print(f"  Total attributes updated: {updated_attrs_count}/{len(attributes)}")

        # Commit DB changes
        db.commit()
        print("\n" + "=" * 70)
        print("  DATABASE COMMITTED & SYNCHRONIZED WITH PUBLIC S3 URLS SUCCESSFULLY!")
        print("=" * 70)

    except Exception as e:
        db.rollback()
        print(f"\n[Error during DB update]: {e}")
    finally:
        db.close()

if __name__ == "__main__":
    upload_and_update_database()
