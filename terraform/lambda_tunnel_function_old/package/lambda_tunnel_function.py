import os
import json
import requests
import logging

logger = logging.getLogger()
logger.setLevel(logging.INFO)

def handler(event, context):
    logger.info(f"Event received: {json.dumps(event)}")
    
    urls = [
        os.environ.get('PRIMARY_BACKEND_URL'),
        os.environ.get('SECONDARY_BACKEND_URL'),
        os.environ.get('TERTIARY_BACKEND_URL')
    ]
    urls = [url for url in urls if url]  # Filter out None/empty values
    
    auth_token = os.environ.get('AUTH_TOKEN')
    headers = {"Authorization": f"Bearer {auth_token}"} if auth_token else {}
    
    # Extract request details
    path = event.get("rawPath", "/")
    
    # API Gateway v2 provides method differently depending on integration
    method = None
    if "requestContext" in event and "http" in event["requestContext"]:
        method = event["requestContext"]["http"].get("method")
    if not method:
        method = event.get("httpMethod", "GET")
    
    # Handle query string parameters
    query_params = event.get("queryStringParameters", {})
    if query_params:
        query_string = "&".join([f"{k}={v}" for k, v in query_params.items()])
        path = f"{path}?{query_string}"
    
    # Handle request body
    body = event.get("body", "")
    is_base64_encoded = event.get("isBase64Encoded", False)
    if is_base64_encoded and body:
        import base64
        body = base64.b64decode(body).decode("utf-8")
    
    # Add content-type header if provided
    content_type = None
    if "headers" in event:
        headers_dict = event["headers"]
        content_type = headers_dict.get("content-type") or headers_dict.get("Content-Type")
    if content_type:
        headers["Content-Type"] = content_type
    
    logger.info(f"Proxying {method} request to {path}")
    
    for url in urls:
        try:
            full_url = f"{url}{path}"
            logger.info(f"Trying backend: {full_url}")
            
            resp = requests.request(
                method, 
                full_url, 
                data=body if body else None,
                headers=headers
            )
            
            logger.info(f"Response from {url}: Status {resp.status_code}")
            
            # Filter out problematic headers
            safe_headers = {}
            for key, value in resp.headers.items():
                # Skip headers that might cause issues
                if key.lower() not in ['transfer-encoding', 'connection']:
                    safe_headers[key] = value
            
            return {
                "statusCode": resp.status_code,
                "headers": safe_headers,
                "body": resp.text
            }
        except Exception as e:
            logger.error(f"Failed on {url}: {str(e)}")
    
    logger.error("All backends unreachable")
    return {
        "statusCode": 502,
        "headers": {"Content-Type": "application/json"},
        "body": json.dumps({"message": "All backends unreachable"})
    }
