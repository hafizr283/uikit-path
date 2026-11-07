#!/usr/bin/env python3
"""Typecheck exact course examples on an iOS SDK and run bounded host tests.

No course source is rewritten to make a check pass. Contextual exercise imports
and dependencies are declared in validation/runtime-cases.json. --prepare-only
works without Xcode and records NOT RUN rather than claiming compilation.
"""

import argparse
import hashlib
import json
import os
import platform
import shlex
import shutil
import subprocess
import sys
import time
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
VALIDATION = ROOT / "validation"
LIMITATIONS = [
    "Worked examples are typechecked for iOS Simulator with Swift 6; typechecking is not an app build or a UI/simulator run.",
    "Day 12 is checked with Day 11's unchanged TaskAPI source, as its walkthrough requires.",
    "Day 14's Swift source needs no generated model types. The required PocketTasks.xcdatamodeld schema, persistent-store opening, CRUD, migrations, and Core Data background behavior are NOT runtime-tested here.",
    "Day 20 is a Bash script: bash -n checks syntax only. Its build/test commands are not executed by this course-example workflow.",
    "Pure Swift runtime cases execute on the macOS host, not an iOS simulator. They make no real network requests and use only unique temporary files/preferences.",
    "Day 16's worked example and three exercise solutions execute as real XCTest tests in a temporary Swift package on macOS. Its URLSession test is intercepted by the supplied URLProtocol fixture.",
    "Other exercise solutions, UI rendering, entitlements, Keychain behavior, notifications, external API availability, and accessibility behavior are outside this runner's runtime coverage.",
]


def run_tool(arguments, timeout=30):
    process = subprocess.run(arguments, cwd=ROOT, text=True, encoding="utf-8",
                             errors="replace", stdout=subprocess.PIPE,
                             stderr=subprocess.STDOUT, timeout=timeout)
    if process.returncode:
        raise RuntimeError("Command failed: " + shlex.join(arguments) + "\n" + process.stdout)
    return process.stdout.strip()


def extract(course, selector):
    day = selector["day"]
    lesson = course[day]
    if selector["part"] == "example":
        code = lesson["example"]["code"]
        reference = f"content/day-{day:02}.json#example.code"
    else:
        exercise_id = selector["exercise"]
        matches = [exercise for exercise in lesson["exercises"] if exercise["id"] == exercise_id]
        if len(matches) != 1:
            raise ValueError(f"Expected one exercise {exercise_id} on day {day}")
        code = matches[0][selector["part"]]
        reference = f"content/day-{day:02}.json#exercises.{exercise_id}.{selector['part']}"
    if not isinstance(code, str) or not code.strip():
        raise ValueError(f"Empty source: {reference}")
    imports = selector.get("imports", [])
    prefix = "".join(f"import {module}\n" for module in imports)
    return prefix + code + "\n", {
        "reference": reference,
        "course_source_sha256": hashlib.sha256(code.encode("utf-8")).hexdigest(),
        "context_imports_added": imports,
    }


def prepare_cases(course, destination):
    cases = []
    extracted = destination / "extracted"
    for day in range(1, 21):
        directory = extracted / f"day-{day:02}-example"
        directory.mkdir(parents=True, exist_ok=True)
        selectors = [{"day": day, "part": "example"}]
        if day == 12:
            selectors.insert(0, {"day": 11, "part": "example"})
        paths, provenance = [], []
        for index, selector in enumerate(selectors):
            code, source = extract(course, selector)
            extension = ".sh" if day == 20 else ".swift"
            path = directory / f"Source{index + 1}{extension}"
            path.write_text(code, encoding="utf-8")
            paths.append(path)
            provenance.append(source)
        cases.append({
            "id": f"day-{day:02}-example", "kind": "shell-syntax" if day == 20 else "ios-typecheck",
            "scope": "Bash syntax only" if day == 20 else "Unchanged worked example",
            "paths": paths, "sources": provenance,
        })

    runtime_manifest = json.loads((VALIDATION / "runtime-cases.json").read_text(encoding="utf-8"))
    for item in runtime_manifest:
        directory = extracted / item["id"]
        directory.mkdir(parents=True, exist_ok=True)
        paths, provenance = [], []
        for index, selector in enumerate(item["sources"]):
            code, source = extract(course, selector)
            path = directory / f"Source{index + 1}.swift"
            path.write_text(code, encoding="utf-8")
            paths.append(path)
            provenance.append(source)
        harness = (VALIDATION / item["harness"]).resolve()
        if VALIDATION.resolve() not in harness.parents or not harness.is_file():
            raise ValueError(f"Invalid test-only harness: {harness}")
        copied_harness = directory / "Harness.swift"
        shutil.copyfile(harness, copied_harness)
        paths.append(copied_harness)
        provenance.append({
            "reference": str(harness.relative_to(ROOT)).replace(os.sep, "/"),
            "test_only": True,
            "sha256": hashlib.sha256(harness.read_bytes()).hexdigest(),
        })
        cases.append({
            "id": item["id"] + "-ios", "kind": "ios-typecheck",
            "scope": item["scope"] + " (source plus test harness typecheck)",
            "paths": paths, "sources": provenance,
        })
        cases.append({
            "id": item["id"] + "-runtime", "kind": "host-runtime",
            "scope": item["scope"], "paths": paths, "sources": provenance,
        })

    # Day 16's private teaching types and its core extension must be in one file,
    # exactly as the exercise says. All fragments remain textually unchanged.
    selectors = [{"day": 16, "part": "example"}] + [
        {"day": 16, "exercise": exercise_id, "part": "solution"}
        for exercise_id in ("16-warmup", "16-core", "16-stretch")
    ]
    fragments, provenance = [], []
    for selector in selectors:
        code, source = extract(course, selector)
        fragments.append(code)
        provenance.append(source)
    package = extracted / "day16-xctest"
    tests = package / "Tests"
    tests.mkdir(parents=True, exist_ok=True)
    test_file = tests / "CourseExampleTests.swift"
    test_file.write_text("\n".join(fragments), encoding="utf-8")
    (package / "Package.swift").write_text(
        '// swift-tools-version: 6.0\n'
        'import PackageDescription\n'
        'let package = Package(\n'
        '    name: "UIKitPathExampleValidation",\n'
        '    platforms: [.macOS(.v13)],\n'
        '    targets: [.testTarget(name: "CourseExampleTests", path: "Tests")]\n'
        ')\n', encoding="utf-8")
    cases.append({
        "id": "day16-xctest-ios", "kind": "ios-typecheck",
        "scope": "Day 16 worked example and all three exercise solutions",
        "paths": [test_file], "sources": provenance,
    })
    cases.append({
        "id": "day16-xctest-runtime", "kind": "host-xctest",
        "scope": "Actual XCTest execution: Day 16 worked example plus all three exercise solutions",
        "paths": [test_file], "sources": provenance, "package": package,
    })
    return cases, runtime_manifest


