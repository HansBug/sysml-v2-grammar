#!/usr/bin/env python3
"""SysML v2 Grammar Conformance Test Runner.

Parses official OMG SysML v2 Release files (training, validation, examples,
standard library) through the ANTLR4 Java grammar and reports failures.

Usage:
    python scripts/conformance.py                    # Run all suites
    python scripts/conformance.py --suite validation  # Run one suite
    python scripts/conformance.py --fetch             # Fetch fixtures first

Requires:
    - Java 17+ on PATH
    - ANTLR4 JAR at .build/antlr4.jar (run `make download-antlr`)
    - Compiled grammar at .build/antlr-test/ (built automatically)
"""

from __future__ import annotations

import argparse
import hashlib
import json
import shutil
import subprocess
import sys
import tarfile
import tempfile
import urllib.request
from dataclasses import dataclass, field
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
BUILD_DIR = ROOT / ".build"
ANTLR_JAR = BUILD_DIR / "antlr4.jar"
GRAMMAR_CLASS_DIR = BUILD_DIR / "antlr-test" / "grammar"
GRAMMAR_STAMP = BUILD_DIR / "antlr-test" / ".grammar.sha256"
FIXTURES_DIR = ROOT / "test" / "fixtures" / "conformance"

with (ROOT / "scripts" / "config.json").open(encoding="utf-8") as config_file:
    RELEASE_CONFIG = json.load(config_file)

LIBRARY_REPO = RELEASE_CONFIG["release_repo"]
LIBRARY_REVISION = RELEASE_CONFIG["release_revision"]
LIBRARY_ARCHIVE = f"https://github.com/{LIBRARY_REPO}/archive/{LIBRARY_REVISION}.tar.gz"

# Standard library ships with the repo (committed)
LIBRARY_DIR = ROOT / "sysml.library"

SUITES: dict[str, dict] = {
    "library": {
        "label": "Standard Library",
        "dir": LIBRARY_DIR,
        "extensions": [".sysml"],
        "committed": True,
    },
    "training": {
        "label": "Official Training Examples",
        "dir": FIXTURES_DIR / "training",
        "extensions": [".sysml"],
    },
    "validation": {
        "label": "Official Validation Models",
        "dir": FIXTURES_DIR / "validation",
        "extensions": [".sysml"],
    },
    "examples": {
        "label": "Official SysML Examples",
        "dir": FIXTURES_DIR / "examples",
        "extensions": [".sysml"],
    },
}


@dataclass
class ParseFailure:
    file: str
    stderr: str


@dataclass
class SuiteResult:
    name: str
    label: str
    total: int
    failures: list[ParseFailure] = field(default_factory=list)
    missing: bool = False

    @property
    def passed(self) -> bool:
        return not self.failures and not self.missing


def find_files(directory: Path, extensions: list[str]) -> list[Path]:
    """Recursively find files matching given extensions."""
    if not directory.exists():
        return []
    results = []
    for ext in extensions:
        results.extend(directory.rglob(f"*{ext}"))
    return sorted(results)


