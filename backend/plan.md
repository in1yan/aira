# Card Image Detection Plan

## Goal

Add an image-detection service and API route that recognizes an uploaded card image by comparing it with template images in `backend/card_db`. The uploaded image must be processed in memory and must never be written to local disk.

## Implementation

1. **Template discovery and indexing**
   - Use `backend/card_db` as the default template directory.
   - Load supported image files (`.jpg`, `.jpeg`, `.png`, `.webp`, `.bmp`) from the directory.
   - Decode each template with OpenCV and precompute grayscale ORB keypoints and descriptors once when the service is initialized.
   - Use the template filename stem as the detected card identifier.
   - Fail clearly if the template directory is missing; skip unreadable templates and templates without descriptors.

2. **Matching service**
   - Add a reusable service based on `scripts/orb_classifier.py`.
   - Decode the request bytes with `numpy.frombuffer` and `cv2.imdecode`; do not create a temporary file.
   - Extract ORB descriptors from the uploaded image.
   - Compare the query with every template using BFMatcher with Hamming distance and Lowe's ratio test.
   - Use RANSAC homography to calculate inliers and the inlier ratio.
   - Sort candidates by inliers, ratio, and good matches.
   - Return the best card only when minimum inlier and ratio thresholds are met; otherwise return an unknown result with candidate scores.

3. **API route**
   - Implement `POST /api/v1/detect` in `app/api/v1/endpoints/detect.py`.
   - Accept `UploadFile` through multipart form upload.
   - Validate that the upload is an image and enforce a configured maximum byte size before decoding.
   - Read bytes into memory, call the matching service, and return JSON containing the detected card, confidence metrics, and ranked candidates.
   - Return clear `400` responses for invalid or undecodable images.
   - Do not save the upload, generate a visualization, or write any upload-related artifact locally.

4. **Application wiring and configuration**
   - Register the detection router in `app/api/v1/api.py`.
   - Add any required OpenCV dependency to `pyproject.toml` and lock metadata through the project package manager.
   - Keep template loading configurable through an environment setting while defaulting to `card_db`.
   - Keep thresholds and ORB feature count configurable with safe defaults matching the reference classifier.

5. **Validation**
   - Compile the changed Python files.
   - Verify the route appears in OpenAPI as a multipart upload endpoint.
   - Test invalid uploads and undecodable bytes without creating files.
   - Test matching with representative template/query images when `card_db` contains templates.
   - Confirm no uploaded image is present in the repository or local upload directory after a request.