def exercise_coverage(course, runtime_manifest):
    selected = {(source["day"], source.get("exercise"))
                for case in runtime_manifest for source in case["sources"]
                if source.get("exercise")}
    coverage = []
    for day, lesson in course.items():
        for exercise in lesson["exercises"]:
            included = day == 16 or (day, exercise["id"]) in selected
            coverage.append({
                "day": day, "id": exercise["id"], "title": exercise["title"],
                "selected_for_runtime_checks": included,
                "reason": ("Executed with the declared harness or Day 16 XCTest suite when native checks run."
                           if included else "Not selected by this bounded runner; no runtime correctness claim is made for this solution. Follow its app/setup instructions."),
            })
    return coverage


def execute_case(case, commands, destination):
    started = time.monotonic()
    log = destination / "logs" / (case["id"] + ".log")
    log.parent.mkdir(parents=True, exist_ok=True)
    status, return_code = "passed", 0
    executed = []
    with log.open("w", encoding="utf-8") as stream:
        for command in commands:
            arguments = [str(value) for value in command]
            executed.append(arguments)
            stream.write("$ " + shlex.join(arguments) + "\n")
            stream.flush()
            try:
                process = subprocess.run(arguments, cwd=ROOT, text=True, encoding="utf-8",
                                         errors="replace", stdout=subprocess.PIPE,
                                         stderr=subprocess.STDOUT, timeout=240)
                stream.write(process.stdout)
                return_code = process.returncode
            except subprocess.TimeoutExpired as error:
                status, return_code = "failed", 124
                stream.write("Timed out after 240 seconds.\n")
                if error.stdout:
                    text = error.stdout.decode("utf-8", errors="replace") if isinstance(error.stdout, bytes) else error.stdout
                    stream.write(text)
            if return_code:
                status = "failed"
                break
    result = {
        "id": case["id"], "kind": case["kind"], "scope": case["scope"],
        "status": status, "return_code": return_code,
        "duration_seconds": round(time.monotonic() - started, 3),
        "commands": executed, "sources": case["sources"],
        "log": str(log.relative_to(destination)).replace(os.sep, "/"),
    }
    print(f"{status.upper():7} {case['id']}", flush=True)
    if status == "failed":
        print(log.read_text(encoding="utf-8")[-18000:], flush=True)
    return result


