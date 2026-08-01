"""
Railway direct API deployer for GitHub Actions.
Uses Railway's GraphQL API + file upload to deploy without the CLI.
"""
import os
import json
import tarfile
import io
import time
import requests

RAILWAY_TOKEN = os.environ.get("RAILWAY_TOKEN")
REFRESH_TOKEN = os.environ.get("RAILWAY_REFRESH_TOKEN", "")
PROJECT_ID = os.environ.get("RAILWAY_PROJECT_ID")
ENV_ID = os.environ.get("RAILWAY_ENV_ID")
SERVICE_ID = os.environ.get("RAILWAY_SERVICE_ID")
BRANCH = os.environ.get("GITHUB_REF_NAME", "main")
GITHUB_SHA = os.environ.get("GITHUB_SHA", "")[:8]

API = "https://backboard.railway.com/graphql/v2"
CLIENT_ID = "rlwy_oaci_onEklvmksh1hRUiCo7E2zX12"
REDIRECT_URI = "http://127.0.0.1:49208/callback"

_token = None


def _get_headers() -> dict:
    global _token
    if _token is None:
        _token = RAILWAY_TOKEN
    return {
        "Content-Type": "application/json",
        "Authorization": f"Bearer {_token}",
        "User-Agent": "Railway-CLI/5.30.3 Darwin/24.0.0"
    }


def refresh_access_token() -> str:
    """Exchange refresh token for a new access token."""
    if not REFRESH_TOKEN:
        print("No refresh token available — using current access token")
        return RAILWAY_TOKEN

    print("Refreshing access token...")
    payload = json.dumps({
        "grant_type": "refresh_token",
        "refresh_token": REFRESH_TOKEN,
        "client_id": CLIENT_ID,
        "redirect_uri": REDIRECT_URI
    })
    headers = {
        "Content-Type": "application/json",
        "Accept": "application/json",
        "User-Agent": "Railway-CLI/5.30.3 Darwin/24.0.0"
    }
    resp = requests.post(
        "https://backboard.railway.com/oauth/auth",
        data=payload,
        headers=headers,
        timeout=15
    )
    if resp.status_code == 200:
        data = resp.json()
        new_token = data.get("access_token")
        if new_token:
            global _token
            _token = new_token
            print(f"Token refreshed! New token: {new_token[:20]}...")
            return new_token
    print(f"Token refresh failed: {resp.status_code} {resp.text[:200]}")
    return RAILWAY_TOKEN


def gql(query: str, variables: dict = None, _retried: bool = False) -> dict:
    global _token
    payload = {"query": query}
    if variables:
        payload["variables"] = variables
    resp = requests.post(API, json=payload, headers=_get_headers(), timeout=30)
    data = resp.json()

    # If unauthorized, try refreshing token once
    if resp.status_code == 401 and not _retried and REFRESH_TOKEN:
        refresh_access_token()
        return gql(query, variables, _retried=True)

    if data.get("errors"):
        raise Exception(f"GraphQL error: {data['errors']}")
    return data["data"]


def get_upload_url(service_id: str, environment_id: str) -> tuple[str, str]:
    """Get presigned upload URL and deployment ID."""
    query = """
    mutation CreateDeployment($serviceId: ID!, $environmentId: ID!, $branch: String!, $sha: String!) {
        createDeployment(
            input: {
                serviceId: $serviceId
                environmentId: $environmentId
                branch: $branch
                sha: $sha
            }
        ) {
            id
            uploadUrl
        }
    }
    """
    data = gql(query, {
        "serviceId": service_id,
        "environmentId": environment_id,
        "branch": BRANCH,
        "sha": GITHUB_SHA
    })
    deployment = data["createDeployment"]
    print(f"Deployment created: {deployment['id']}")
    return deployment["uploadUrl"], deployment["id"]


def upload_archive(upload_url: str, directory: str):
    """Create tarball of directory and upload it."""
    print(f"Creating tarball of {directory}...")
    tar_buffer = io.BytesIO()
    with tarfile.open(fileobj=tar_buffer, mode="w:gz") as tar:
        tar.add(directory, arcname=".")
    tar_data = tar_buffer.getvalue()
    print(f"Uploading {len(tar_data) / 1024 / 1024:.1f} MB...")

    resp = requests.put(
        upload_url,
        data=tar_buffer.getvalue(),
        headers={"Content-Type": "application/gzip", "User-Agent": "Railway-CLI/5.30.3"},
        timeout=120
    )
    if resp.status_code not in (200, 201):
        raise Exception(f"Upload failed: {resp.status_code} {resp.text}")
    print("Upload complete!")


def wait_for_deployment(deployment_id: str, timeout: int = 180) -> str:
    """Poll deployment status until it's RUNNING or FAILED."""
    query = """
    query GetDeployment($id: ID!) {
        deployment(id: $id) {
            id
            status
            url
        }
    }
    """
    start = time.time()
    while time.time() - start < timeout:
        data = gql(query, {"id": deployment_id})
        dep = data["deployment"]
        status = dep["status"]
        print(f"Deployment status: {status}")
        if status == "FAILED":
            raise Exception("Deployment failed!")
        if status == "SUCCESS" or status == "READY" or status == "RUNNING":
            return dep.get("url") or f"https://pawprint.up.railway.app"
        time.sleep(10)

    raise Exception("Deployment timed out!")


def main():
    if not all([RAILWAY_TOKEN, PROJECT_ID, ENV_ID, SERVICE_ID]):
        print("Missing env vars. Skipping Railway deploy.")
        print(f"  RAILWAY_TOKEN: {'set' if RAILWAY_TOKEN else 'MISSING'}")
        print(f"  RAILWAY_PROJECT_ID: {'set' if PROJECT_ID else 'MISSING'}")
        print(f"  RAILWAY_ENV_ID: {'set' if ENV_ID else 'MISSING'}")
        print(f"  RAILWAY_SERVICE_ID: {'set' if SERVICE_ID else 'MISSING'}")
        return

    print(f"Deploying to Railway production (env={ENV_ID}, service={SERVICE_ID})...")

    # Test token
    me = gql("{ me { id email } }")
    print(f"Authenticated as: {me['me']['email']}")

    upload_url, deployment_id = get_upload_url(SERVICE_ID, ENV_ID)
    upload_archive(upload_url, ".")

    print("Waiting for deployment...")
    url = wait_for_deployment(deployment_id, timeout=180)
    print(f"✓ App deployed! URL: {url}")

    # Output for GitHub Actions
    with open(os.environ.get("GITHUB_OUTPUT", "/dev/null"), "a") as f:
        f.write(f"url={url}\n")


if __name__ == "__main__":
    main()
