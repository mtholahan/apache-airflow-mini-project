# scripts/log_analyzer.py

import sys
from pathlib import Path
from datetime import datetime

def analyze_file(log_dir, task_substring):
    """
    Analyzes combined log files in `log_dir` for lines containing both
    `task_substring` and 'ERROR'. Prints and saves a summary report.
    """
    error_count = 0
    error_messages = []

    log_path = Path(log_dir)
    log_files = list(log_path.glob("marketvol_combined_log_*.txt"))

    timestamp = datetime.now().strftime("%Y-%m-%d_%H-%M-%S")
    report_file = log_path / f"report_{task_substring}_{timestamp}.txt"

    with open(report_file, "w") as report:
        report.write(f"📄 Log Summary for task substring: {task_substring}\n")
        print(f"\n📄 Log Summary for task substring: {task_substring}")

        for log_file in log_files:
            try:
                with open(log_file, 'r') as file:
                    for line in file:
                        if task_substring in line and 'ERROR' in line:
                            msg = line.strip()
                            error_messages.append(msg)
                            error_count += 1
            except Exception as e:
                msg = f"❌ Could not read file {log_file}: {e}"
                print(msg)
                report.write(msg + "\n")

        summary = f"Total number of matching error lines: {error_count}"
        print(summary)
        report.write(summary + "\n")

        if error_messages:
            print("Here are all the matched error lines:")
            report.write("Here are all the matched error lines:\n")
            for msg in error_messages:
                print(msg)
                report.write(msg + "\n")

    print(f"\n✅ Report saved to: {report_file}")
    return error_count, error_messages


# Allow command-line execution for manual testing
if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Usage: python log_analyzer.py <log_dir> <task_substring>")
        sys.exit(1)

    log_dir = sys.argv[1]
    task_substring = sys.argv[2]
    analyze_file(log_dir, task_substring)