def ensure_grammar_compiled() -> None:
    """Compile the grammar with ANTLR4 Java target if not already done."""
    if not ANTLR_JAR.exists():
        print(
            "❌ ANTLR4 JAR not found. Run 'make download-antlr' first.", file=sys.stderr
        )
        sys.exit(1)

    grammar_sources = [
        ROOT / "grammar" / "SysMLv2Lexer.g4",
        ROOT / "grammar" / "SysMLv2Parser.g4",
    ]
    digest = hashlib.sha256()
    for source in grammar_sources:
        digest.update(str(source.relative_to(ROOT)).encode("utf-8"))
        digest.update(source.read_bytes())
    # The generated classes depend on both grammar sources and the ANTLR
    # runtime/tool JAR. Include the JAR bytes so replacing the tool cannot
    # silently reuse classes compiled by a different generator version.
    digest.update(b"antlr4.jar\0")
    digest.update(ANTLR_JAR.read_bytes())
    build_hash = digest.hexdigest()

    # Reuse only a build produced from the current grammar sources and JAR.
    previous_hash = GRAMMAR_STAMP.read_text().strip() if GRAMMAR_STAMP.exists() else ""
    if (
        GRAMMAR_CLASS_DIR / "SysMLv2Parser.class"
    ).exists() and previous_hash == build_hash:
        return

    print("  Compiling grammar (Java target)...")
    compile_dir = BUILD_DIR / "antlr-test"
    shutil.rmtree(compile_dir, ignore_errors=True)
    compile_dir.mkdir(parents=True, exist_ok=True)

    subprocess.run(
        [
            "java",
            "-jar",
            str(ANTLR_JAR),
            "-Dlanguage=Java",
            "-o",
            str(compile_dir),
            "grammar/SysMLv2Lexer.g4",
            "grammar/SysMLv2Parser.g4",
        ],
        cwd=str(ROOT),
        check=True,
        capture_output=True,
    )

    java_sources = [str(path.name) for path in sorted(GRAMMAR_CLASS_DIR.glob("*.java"))]
    subprocess.run(
        ["javac", "-cp", f"{ANTLR_JAR}:.", *java_sources],
        cwd=str(GRAMMAR_CLASS_DIR),
        check=True,
        capture_output=True,
    )
    GRAMMAR_STAMP.write_text(build_hash + "\n")


def parse_file(filepath: Path) -> ParseFailure | None:
    """Parse a single file through ANTLR4 TestRig. Returns failure or None."""
    result = subprocess.run(
        [
            "java",
            "-cp",
            f"{ANTLR_JAR}:.",
            "org.antlr.v4.gui.TestRig",
            "SysMLv2",
            "rootNamespace",
            str(filepath),
        ],
        cwd=str(GRAMMAR_CLASS_DIR),
        capture_output=True,
        text=True,
        timeout=30,
    )

    stderr = result.stderr.strip()
    if result.returncode != 0 or stderr:
        rel = str(filepath.relative_to(ROOT))
        first_line = (
            stderr
            or result.stdout.strip()
            or f"TestRig exited with {result.returncode}"
        ).split("\n")[0][:120]
        return ParseFailure(file=rel, stderr=first_line)
    return None


def run_suite(name: str, suite: dict) -> SuiteResult:
    """Run conformance tests for a single suite."""
    label = suite["label"]
    directory = Path(suite["dir"])
    extensions = suite["extensions"]

    files = find_files(directory, extensions)

    if not files:
        message = "No fixture files found (run --fetch to download)"
        print(f"  ❌ {label}: {message}")
        return SuiteResult(
            name=name,
            label=label,
            total=0,
            failures=[ParseFailure(file=str(directory), stderr=message)],
            missing=True,
        )

    failures: list[ParseFailure] = []
    for f in files:
        failure = parse_file(f)
        if failure:
            failures.append(failure)

    return SuiteResult(name=name, label=label, total=len(files), failures=failures)


