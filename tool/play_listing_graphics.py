"""Replaces the Play store listing's feature graphic and app icon.

Run by .github/workflows/play-listing-graphics.yml with the Play service
account in PLAY_SERVICE_ACCOUNT_JSON. Opens one Play edit, swaps the images
for the listing's default language, then validates (--dry-run) or commits it.
Committing sends the listing change to Play review like any console edit.
"""

import argparse
import json
import os
import sys

import requests
from google.auth.transport.requests import Request
from google.oauth2 import service_account

API = "https://androidpublisher.googleapis.com/androidpublisher/v3/applications"
UPLOAD = "https://androidpublisher.googleapis.com/upload/androidpublisher/v3/applications"


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--package", required=True)
    parser.add_argument("--feature-graphic", required=True)
    parser.add_argument("--icon", required=True)
    parser.add_argument("--dry-run", action="store_true")
    args = parser.parse_args()

    creds = service_account.Credentials.from_service_account_info(
        json.loads(os.environ["PLAY_SERVICE_ACCOUNT_JSON"]),
        scopes=["https://www.googleapis.com/auth/androidpublisher"],
    )
    creds.refresh(Request())
    session = requests.Session()
    session.headers["Authorization"] = f"Bearer {creds.token}"

    def call(method, url, **kw):
        r = session.request(method, url, timeout=120, **kw)
        if not r.ok:
            sys.exit(f"{method} {url} -> {r.status_code}: {r.text}")
        return r.json() if r.content else {}

    app = f"{API}/{args.package}"
    edit = call("POST", f"{app}/edits")["id"]
    language = call("GET", f"{app}/edits/{edit}/details")["defaultLanguage"]
    print(f"edit {edit}, listing language {language}")

    for image_type, path in (
        ("featureGraphic", args.feature_graphic),
        ("icon", args.icon),
    ):
        listing = f"{edit}/listings/{language}/{image_type}"
        # Play keeps one image of each of these types; clear it so the upload
        # replaces rather than fails.
        call("DELETE", f"{app}/edits/{listing}")
        with open(path, "rb") as f:
            image = call(
                "POST",
                f"{UPLOAD}/{args.package}/edits/{listing}?uploadType=media",
                headers={"Content-Type": "image/png"},
                data=f.read(),
            )["image"]
        print(f"{image_type}: uploaded {path} (sha256 {image.get('sha256', '?')})")

    if args.dry_run:
        call("POST", f"{app}/edits/{edit}:validate")
        call("DELETE", f"{app}/edits/{edit}")
        print("dry run: edit validated and discarded, nothing published")
    else:
        call("POST", f"{app}/edits/{edit}:commit")
        print("committed: listing change sent to Play")
    return 0


if __name__ == "__main__":
    sys.exit(main())
