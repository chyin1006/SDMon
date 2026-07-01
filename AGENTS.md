# AGENTS.md

## Project
SDMon = Security Dynamic Monitor for macOS Enterprise Agent Analysis.

## Current target
V1.1 only monitors this software:

- /Library/Application Support/ExampleAgent/demo-agent
- /Library/Application Support/ExampleHelper/demo-helper
- Server: 192.0.2.10:7777

## Requirements
- Use Bash only.
- Use macOS built-in tools only.
- Do not require Homebrew.
- Do not require Python.
- Do not delete, stop, unload, or modify the target software.
- Monitoring must be read-only.
- Output must be saved under ~/Downloads/2026-110.
- Start_SDMon.command must be double-click runnable.
- Stop_SDMon.command must stop monitoring and generate reports.
- Analyse.command must analyse collected logs.

## Expected files
- Start_SDMon.command
- Stop_SDMon.command
- Analyse.command
- bin/common.sh
- bin/monitor.sh
- bin/stop.sh
- bin/analyse.sh
- bin/summary.sh
- bin/findings.sh
- config.conf
- rules/sensitive_paths.conf
- rules/process.conf
- rules/network.conf

## V1.1 monitoring scope
Collect:
- tcpdump pcap for 192.0.2.10:7777
- sudo lsof network snapshots
- process snapshots for demo-agent/demo-helper
- launchctl status for com.example.demo-agent and com.example.demo-helper
- fs_usage filtered to demo-agent/demo-helper
- sensitive path findings

Sensitive paths:
- Chrome History
- Chrome Login Data
- Safari History
- SSH ~/.ssh
- Keychains
- Documents
- Desktop
- Downloads
- WeChat
- Foxmail
- Photos.sqlite

## Output
Each run creates:

~/Downloads/2026-110/run_YYYYMMDD_HHMMSS/

Files:
- traffic.pcap
- process.log
- network.log
- launchctl.log
- fs_usage.log
- summary.txt
- findings.txt
- zip package

## Development rules
- Keep scripts readable.
- Add comments for important logic.
- Do not commit generated logs, pcap, zip, or output files.
- After editing, run shell syntax checks:
  bash -n file.sh
