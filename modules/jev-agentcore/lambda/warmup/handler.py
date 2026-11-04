"""Pre-business-hours warm-up ping for the Jev decider (Posture A).

Sends one trivial decision to the AgentCore runtime using a STABLE session id,
so the first real caller of the day reaches a warm microVM instead of eating a
45-90s cold start. Billed cost is a few seconds of a 2 vCPU/8 GB microVM per
weekday — negligible — while overnight the session idles out and costs nothing.
"""
from __future__ import annotations

import json
import os

import boto3
from botocore.config import Config

_ARN = os.environ["DECIDER_RUNTIME_ARN"]
# AgentCore runtimeSessionId must be >= 33 chars; reusing one keeps ONE replica warm.
_SESSION_ID = os.environ["WARMUP_SESSION_ID"]

# Cold start can take ~90s; give boto3 room so the warm-up itself doesn't time out.
_client = boto3.client(
    "bedrock-agentcore",
    config=Config(read_timeout=900, connect_timeout=10, retries={"max_attempts": 2}),
)

_PAYLOAD = {
    "state": "warm-up ping",
    "questions": {
        "ready": {"type": "noul", "instructions": "Is the model loaded and ready?"}
    },
}


def handler(event, context):  # noqa: ANN001, ARG001
    resp = _client.invoke_agent_runtime(
        agentRuntimeArn=_ARN,
        runtimeSessionId=_SESSION_ID,
        payload=json.dumps(_PAYLOAD).encode("utf-8"),
    )
    body = resp["response"].read().decode("utf-8") if "response" in resp else ""
    return {"ok": True, "session_id": _SESSION_ID, "response_preview": body[:200]}
