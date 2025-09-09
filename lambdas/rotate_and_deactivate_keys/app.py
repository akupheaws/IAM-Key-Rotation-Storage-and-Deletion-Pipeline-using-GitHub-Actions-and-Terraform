import json
import os
import datetime
from typing import Dict, Any, List

import boto3
from botocore.exceptions import ClientError

iam = boto3.client("iam")
secrets = boto3.client("secretsmanager")
sns = boto3.client("sns")


def _env(name: str, required: bool = True, default: str | None = None) -> str:
    val = os.getenv(name, default)
    if required and (val is None or val == ""):
        raise RuntimeError(f"Missing required env var: {name}")
    return val


def deactivate_old_active_keys(username: str) -> List[Dict[str, Any]]:
    """Deactivate all ACTIVE keys except the newest one. Return changed metadata."""
    resp = iam.list_access_keys(UserName=username)
    keys = resp.get("AccessKeyMetadata", [])
    if not keys:
        return []
    keys.sort(key=lambda k: k["CreateDate"], reverse=True)
    to_deactivate = [k for k in keys if k["Status"] == "Active"][1:]  # keep newest
    changed = []
    for k in to_deactivate:
        try:
            iam.update_access_key(
                UserName=username, AccessKeyId=k["AccessKeyId"], Status="Inactive"
            )
            kk = dict(k)
            kk["NewStatus"] = "Inactive"
            changed.append(kk)
        except ClientError as e:
            print(f"Failed to deactivate {k['AccessKeyId']}: {e}")
    return changed


def create_new_key(username: str) -> Dict[str, str]:
    resp = iam.create_access_key(UserName=username)
    ak = resp["AccessKey"]
    return {
        "AccessKeyId": ak["AccessKeyId"],
        "SecretAccessKey": ak["SecretAccessKey"],
        "CreateDate": ak["CreateDate"].isoformat(),
        "UserName": ak["UserName"],
    }


def upsert_secret(secret_name: str, json_key: str, keypair: Dict[str, str]) -> None:
    payload = json.dumps({json_key: keypair})
    try:
        secrets.put_secret_value(SecretId=secret_name, SecretString=payload)
    except secrets.exceptions.ResourceNotFoundException:
        secrets.create_secret(Name=secret_name, SecretString=payload)


def notify(topic_arn: str, subject: str, message: Dict[str, Any]) -> None:
    sns.publish(
        TopicArn=topic_arn,
        Subject=subject[:100],
        Message=json.dumps(message, default=str, indent=2),
    )


def lambda_handler(event, context):
    username = _env("TARGET_USERNAME")
    secret_name = _env("SECRET_NAME")
    topic_arn = _env("SNS_TOPIC_ARN")
    json_key = _env("SECRET_JSON_KEY", required=False, default="current")

    deactivated = deactivate_old_active_keys(username)
    new_key = create_new_key(username)
    upsert_secret(secret_name, json_key, new_key)

    now = datetime.datetime.utcnow().isoformat() + "Z"
    msg = {
        "action": "rotate_and_deactivate_keys",
        "username": username,
        "deactivated_keys": [k["AccessKeyId"] for k in deactivated],
        "new_access_key_id": new_key["AccessKeyId"],
        "secret_name": secret_name,
        "secret_json_key": json_key,
        "timestamp": now,
    }
    notify(topic_arn, f"IAM key rotated for {username}", msg)
    return {"statusCode": 200, "body": msg}
