import io
import json
import os
from pathlib import Path
import subprocess
import zipfile

REPOSITORY = "kubla/chronoception"
PARENT = 11
NATIVE_TRAIN = "testTrainingRepeatsAndPersistsWithoutCreatingEstimates"
NATIVE_TEST = "testRealEstimateFeedbackAndHistorySurviveRelaunch"
BROWSER_TRAIN = "phone: train with three real timed cues, persistence, separate estimate count and per-interval calibration"


def assess(run, receipts, candidate_tree):
    problems = []
    required = ["purpose-browser", "purpose-phone", "purpose-watch", "purpose-release"]
    if run["conclusion"] != "success":
        problems.append("Change acceptance failed or did not finish")
    for name in required:
        receipt = receipts.get(name)
        if not receipt:
            problems.append(name + ": missing receipt")
            continue
        if str(receipt.get("run")) != str(run["id"]) or receipt.get("candidate_tree") != candidate_tree:
            problems.append(name + ": stale or mismatched receipt")
        if receipt.get("result") != "passed":
            problems.append(name + ": acceptance did not pass")
    browser = receipts.get("purpose-browser", {})
    journeys = browser.get("journeys", [])
    if BROWSER_TRAIN not in journeys:
        problems.append("Browser training and calibration were not exercised")
    for kind in ["phone", "watch"]:
        media = receipts.get("purpose-" + kind, {}).get("media", [])
        mapped = {item["journey"] for item in media}
        if NATIVE_TRAIN not in mapped or NATIVE_TEST not in mapped:
            problems.append(kind + ": train and test journeys both required")
    rows = [
        {"outcome": "Train, test, and review calibration in the foreground", "status": "verified" if not problems else "unverified", "next": "Retain candidate evidence" if not problems else "Repair the missing or failed acceptance evidence"},
        {"outcome": "Screen-free cues on actual iPhone and Watch", "status": "not_verified", "next": "Implement supported locked-device cue adapters and collect device timing, perceptibility, interruption and battery evidence"},
        {"outcome": "Signed personal native delivery", "status": "not_verified", "next": "Establish personal signing destination, distribute, install and smoke-test the signed build"},
    ]
    return {"parent_issue": PARENT, "candidate_tree": candidate_tree,
            "run": run["id"], "change_acceptance": "passed" if run["conclusion"] == "success" else "failed",
            "product_status": "incomplete", "outcomes": rows, "problems": problems,
            "limits": "Known-journey evidence coverage, not an independent semantic review. Physical cues and signed delivery have no commissioned verifier and remain open. This publisher queues next work; it does not launch an AI worker."}


def api(path, method="GET", payload=None, binary=False):
    command = ["gh", "api", "--method", method, "repos/" + REPOSITORY + "/" + path]
    if payload is not None:
        command += ["--input", "-"]
    result = subprocess.check_output(command, input=json.dumps(payload).encode() if payload is not None else None)
    return result if binary else json.loads(result)


def publish():
    event = json.loads(Path(os.environ["GITHUB_EVENT_PATH"]).read_text())
    run_id = int(event["workflow_run"]["id"])
    run = api(f"actions/runs/{run_id}")
    if run["repository"]["full_name"] != REPOSITORY or run["head_repository"]["full_name"] != REPOSITORY:
        raise SystemExit("Only this repository's native acceptance runs are publishable")
    if run["name"] != "Native acceptance" or run["status"] != "completed":
        raise SystemExit("Expected a completed native acceptance run")
    if run["event"] not in ["push", "pull_request"]:
        raise SystemExit("Unsupported run event")
    if run["event"] == "push" and run["head_branch"] != "main":
        raise SystemExit("Only delivered main pushes are publishable")
    artifacts = api(f"actions/runs/{run_id}/artifacts?per_page=100")["artifacts"]
    receipts = {}
    candidates = set()
    for item in artifacts:
        name = item["name"]
        if name not in ["purpose-browser", "purpose-phone", "purpose-watch", "purpose-release"]:
            continue
        if name in receipts or item["size_in_bytes"] > 1_000_000 or item["expired"]:
            raise SystemExit("Invalid or duplicate purpose artifact")
        data = api(f"actions/artifacts/{int(item['id'])}/zip", binary=True)
        with zipfile.ZipFile(io.BytesIO(data)) as archive:
            entries = archive.infolist()
            if len(entries) != 1 or entries[0].file_size > 100_000 or entries[0].filename != "receipt.json":
                raise SystemExit("Expected one small receipt, not executable artifact contents")
            receipt = json.loads(archive.read(entries[0]))
        candidates.add(receipt["candidate"])
        receipts[name] = receipt
    candidate_tree = "unverified"
    if len(candidates) == 1:
        candidate = next(iter(candidates))
        if not isinstance(candidate, str) or len(candidate) != 40 or any(c not in "0123456789abcdef" for c in candidate):
            raise SystemExit("Invalid candidate commit")
        commit = api("commits/" + candidate)
        if candidate != run["head_sha"] and run["head_sha"] not in [item["sha"] for item in commit["parents"]]:
            raise SystemExit("Receipt does not address this run's source or its tested merge")
        candidate_tree = commit["commit"]["tree"]["sha"]
    report = assess(run, receipts, candidate_tree)
    Path("product-status.json").write_text(json.dumps(report, indent=2) + "\n")
    heading = "## Automated product status"
    lines = [heading, "", f"[Acceptance run]({run['html_url']}) · `{run['head_sha']}`", "",
             "Change acceptance: **" + report["change_acceptance"] + "**. Product: **incomplete**.", ""]
    for item in report["outcomes"]:
        lines += ["- **" + item["outcome"] + ": " + item["status"] + ".** " + item["next"]]
    lines += ["", report["limits"]]
    if report["problems"]:
        lines += ["", "Evidence gaps:"] + ["- " + item for item in report["problems"]]
    text = "\n".join(lines) + "\n"
    Path(os.environ["GITHUB_STEP_SUMMARY"]).write_text(text)
    if run["event"] == "push":
        latest = api("commits/main")["sha"]
        if latest != run["head_sha"]:
            print("Superseded main run: retained report without overwriting parent")
            return
        issue = api(f"issues/{PARENT}")
        body = (issue["body"] or "").split(heading)[0].rstrip() + "\n\n" + text
        api(f"issues/{PARENT}", "PATCH", {"body": body, "state": "open"})


if __name__ == "__main__":
    publish()
