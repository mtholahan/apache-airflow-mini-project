from pathlib import Path
import sys

def analyze_file(base_log_dir, task_name):
    base_path = Path(base_log_dir)

    if not base_path.exists():
        print(f"Provided base log directory does not exist: {base_path}")
        return

    run_dirs = sorted(base_path.glob("run_id=*"), reverse=True)
    if not run_dirs:
        print(f"No run_id directories found under {base_path}")
        return

    latest_run = run_dirs[0]
    task_logs_path = latest_run / f"task_id={task_name}"

    if not task_logs_path.exists():
        print(f"No logs found for task '{task_name}' under {latest_run}")
        return

    log_files = list(task_logs_path.rglob("*.log"))
    if not log_files:
        print(f"No log files found in {task_logs_path}")
        return

    total_errors = 0
    error_lines = []

    print(f"Scanning {len(log_files)} log files in {task_logs_path}...")

    for file in log_files:
        with file.open() as f:
            for line in f:
                if "ERROR" in line:
                    total_errors += 1
                    error_lines.append(line.strip())

    print(f"Total number of errors: {total_errors}")
    print("Here are all the errors:")
    for line in error_lines:
        print(line)

if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Usage: python log_analyzer.py <log_directory> <task_name>")
        sys.exit(1)
    analyze_file(sys.argv[1], sys.argv[2])
