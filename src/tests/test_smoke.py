"""Smoke tests for FSL_2_Final_Project structure and data availability.

These tests verify that:
1. Required directories exist in the correct locations
2. Raw data CSV files are present in data/data_raw/
3. The main notebook exists at src/main.ipynb
"""

import os
from pathlib import Path


def get_project_root() -> Path:
    """Find the project root (contains README.md, data/, src/)."""
    # Start from this file's location and go up
    current = Path(__file__).resolve()
    
    # Go up until we find the project root markers
    for parent in current.parents:
        if (parent / "README.md").exists() and \
           (parent / "data").is_dir() and \
           (parent / "src").is_dir():
            return parent
    
    # Fallback: assume we're in src/tests/ so go up 2 levels
    return current.parent.parent.parent


PROJECT_ROOT = get_project_root()


class TestDirectoryStructure:
    """Test that required directories exist."""

    def test_project_root_exists(self):
        """Project root should exist and contain README.md."""
        assert PROJECT_ROOT.exists()
        assert (PROJECT_ROOT / "README.md").exists()

    def test_data_directories_exist(self):
        """Data directories should exist under data/."""
        data_dir = PROJECT_ROOT / "data"
        assert data_dir.is_dir(), f"Missing: {data_dir}"
        
        data_raw = data_dir / "data_raw"
        assert data_raw.is_dir(), f"Missing: {data_raw}"
        
        data_processed = data_dir / "data_processed"
        assert data_processed.is_dir(), f"Missing: {data_processed}"

    def test_src_directories_exist(self):
        """Source directories should exist under src/."""
        src_dir = PROJECT_ROOT / "src"
        assert src_dir.is_dir(), f"Missing: {src_dir}"
        
        # Required subdirectories under src/
        required_subdirs = ["models", "scripts", "report", "outputs", "tests"]
        for subdir in required_subdirs:
            path = src_dir / subdir
            assert path.is_dir(), f"Missing: {path}"

    def test_outputs_subdirectories_exist(self):
        """Output subdirectories should exist under src/outputs/."""
        outputs_dir = PROJECT_ROOT / "src" / "outputs"
        
        required_subdirs = ["figures", "tables", "diagnostics", "model_objects", "simulations"]
        for subdir in required_subdirs:
            path = outputs_dir / subdir
            assert path.is_dir(), f"Missing: {path}"

    def test_docs_directory_exists(self):
        """Docs directory should exist at project root."""
        docs_dir = PROJECT_ROOT / "docs"
        assert docs_dir.is_dir(), f"Missing: {docs_dir}"

    def test_notes_directory_exists(self):
        """Notes directory should exist at project root."""
        notes_dir = PROJECT_ROOT / "notes"
        assert notes_dir.is_dir(), f"Missing: {notes_dir}"


class TestDataFiles:
    """Test that required data files are present."""

    def test_raw_data_files_exist(self):
        """Required raw CSV files should exist in data/data_raw/."""
        data_raw = PROJECT_ROOT / "data" / "data_raw"
        
        required_files = [
            "TB_outcomes_2026-04-04.csv",
            "TB_burden_countries_2026-04-04.csv",
            "TB_data_dictionary_2026-04-04.csv",
        ]
        
        for filename in required_files:
            path = data_raw / filename
            assert path.exists(), f"Missing raw data file: {path}"
            assert path.stat().st_size > 0, f"Empty file: {path}"


class TestNotebook:
    """Test that the main notebook exists."""

    def test_main_notebook_exists(self):
        """Main notebook should exist at src/main.ipynb."""
        notebook_path = PROJECT_ROOT / "src" / "main.ipynb"
        assert notebook_path.exists(), f"Missing notebook: {notebook_path}"
        assert notebook_path.stat().st_size > 0, f"Empty notebook: {notebook_path}"