def fetch_fixtures() -> None:
    """Download conformance fixtures from the OMG SysML v2 Release repo."""
    print(f"📥 Fetching conformance fixtures from {LIBRARY_REPO}...")

    with tempfile.TemporaryDirectory() as tmpdir:
        archive_path = Path(tmpdir) / "release.tar.gz"
        urllib.request.urlretrieve(LIBRARY_ARCHIVE, str(archive_path))

        extract_dir = Path(tmpdir) / "extracted"
        extract_dir.mkdir()

        with tarfile.open(archive_path, "r:gz") as tar:
            tar.extractall(path=str(extract_dir), filter="data")

        # Find the extracted root (e.g., SysML-v2-Release-master/)
        roots = list(extract_dir.iterdir())
        if len(roots) != 1:
            print(f"❌ Unexpected archive structure: {roots}", file=sys.stderr)
            sys.exit(1)
        src_root = roots[0]

        # Clean and copy fixtures
        if FIXTURES_DIR.exists():
            shutil.rmtree(FIXTURES_DIR)
        FIXTURES_DIR.mkdir(parents=True, exist_ok=True)

        mapping = {
            "sysml/src/training": "training",
            "sysml/src/validation": "validation",
            "sysml/src/examples": "examples",
        }

        for src_rel, dst_name in mapping.items():
            src = src_root / src_rel
            dst = FIXTURES_DIR / dst_name
            if src.exists():
                shutil.copytree(src, dst)
                count = len(list(dst.rglob("*.sysml")))
                print(f"  {dst_name}: {count} .sysml files")

    # Also fetch/update standard library
    print(f"\n📥 Fetching standard library from {LIBRARY_REPO}...")
    with tempfile.TemporaryDirectory() as tmpdir:
        archive_path = Path(tmpdir) / "release.tar.gz"
        urllib.request.urlretrieve(LIBRARY_ARCHIVE, str(archive_path))

        extract_dir = Path(tmpdir) / "extracted"
        extract_dir.mkdir()

        with tarfile.open(archive_path, "r:gz") as tar:
            members = [m for m in tar.getmembers() if "/sysml.library/" in m.name]
            tar.extractall(path=str(extract_dir), members=members, filter="data")

        roots = list(extract_dir.iterdir())
        if roots:
            src_lib = roots[0] / "sysml.library"
            if src_lib.exists():
                # Clear existing subdirectories
                for sub in ["Domain Libraries", "Kernel Libraries", "Systems Library"]:
                    target = LIBRARY_DIR / sub
                    if target.exists():
                        shutil.rmtree(target)
                # Copy fresh
                for item in src_lib.iterdir():
                    dst = LIBRARY_DIR / item.name
                    if item.is_dir():
                        if dst.exists():
                            shutil.rmtree(dst)
                        shutil.copytree(item, dst)
                sysml_count = len(list(LIBRARY_DIR.rglob("*.sysml")))
                kerml_count = len(list(LIBRARY_DIR.rglob("*.kerml")))
                print(f"  Library: {sysml_count} .sysml, {kerml_count} .kerml files")

    print("\n✅ Conformance fixtures updated")


def main() -> None:
    parser = argparse.ArgumentParser(description="SysML v2 Grammar Conformance Tests")
    parser.add_argument(
        "--fetch", action="store_true", help="Fetch/update fixtures from OMG repo"
    )
    parser.add_argument(
        "--suite", choices=list(SUITES.keys()), help="Run only this suite"
    )
    parser.add_argument(
        "--verbose", "-v", action="store_true", help="Show individual file failures"
    )
    args = parser.parse_args()

    if args.fetch:
        fetch_fixtures()
        return

    print("SysML v2 Grammar Conformance Tests")
    print("=" * 50)

    ensure_grammar_compiled()

    suites_to_run = {args.suite: SUITES[args.suite]} if args.suite else SUITES
    results: list[SuiteResult] = []
    any_failure = False

    for name, suite in suites_to_run.items():
        result = run_suite(name, suite)
        results.append(result)

        if result.missing:
            any_failure = True
            if args.verbose:
                for failure in result.failures:
                    print(f"       ✗ {failure.file} — {failure.stderr}")
        elif result.passed:
            print(f"  ✅ {result.label}: {result.total}/{result.total} passed")
        else:
            any_failure = True
            failed = len(result.failures)
            passed = result.total - failed
            print(
                f"  ❌ {result.label}: {passed}/{result.total} passed ({failed} failures)"
            )
            if args.verbose:
                for f in result.failures:
                    print(f"       ✗ {f.file} — {f.stderr}")

    # Summary
    print()
    total_files = sum(r.total for r in results)
    total_failures = sum(len(r.failures) for r in results)
    print(
        f"📊 Total: {total_files - total_failures}/{total_files} files passed across {len(results)} suites"
    )

    if any_failure:
        print()
        print("Failing files:")
        for r in results:
            for f in r.failures:
                print(f"  ✗ {f.file}")
                print(f"    {f.stderr}")
        sys.exit(1)
    else:
        print("\n✅ All conformance tests passed")


if __name__ == "__main__":
    main()
