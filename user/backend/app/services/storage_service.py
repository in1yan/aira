import os
import mimetypes
import boto3
from botocore.config import Config
from botocore.exceptions import ClientError, NoCredentialsError
from typing import Optional, Tuple, Dict, Any

# Ensure environment variables are loaded
try:
    from dotenv import load_dotenv
    _cur_dir = os.path.dirname(os.path.abspath(__file__))
    _root_dir = os.path.dirname(os.path.dirname(os.path.dirname(_cur_dir)))
    load_dotenv(os.path.join(_root_dir, ".env"))
    load_dotenv()
except Exception:
    pass

def get_s3_config() -> Dict[str, Any]:
    """
    Retrieve S3 and cloud storage configuration parameters from environment variables.
    """
    region = os.getenv("AWS_REGION", "us-east-1")
    bucket = os.getenv("AWS_S3_BUCKET") or os.getenv("S3_BUCKET") or os.getenv("AWS_BUCKET_NAME") or "assets"
    access_key = os.getenv("AWS_ACCESS_KEY_ID")
    secret_key = os.getenv("AWS_SECRET_ACCESS_KEY")
    endpoint_url = os.getenv("AWS_ENDPOINT_URL") or os.getenv("AWS_S3_ENDPOINT_URL")
    
    try:
        presigned_expiry = int(os.getenv("AWS_S3_PRESIGNED_EXPIRY", "3600"))
    except (ValueError, TypeError):
        presigned_expiry = 3600

    return {
        "region": region,
        "bucket": bucket,
        "access_key": access_key,
        "secret_key": secret_key,
        "endpoint_url": endpoint_url,
        "presigned_expiry": presigned_expiry,
    }

def get_s3_client():
    """
    Initializes and returns a boto3 S3 client using environment configuration.
    """
    config = get_s3_config()
    client_kwargs = {
        "service_name": "s3",
        "region_name": config["region"],
        "config": Config(signature_version="s3v4")
    }

    if config["access_key"] and config["secret_key"]:
        client_kwargs["aws_access_key_id"] = config["access_key"]
        client_kwargs["aws_secret_access_key"] = config["secret_key"]

    if config["endpoint_url"]:
        client_kwargs["endpoint_url"] = config["endpoint_url"]

    return boto3.client(**client_kwargs)

def upload_bytes_to_s3(
    file_bytes: bytes,
    key: str,
    content_type: Optional[str] = None,
    bucket_name: Optional[str] = None,
    expires_in: Optional[int] = None
) -> Tuple[str, str]:
    """
    Uploads raw file bytes to the specified S3 bucket and key.
    Generates and returns a presigned GET URL for viewing the asset.

    Returns:
        (view_url, s3_key)
    """
    config = get_s3_config()
    bucket = bucket_name or config["bucket"]
    expiry = expires_in if expires_in is not None else config["presigned_expiry"]

    if not content_type:
        guessed, _ = mimetypes.guess_type(key)
        content_type = guessed or "application/octet-stream"

    s3 = get_s3_client()
    
    # Upload object to S3 bucket
    s3.put_object(
        Bucket=bucket,
        Key=key,
        Body=file_bytes,
        ContentType=content_type
    )

    # Generate presigned view URL
    url = s3.generate_presigned_url(
        "get_object",
        Params={"Bucket": bucket, "Key": key},
        ExpiresIn=expiry
    )
    
    return url, key

def upload_file_path_to_s3(
    file_path: str,
    key_prefix: str = "uploads/images",
    bucket_name: Optional[str] = None,
    custom_key: Optional[str] = None,
    expires_in: Optional[int] = None
) -> Tuple[str, str]:
    """
    Uploads a local file from disk to S3 bucket and returns its presigned view URL.
    """
    if not os.path.exists(file_path):
        raise FileNotFoundError(f"Local file not found: {file_path}")

    filename = os.path.basename(file_path)
    key = custom_key or f"{key_prefix.rstrip('/')}/{filename}"
    content_type, _ = mimetypes.guess_type(file_path)

    with open(file_path, "rb") as f:
        file_bytes = f.read()

    return upload_bytes_to_s3(
        file_bytes=file_bytes,
        key=key,
        content_type=content_type or "image/jpeg",
        bucket_name=bucket_name,
        expires_in=expires_in
    )

def generate_presigned_view_url(key: str, bucket_name: Optional[str] = None, expires_in: Optional[int] = None) -> str:
    """
    Generates a presigned URL for an existing S3 key.
    """
    config = get_s3_config()
    bucket = bucket_name or config["bucket"]
    expiry = expires_in if expires_in is not None else config["presigned_expiry"]
    s3 = get_s3_client()

    return s3.generate_presigned_url(
        "get_object",
        Params={"Bucket": bucket, "Key": key},
        ExpiresIn=expiry
    )
