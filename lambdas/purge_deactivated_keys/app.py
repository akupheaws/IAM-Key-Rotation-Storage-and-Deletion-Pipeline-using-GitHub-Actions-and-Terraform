import os
import datetime
from typing import List
import boto3
from botocore.exceptions import ClientError


def _env(name: str, required: bool = True, default: str | None = None) -> str:
    v = os.getenv(name, default)
    if required and (not v):
        raise RuntimeError(f"Missing required env var: {name}")
    return v


def _iam():
    return boto3.session.Session().client("iam")


def delete_inactive_keys(username: str) -> List[str]:
    iam = _iam()
    resp = iam.list_access_keys(UserName=username)
    keys = resp.get("AccessKeyMetadata", [])
    deleted: List[str] = []
    for k in keys:
        if k["Status"] == "Inactive":
            try:
                iam.delete_access_key(UserName=username, AccessKeyId=k["AccessKeyId"])
                deleted.append(k["AccessKeyId"])
            except ClientError as e:
                print(f"Failed to delete {k['AccessKeyId']}: {e}")
    return deleted


def lambda_handler(event, context):
    username = _env("TARGET_USERNAME")
    deleted = delete_inactive_keys(username)
    body = {
        "action": "purge_deactivated_keys",
        "username": username,
        "deleted_keys": deleted,
        "timestamp": datetime.datetime.utcnow().isoformat() + "Z",
    }
    return {"statusCode": 200, "body": body}
