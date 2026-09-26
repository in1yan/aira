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
    endpoint_url = os.getenv("AWS_ENDPOINT_URL") or os.getenv("AWS_S3_ENDPOINT_URL") or os.getenv("AWS_ENDPOINT_URL_S3")
    custom_domain = os.getenv("AWS_S3_CUSTOM_DOMAIN") or os.getenv("AWS_PUBLIC_URL_BASE")
    
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
        "custom_domain": custom_domain,
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

def get_public_url(key: str, bucket_name: Optional[str] = None) -> str:
    """
    Builds a permanent, public URL for an S3 object (no signature/expiration).
    """
    config = get_s3_config()
    bucket = bucket_name or config["bucket"]
    region = config["region"]
    clean_key = key.lstrip("/")

    if config["custom_domain"]:
        return f"{config['custom_domain'].rstrip('/')}/{clean_key}"
    elif config["endpoint_url"]:
        # Custom S3-compatible endpoints (MinIO, Supabase, Cloudflare R2, etc.)
        return f"{config['endpoint_url'].rstrip('/')}/{bucket}/{clean_key}"
    else:
        # Standard AWS S3 public URL format
        if region == "us-east-1":
            return f"https://{bucket}.s3.amazonaws.com/{clean_key}"
        return f"https://{bucket}.s3.{region}.amazonaws.com/{clean_key}"

def upload_bytes_to_s3(
    file_bytes: bytes,
    key: str,
    content_type: Optional[str] = None,
    bucket_name: Optional[str] = None,
    use_presigned: bool = False,
    expires_in: Optional[int] = None
) -> Tuple[str, str]:
    """
    Uploads raw file bytes to the specified S3 bucket and key.
    Returns a direct, permanent public URL (or presigned URL if explicitly requested).

    Returns:
        (image_url, s3_key)
    """
    config = get_s3_config()
    bucket = bucket_name or config["bucket"]

    if not content_type:
        guessed, _ = mimetypes.guess_type(key)
        content_type = guessed or "application/octet-stream"

    s3 = get_s3_client()
    
    # Upload object to S3 bucket
    put_kwargs = {
        "Bucket": bucket,
        "Key": key,
        "Body": file_bytes,
        "ContentType": content_type
    }
    
    # If using custom endpoint (Neon, R2, MinIO), upload without ACL (as ACLs are often not implemented)
    if config.get("endpoint_url"):
        s3.put_object(**put_kwargs)
    else:
        try:
            s3.put_object(**put_kwargs, ACL="public-read")
        except Exception:
            s3.put_object(**put_kwargs)

    if use_presigned:
        expiry = expires_in if expires_in is not None else config["presigned_expiry"]
        url = s3.generate_presigned_url(
            "get_object",
            Params={"Bucket": bucket, "Key": key},
            ExpiresIn=expiry
        )
    else:
        url = get_public_url(key=key, bucket_name=bucket)
    
    return url, key

def upload_file_path_to_s3(
    file_path: str,
    key_prefix: str = "uploads/images",
    bucket_name: Optional[str] = None,
    custom_key: Optional[str] = None,
    use_presigned: bool = False,
    expires_in: Optional[int] = None
) -> Tuple[str, str]:
    """
    Uploads a local file from disk to S3 bucket and returns its permanent public URL.
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
        use_presigned=use_presigned,
        expires_in=expires_in
    )

def generate_presigned_view_url(key: str, bucket_name: Optional[str] = None, expires_in: Optional[int] = None) -> str:
    """
    Generates a presigned URL for an existing S3 key if needed.
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