def write_report(destination, environment, results, coverage, prepare_only):
    passed = sum(result["status"] == "passed" for result in results)
    failed = sum(result["status"] == "failed" for result in results)
    not_run = sum(result["status"] == "not_run" for result in results)
    report = {
        "mode": "prepare-only" if prepare_only else "native-validation",
        "environment": environment,
        "counts": {"passed": passed, "failed": failed, "not_run": not_run},
        "results": results, "exercise_coverage": coverage, "limitations": LIMITATIONS,
    }
    (destination / "report.json").write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    lines = ["# UIKit course source validation", "",
             f"Passed: **{passed}** · Failed: **{failed}** · Not run: **{not_run}**", ""]
    if prepare_only:
        lines += ["**Preparation only. No Swift compiler, simulator, or test execution occurred.**", ""]
    lines += ["| Check | Scope | Result |", "| --- | --- | --- |"]
    for result in results:
        lines.append(f"| `{result['id']}` | {result['kind']} | {result['status']} |")
    lines += ["", "## Verification limits", ""]
    lines += ["- " + value for value in LIMITATIONS]
    uncovered = [item for item in coverage if not item["selected_for_runtime_checks"]]
    lines += ["", "## Exercise solutions outside runtime coverage", ""]
    lines += [f"- Day {item['day']:02}, `{item['id']}`: {item['title']}" for item in uncovered]
    lines += ["", "Toolchain, exact commands, source hashes, and per-case diagnostics are in report.json and logs/.", ""]
    (destination / "report.md").write_text("\n".join(lines), encoding="utf-8")
    print(f"Report: {destination / 'report.md'}", flush=True)
    return failed


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output-dir", type=Path, default=ROOT / ".build" / "swift-validation")
    parser.add_argument("--prepare-only", action="store_true",
                        help="Extract and verify test inputs only; explicitly report native checks as not run.")
    arguments = parser.parse_args()
    destination = arguments.output_dir.resolve()
    destination.mkdir(parents=True, exist_ok=True)
    course = {}
    for day in range(1, 21):
        lesson = json.loads((ROOT / "content" / f"day-{day:02}.json").read_text(encoding="utf-8"))
        expected = ".sh" if day == 20 else ".swift"
        if lesson["day"] != day or Path(lesson["example"]["filename"]).suffix != expected:
            raise ValueError(f"Unexpected example identity/language on day {day}")
        course[day] = lesson
    cases, manifest = prepare_cases(course, destination)
    coverage = exercise_coverage(course, manifest)
    environment = {"platform": platform.platform(), "python": sys.version}
    try:
        environment["commit"] = run_tool(["git", "rev-parse", "HEAD"])
    except (RuntimeError, FileNotFoundError):
        environment["commit"] = "unavailable"
    if arguments.prepare_only:
        results = [{"id": case["id"], "kind": case["kind"], "scope": case["scope"],
                    "status": "not_run", "sources": case["sources"],
                    "reason": "--prepare-only: inputs prepared; no native verification performed"}
                   for case in cases]
        write_report(destination, environment, results, coverage, True)
        return 0
    if sys.platform != "darwin":
        raise RuntimeError("Native validation requires macOS with Xcode. Use --prepare-only elsewhere; it does not count as compilation.")

    swiftc = run_tool(["xcrun", "--find", "swiftc"])
    swift = run_tool(["xcrun", "--find", "swift"])
    ios_sdk = run_tool(["xcrun", "--sdk", "iphonesimulator", "--show-sdk-path"])
    ios_platform = Path(run_tool(["xcrun", "--sdk", "iphonesimulator", "--show-sdk-platform-path"]))
    mac_sdk = run_tool(["xcrun", "--sdk", "macosx", "--show-sdk-path"])
    architecture = "arm64" if platform.machine() == "arm64" else "x86_64"
    environment.update({
        "xcode": run_tool(["xcodebuild", "-version"]),
        "swift": run_tool([swiftc, "--version"]),
        "ios_sdk": ios_sdk, "macos_sdk": mac_sdk,
        "ios_target": architecture + "-apple-ios17.0-simulator",
        "host_target": architecture + "-apple-macosx13.0",
    })
    cache = destination / "module-cache"
    cache.mkdir(exist_ok=True)
    common = [swiftc, "-swift-version", "6", "-strict-concurrency=complete",
              "-parse-as-library", "-module-cache-path", cache]
    ios = common + ["-sdk", ios_sdk, "-target", environment["ios_target"],
                    "-F", ios_platform / "Developer" / "Library" / "Frameworks"]
    host = common + ["-sdk", mac_sdk, "-target", environment["host_target"]]
    results = []
    for case in cases:
        if case["kind"] == "ios-typecheck":
            commands = [ios + ["-module-name", case["id"].replace("-", "_"), "-typecheck"] + case["paths"]]
        elif case["kind"] == "shell-syntax":
            commands = [["/bin/bash", "-n", case["paths"][0]]]
        elif case["kind"] == "host-runtime":
            executable = destination / "executables" / case["id"]
            executable.parent.mkdir(exist_ok=True)
            commands = [host + case["paths"] + ["-o", executable], [executable]]
        else:
            commands = [[swift, "test", "--package-path", case["package"],
                         "--scratch-path", destination / "xctest-build",
                         "-Xswiftc", "-strict-concurrency=complete"]]
        results.append(execute_case(case, commands, destination))
    failed = write_report(destination, environment, results, coverage, False)
    return 1 if failed else 0


if __name__ == "__main__":
    try:
        sys.exit(main())
    except (OSError, ValueError, RuntimeError, subprocess.TimeoutExpired) as error:
        print("Validation setup failed: " + str(error), file=sys.stderr)
        sys.exit(2)
