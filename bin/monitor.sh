#!/usr/bin/env bash
set -u

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
. "$SCRIPT_DIR/common.sh"

start_loop() {
  local name="$1"
  local logfile="$2"
  shift 2

  (
    log_line "$name loop started" >> "$logfile"
    while :; do
      "$@" >> "$logfile" 2>&1
      sleep "${SNAPSHOT_INTERVAL_SECONDS:-10}"
    done
  ) &
  add_child_pid "$name" "$!"
}

snapshot_processes() {
  printf "\n===== %s =====\n" "$(timestamp)"
  ps axww -o pid,ppid,user,stat,lstart,command | awk -v p1="$PROCESS_1" -v p2="$PROCESS_2" 'NR == 1 || index($0, p1) || index($0, p2)'
}

snapshot_network() {
  printf "\n===== %s =====\n" "$(timestamp)"
  sudo lsof -nP -iTCP -iUDP | awk -v p1="$PROCESS_1" -v p2="$PROCESS_2" -v ip="$TARGET_IP" -v port="$TARGET_PORT" 'NR == 1 || index($0, p1) || index($0, p2) || (index($0, ip) && index($0, ":" port))'
}

snapshot_launchctl() {
  printf "\n===== %s =====\n" "$(timestamp)"
  launchctl print "system/$LAUNCH_LABEL_1" 2>&1
  printf "\n"
  launchctl print "system/$LAUNCH_LABEL_2" 2>&1
}

start_tcpdump() {
  local iface="$1"
  local pcap="$RUN_DIR/traffic.pcap"
  local log="$RUN_DIR/tcpdump.log"

  log_line "tcpdump interface: $iface" >> "$log"
  sudo tcpdump -i "$iface" -n -s 0 -w "$pcap" "host $TARGET_IP and port $TARGET_PORT" >> "$log" 2>&1 &
  add_child_pid "tcpdump" "$!"
}

start_fs_usage() {
  local log="$RUN_DIR/fs_usage.log"
  (
    log_line "fs_usage started for $PROCESS_1/$PROCESS_2"
    sudo fs_usage -w -f filesystem 2>/dev/null | awk -v p1="$PROCESS_1" -v p2="$PROCESS_2" 'index($0, p1) || index($0, p2) { print; fflush() }'
  ) >> "$log" 2>&1 &
  add_child_pid "fs_usage" "$!"
}

start_sudo_keepalive() {
  (
    while :; do
      sudo -n -v >/dev/null 2>&1 || exit 0
      sleep 60
    done
  ) &
  add_child_pid "sudo_keepalive" "$!"
}

supervise() {
  save_monitor_pid "$$"
  trap 'log_line "monitor supervisor exiting" >> "$RUN_DIR/monitor.log"; exit 0' TERM INT
  log_line "SDMon V1.1 monitor started: $RUN_DIR" >> "$RUN_DIR/monitor.log"
  while :; do
    sleep 3600 &
    wait $!
  done
}

main() {
  ensure_command awk
  ensure_command date
  ensure_command find
  ensure_command launchctl
  ensure_command lsof
  ensure_command ps
  ensure_command route
  ensure_command sudo
  ensure_command tcpdump
  ensure_command fs_usage

  sdmon_mkdirs
  if monitor_is_running; then
    log_line "SDMon is already running. PID: $(active_monitor_pid)"
    log_line "Run directory: $(current_run_dir)"
    exit 0
  fi

  require_sudo
  create_run_dir

  {
    log_line "SDMon V1.1 run directory: $RUN_DIR"
    log_line "Target processes: $PROCESS_1, $PROCESS_2"
    log_line "Target paths: $TARGET_PATH_1, $TARGET_PATH_2"
    log_line "Target services: $LAUNCH_LABEL_1, $LAUNCH_LABEL_2"
    log_line "Target server: $TARGET_IP:$TARGET_PORT"
  } | tee -a "$RUN_DIR/monitor.log"

  local iface
  iface="$(route_interface_for_target)"
  if [ -z "$iface" ]; then
    iface="pktap"
  fi

  start_sudo_keepalive
  start_tcpdump "$iface"
  start_fs_usage
  start_loop "process" "$RUN_DIR/process.log" snapshot_processes
  start_loop "network" "$RUN_DIR/network.log" snapshot_network
  start_loop "launchctl" "$RUN_DIR/launchctl.log" snapshot_launchctl

  log_line "Monitoring started. Supervisor PID: $$"
  log_line "Use Stop_SDMon.command to stop SDMon collection and generate reports."
  supervise
}

main "$@"