class TestPhase0Deliverables:
    """Test that Phase 0 deliverables exist."""

    def test_decision_log_exists(self):
        """Decision log should exist at notes/decision_log.md."""
        path = PROJECT_ROOT / "notes" / "decision_log.md"
        assert path.exists(), f"Missing: {path}"
        assert path.stat().st_size > 0, f"Empty file: {path}"

    def test_version_manifest_exists(self):
        """Version manifest should exist in outputs/tables/."""
        path = PROJECT_ROOT / "src" / "outputs" / "tables" / "version_manifest.csv"
        assert path.exists(), f"Missing: {path}"
        assert path.stat().st_size > 0, f"Empty file: {path}"

    def test_git_metadata_exists(self):
        """Git metadata should exist in outputs/tables/."""
        path = PROJECT_ROOT / "src" / "outputs" / "tables" / "git_metadata.yaml"
        assert path.exists(), f"Missing: {path}"
        assert path.stat().st_size > 0, f"Empty file: {path}"

    def test_setup_metadata_exists(self):
        """Setup metadata should exist in outputs/tables/."""
        path = PROJECT_ROOT / "src" / "outputs" / "tables" / "setup_metadata.yaml"
        assert path.exists(), f"Missing: {path}"
        assert path.stat().st_size > 0, f"Empty file: {path}"


class TestPhase1Deliverables:
    """Test that Phase 1 deliverables exist."""

    def test_analysis_rules_exists(self):
        """Analysis rules should exist at notes/analysis_rules.md."""
        path = PROJECT_ROOT / "notes" / "analysis_rules.md"
        assert path.exists(), f"Missing: {path}"
        assert path.stat().st_size > 0, f"Empty file: {path}"


class TestPhase2Deliverables:
    """Test that Phase 2 deliverables exist."""

    def test_intake_summary_exists(self):
        """Intake summary should exist in outputs/tables/."""
        path = PROJECT_ROOT / "src" / "outputs" / "tables" / "intake_summary.csv"
        assert path.exists(), f"Missing: {path}"
        assert path.stat().st_size > 0, f"Empty file: {path}"

    def test_project_variable_dictionary_exists(self):
        """Project variable dictionary should exist in outputs/tables/."""
        path = PROJECT_ROOT / "src" / "outputs" / "tables" / "project_variable_dictionary.csv"
        assert path.exists(), f"Missing: {path}"
        assert path.stat().st_size > 0, f"Empty file: {path}"

    def test_year_completeness_exists(self):
        """Year completeness table should exist in outputs/tables/."""
        path = PROJECT_ROOT / "src" / "outputs" / "tables" / "year_completeness.csv"
        assert path.exists(), f"Missing: {path}"
        assert path.stat().st_size > 0, f"Empty file: {path}"

    def test_outcome_availability_plot_exists(self):
        """Outcome availability plot should exist in outputs/figures/."""
        path = PROJECT_ROOT / "src" / "outputs" / "figures" / "outcome_availability_by_year.png"
        assert path.exists(), f"Missing: {path}"
        assert path.stat().st_size > 0, f"Empty file: {path}"


def test_no_absolute_paths_in_readme():
    """README should not contain hardcoded absolute paths."""
    readme_path = PROJECT_ROOT / "README.md"
    content = readme_path.read_text()
    
    # Check for common absolute path patterns
    forbidden_patterns = [
        "/Users/",
        "/home/",
        "C:\\",
        "D:\\",
    ]
    
    for pattern in forbidden_patterns:
        assert pattern not in content, \
            f"README.md contains absolute path pattern: {pattern}"


if __name__ == "__main__":
    # Simple runner for quick checks
    print(f"Project root: {PROJECT_ROOT}")
    print("\nRunning smoke tests...")
    
    # Directory structure
    print("\n--- Directory Structure ---")
    for name in ["data", "data/data_raw", "data/data_processed", 
                 "src", "src/models", "src/scripts", "src/report", 
                 "src/outputs", "src/tests", "docs"]:
        path = PROJECT_ROOT / name
        status = "OK" if path.is_dir() else "MISSING"
        print(f"  [{status}] {name}/")
    
    # Key files
    print("\n--- Key Files ---")
    for name in ["README.md", "src/main.ipynb"]:
        path = PROJECT_ROOT / name
        status = "OK" if path.exists() else "MISSING"
        print(f"  [{status}] {name}")
    
    # Raw data files
    print("\n--- Raw Data Files ---")
    data_raw = PROJECT_ROOT / "data" / "data_raw"
    for f in data_raw.glob("*.csv"):
        size_kb = f.stat().st_size / 1024
        print(f"  [OK] {f.name} ({size_kb:.1f} KB)")
    
    print("\nSmoke tests complete.")
