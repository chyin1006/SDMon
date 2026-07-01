#!/usr/bin/env bash

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

INPUT_FILE=""
OUTPUT_DIR=""
EVENTS_FILE=""
RULE_RESULTS_FILE=""
SENSOR_STATUS_FILE=""
RULES_DIR="$REPO_ROOT/rules_v2"
ELAPSED_TIME=""
SDMON_VERSION="SDMon V2 RC1"

usage() {
  cat <<'USAGE'
Usage:
  reporter.sh --input FILE --output-dir DIR [--events-file FILE] [--rule-results-file FILE] [--sensor-status-file FILE] [--rules-dir DIR] [--elapsed-time VALUE]
USAGE
}

die() {
  printf 'reporter: %s\n' "$1" >&2
  exit 1
}

json_get() {
  printf '%s\n' "$1" | sed -n 's/.*"'"$2"'":"\([^"]*\)".*/\1/p'
}

json_escape() {
  value="$1"
  value=${value//\\/\\\\}
  value=${value//\"/\\\"}
  value=${value//$'\t'/\\t}
  value=${value//$'\r'/\\r}
  value=${value//$'\n'/\\n}
  printf '%s' "$value"
}

count_matches() {
  pattern="$1"
  file="$2"
  if [ -f "$file" ]; then
    count="$(grep -c "$pattern" "$file" 2>/dev/null || true)"
    [ -n "$count" ] || count="0"
    printf '%s' "$count"
  else
    printf '0'
  fi
}

count_event_category() {
  category="$1"
  if [ -f "$EVENTS_FILE" ]; then
    count="$(grep -E -c "\"EVENT_CATEGORY\":\"$category\"|\"CATEGORY\":\"$category\"" "$EVENTS_FILE" 2>/dev/null || true)"
    [ -n "$count" ] || count="0"
    printf '%s' "$count"
  else
    printf '0'
  fi
}

count_event_type() {
  event_type="$1"
  if [ -f "$EVENTS_FILE" ]; then
    count="$(grep -c "\"EVENT_TYPE\":\"$event_type\"" "$EVENTS_FILE" 2>/dev/null || true)"
    [ -n "$count" ] || count="0"
    printf '%s' "$count"
  else
    printf '0'
  fi
}

count_rule_ids() {
  pattern="$1"
  if [ -f "$RULE_RESULTS_FILE" ]; then
    count="$(grep '"MATCH":"true"' "$RULE_RESULTS_FILE" 2>/dev/null | grep -v '"RULE_ID":"no_rule_match"' | grep -E -c "$pattern" 2>/dev/null || true)"
    [ -n "$count" ] || count="0"
    printf '%s' "$count"
  else
    printf '0'
  fi
}

status_for_sensor() {
  sensor="$1"
  if [ -f "$SENSOR_STATUS_FILE" ] && grep -q "\"SENSOR\":\"$sensor\".*\"STATUS\":\"success\"" "$SENSOR_STATUS_FILE" 2>/dev/null; then
    printf 'SUCCESS'
  else
    printf 'FAILED'
  fi
}

system_memory() {
  if command -v sysctl >/dev/null 2>&1; then
    mem_bytes="$(sysctl -n hw.memsize 2>/dev/null || true)"
    if [ -n "$mem_bytes" ]; then
      awk -v bytes="$mem_bytes" 'BEGIN { printf "%.1f GB", bytes / 1024 / 1024 / 1024 }'
      return 0
    fi
  fi
  printf 'unknown'
}

cpu_name() {
  if command -v sysctl >/dev/null 2>&1; then
    cpu_value="$(sysctl -n machdep.cpu.brand_string 2>/dev/null || true)"
    if [ -n "$cpu_value" ]; then
      printf '%s' "$cpu_value"
      return 0
    fi
  fi
  uname -m 2>/dev/null || printf 'unknown'
}

score_component() {
  points="$1"
  score="$((100 - points))"
  [ "$score" -lt 0 ] && score="0"
  printf '%s' "$score"
}

detail_get() {
  detail_line="$1"
  field_name="$2"
  printf '%s\n' "$detail_line" | sed -n 's/.*'"$field_name"'=\([^;]*\).*/\1/p'
}

severity_rank() {
  case "$1" in
    critical) printf '1' ;;
    high) printf '2' ;;
    medium) printf '3' ;;
    low) printf '4' ;;
    info) printf '5' ;;
    *) printf '6' ;;
  esac
}

upper_text() {
  printf '%s' "$1" | tr '[:lower:]' '[:upper:]'
}

health_level() {
  score="$1"
  if [ "$score" -ge 90 ]; then
    printf 'Excellent'
  elif [ "$score" -ge 80 ]; then
    printf 'Good'
  elif [ "$score" -ge 60 ]; then
    printf 'Fair'
  elif [ "$score" -ge 40 ]; then
    printf 'Needs Improvement'
  else
    printf 'Poor'
  fi
}

health_class() {
  score="$1"
  if [ "$score" -ge 90 ]; then
    printf 'health-excellent'
  elif [ "$score" -ge 80 ]; then
    printf 'health-good'
  elif [ "$score" -ge 60 ]; then
    printf 'health-fair'
  elif [ "$score" -ge 40 ]; then
    printf 'health-poor'
  else
    printf 'health-critical'
  fi
}

overall_risk_from_score() {
  score="$1"
  if [ "$score" -ge 80 ]; then
    printf 'Low'
  elif [ "$score" -ge 60 ]; then
    printf 'Medium'
  elif [ "$score" -ge 40 ]; then
    printf 'High'
  else
    printf 'Critical'
  fi
}

device_health_from_score() {
  score="$1"
  if [ "$score" -ge 90 ]; then
    printf '★★★★★'
  elif [ "$score" -ge 80 ]; then
    printf '★★★★☆'
  elif [ "$score" -ge 60 ]; then
    printf '★★★☆☆'
  elif [ "$score" -ge 40 ]; then
    printf '★★☆☆☆'
  else
    printf '★☆☆☆☆'
  fi
}

display_path() {
  value="$1"
  home_value="${HOME:-}"
  if [ -n "$home_value" ]; then
    case "$value" in
      "$home_value") printf '~'; return 0 ;;
      "$home_value"/*) printf '~/%s' "${value#"$home_value"/}"; return 0 ;;
    esac
  fi
  printf '%s' "$value"
}

timeline_label() {
  event_type="$1"
  action_value="$2"
  case "$event_type:$action_value" in
    launchd:*|*:launchd_program_missing|*:launchd_user_writable) printf '启动项异常' ;;
    credential_detected:*|*:credential_candidate|*:permission_unsafe|*:credential_*) printf '凭据配置检查' ;;
    sensitive_file:*|*:sensitive_file*) printf '敏感文件访问审查' ;;
    browser_extension:*|application_inventory:*|*:browser_*|*:application_*) printf '浏览器或应用需要复核' ;;
    gatekeeper_status:*|sip_status:*|filevault_status:*|xprotect_status:*|mrt_status:*|firewall_status:*) printf 'macOS 安全配置检查' ;;
    ssh_authorized_key:*) printf 'SSH 配置检查' ;;
    network_connection:*|*:connection|*:no_connection) printf '网络连接检查' ;;
    *) printf '系统行为记录' ;;
  esac
}

timeline_detail() {
  event_type="$1"
  action_value="$2"
  case "$event_type:$action_value" in
    launchd:*|*:launchd_program_missing) printf '发现某启动项指向的程序不存在或路径异常。' ;;
    *:launchd_user_writable) printf '发现用户可写启动项，建议确认来源是否可信。' ;;
    credential_detected:*|*:credential_candidate|*:permission_unsafe|*:credential_*) printf '发现 SSH 或凭据相关配置文件。' ;;
    sensitive_file:*|*:sensitive_file*) printf '发现系统敏感路径被读取或访问。' ;;
    browser_extension:*|application_inventory:*|*:browser_*|*:application_*) printf '发现浏览器扩展或应用信任状态需要复核。' ;;
    gatekeeper_status:*|sip_status:*|filevault_status:*|xprotect_status:*|mrt_status:*|firewall_status:*) printf '发现 macOS 安全配置状态，建议按企业策略复核。' ;;
    ssh_authorized_key:*) printf '发现 SSH 授权配置状态，建议确认访问控制是否符合预期。' ;;
    network_connection:*|*:connection|*:no_connection) printf '发现网络连接状态，建议确认是否符合企业业务预期。' ;;
    *) printf '发现一项系统行为记录，建议按需复核。' ;;
  esac
}

finding_title() {
  rule_id="$1"
  case "$rule_id" in
    firewall_*) printf '防火墙未启用' ;;
    filevault_*) printf '磁盘加密需要关注' ;;
    sip_*) printf '系统完整性保护需要关注' ;;
    gatekeeper_*) printf '应用控制未启用' ;;
    xprotect_*|mrt_*) printf '内置安全组件需要检查' ;;
    persistence_program_missing) printf '发现失效启动项' ;;
    persistence_user_writable|login_item_*) printf '启动项异常' ;;
    persistence_*tmp*|persistence_*downloads*|persistence_*desktop*) printf '启动项路径异常' ;;
    credential_*|ssh_*permission*) printf '凭据文件权限需要检查' ;;
    ssh_empty_authorized_keys) printf 'SSH 配置需要检查' ;;
    browser_*|application_*) printf '浏览器或应用需要复核' ;;
    network_*|remote_login_*|remote_management_*|screen_sharing_*|airdrop_*) printf '网络或远程访问配置需要复核' ;;
    sensitive_file_*) printf '敏感文件访问需要复核' ;;
    process_*) printf '进程行为需要复核' ;;
    *) printf '安全配置需要复核' ;;
  esac
}

finding_reason() {
  rule_id="$1"
  case "$rule_id" in
    firewall_*) printf '设备当前未启用应用防火墙。' ;;
    filevault_*) printf '磁盘加密状态或恢复密钥管理不符合预期。' ;;
    sip_*) printf '系统完整性保护存在关闭或降级项。' ;;
    gatekeeper_*) printf '设备未按预期启用 Gatekeeper。' ;;
    xprotect_*|mrt_*) printf '系统内置恶意软件防护状态需要确认。' ;;
    persistence_program_missing) printf '发现启动项指向的程序路径不存在。' ;;
    persistence_user_writable|login_item_*) printf '发现用户可写或异常启动项。' ;;
    persistence_*tmp*|persistence_*downloads*|persistence_*desktop*) printf '发现启动项执行路径位于临时或高风险目录。' ;;
    credential_*|ssh_*permission*) printf '发现配置文件或密钥文件权限偏宽。' ;;
    ssh_empty_authorized_keys) printf 'SSH 授权文件为空或状态异常。' ;;
    browser_*|application_*) printf '发现浏览器扩展或应用签名状态需要复核。' ;;
    network_*|remote_login_*|remote_management_*|screen_sharing_*|airdrop_*) printf '发现远程访问或网络暴露配置需要复核。' ;;
    sensitive_file_*) printf '发现对敏感文件的访问或配置暴露。' ;;
    process_*) printf '发现进程运行位置或行为不符合常规基线。' ;;
    *) printf '发现一项需要管理员确认的安全偏差。' ;;
  esac
}

finding_eta() {
  rule_id="$1"
  case "$rule_id" in
    firewall_*|screen_sharing_*|airdrop_*|remote_login_*) printf '3 分钟' ;;
    filevault_*|sip_*|gatekeeper_*) printf '5 分钟' ;;
    credential_*|ssh_*permission*) printf '2 分钟' ;;
    persistence_*|login_item_*) printf '5 分钟' ;;
    browser_*|application_*) printf '10 分钟' ;;
    *) printf '5 分钟' ;;
  esac
}

score_bucket() {
  rule_id="$1"
  severity="$2"
  case "$rule_id" in
    firewall_*) printf 'Firewall|10' ;;
    filevault_*) printf 'FileVault|8' ;;
    sip_*) printf 'SIP|8' ;;
    gatekeeper_*) printf 'Gatekeeper|8' ;;
    persistence_*|login_item_*) printf 'Persistence|6' ;;
    credential_*|ssh_*permission*) printf 'Credential|3' ;;
    browser_*|application_*) printf 'Browser|2' ;;
    sensitive_file_*) printf 'Sensitive File|3' ;;
    remote_login_*|remote_management_*|screen_sharing_*|airdrop_*|network_*) printf 'Network|5' ;;
    *)
      case "$severity" in
        high) printf 'High Risk|8' ;;
        medium) printf 'Medium Risk|4' ;;
        low) printf 'Low Risk|2' ;;
        *) printf 'Info|1' ;;
      esac
      ;;
  esac
}

rule_recommendation() {
  rule_id="$1"
  case "$rule_id" in
    firewall_*)
      printf '建议开启 macOS 应用防火墙。'
      ;;
    remote_login_*)
      printf '建议关闭不需要的远程登录，或确认其属于批准的远程运维流程。'
      ;;
    remote_management_*)
      printf '建议关闭不需要的远程管理，或确认其属于批准的管理工具。'
      ;;
    screen_sharing_*)
      printf '建议关闭不需要的屏幕共享，或确认其属于批准的远程支持流程。'
      ;;
    airdrop_*)
      printf '建议在企业终端上限制 AirDrop 使用。'
      ;;
    ssh_*permission*|credential_*unsafe*)
      printf '建议确认凭据文件权限是否符合企业安全规范。'
      ;;
    ssh_empty_authorized_keys)
      printf '建议检查 authorized_keys，并清理空文件或过期访问配置。'
      ;;
    persistence_*|login_item_*)
      printf '建议检查 LaunchAgent / LaunchDaemon 是否来自可信软件，清理异常启动项。'
      ;;
    process_*tmp*|process_*downloads*|process_*desktop*|process_*hidden*)
      printf '建议检查来自临时目录、下载目录、桌面或隐藏路径的进程执行行为。'
      ;;
    network_*port*)
      printf '建议检查外连端口，关闭不必要或不符合策略的网络访问。'
      ;;
    network_*external*)
      printf '建议检查频繁外连行为，确认是否符合企业业务预期。'
      ;;
    gatekeeper_*)
      printf '建议开启 Gatekeeper，并确认终端符合 macOS 应用控制策略。'
      ;;
    filevault_*)
      printf '建议开启 FileVault，并确认恢复密钥管理策略。'
      ;;
    sip_*)
      printf '建议检查系统完整性保护设置，并恢复被关闭的保护项。'
      ;;
    xprotect_*|mrt_*)
      printf '建议确认 macOS 内置恶意软件防护组件存在且保持更新。'
      ;;
    browser_*|application_*)
      printf '建议检查浏览器扩展和应用签名状态，确认是否符合企业允许的软件清单。'
      ;;
    sensitive_file_*)
      printf '建议检查敏感文件访问行为是否符合预期。'
      ;;
    *)
      printf '建议复核该发现，并确认是否符合企业安全策略。'
      ;;
  esac
}

rule_deduction() {
  rule_id="$1"
  severity="$2"
  case "$rule_id" in
    firewall_*) printf '%s' '-10 防火墙未启用' ;;
    remote_login_*) printf '%s' '-5 远程登录已启用' ;;
    remote_management_*) printf '%s' '-6 远程管理已启用' ;;
    screen_sharing_*) printf '%s' '-4 屏幕共享已启用' ;;
    airdrop_*) printf '%s' '-3 AirDrop 配置需要复核' ;;
    ssh_*permission*|credential_*unsafe*) printf '%s' '-8 凭据文件权限需要检查' ;;
    gatekeeper_*) printf '%s' '-8 Gatekeeper 配置需要检查' ;;
    filevault_*) printf '%s' '-8 FileVault 配置需要检查' ;;
    sip_*) printf '%s' '-8 SIP 保护需要检查' ;;
    browser_*|application_*) printf '%s' '-4 浏览器或应用信任状态需要复核' ;;
    persistence_*|login_item_*) printf '%s' '-6 启动项需要复核' ;;
    network_*) printf '%s' '-5 网络行为需要复核' ;;
    sensitive_file_*) printf '%s' '-3 敏感文件访问需要复核' ;;
    *)
      case "$severity" in
        high) printf '%s' '-8 高风险发现' ;;
        medium) printf '%s' '-4 中风险发现' ;;
        low) printf '%s' '-2 低风险发现' ;;
        *) printf '%s' '-1 信息类发现' ;;
      esac
      ;;
  esac
}

is_ai_string() {
  value="$1"
  case "$value" in
    *OpenAI*|*openai*|*Gemini*|*gemini*|*Claude*|*claude*|*Anthropic*|*anthropic*|*Copilot*|*copilot*|*Cursor*|*cursor*)
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

build_credential_summary() {
  if [ ! -f "$EVENTS_FILE" ]; then
    cat <<'EOF'
0
0
0
0
未发现常见凭据配置。
No common credential configuration files were observed.
<p>未发现常见凭据配置。</p>
No common credential configuration files were observed.
0
0
EOF
    return 0
  fi

  credential_events="0"
  credential_high="0"
  credential_medium="0"
  credential_low="0"
  credential_ai="0"
  credential_items_text=""
  credential_items_html=""
  credential_penalty="0"

  while IFS= read -r event_line; do
    [ -n "$event_line" ] || continue
    credential_events=$((credential_events + 1))

    credential_type="$(json_get "$event_line" "PROCESS_NAME")"
    credential_path="$(json_get "$event_line" "TARGET")"
    credential_status="$(json_get "$event_line" "STATUS")"
    detail_value="$(json_get "$event_line" "DETAIL")"
    permission_value="$(detail_get "$detail_value" "permission")"
    risk_value="$(detail_get "$detail_value" "risk")"
    reason_value="$(detail_get "$detail_value" "reason")"

    [ -n "$credential_type" ] || credential_type="Credential Candidate"
    [ -n "$permission_value" ] || permission_value="unknown"
    [ -n "$risk_value" ] || risk_value="info"
    [ -n "$reason_value" ] || reason_value="metadata_only_review"
    [ -n "$credential_status" ] || credential_status="present"

    case "$risk_value" in
      high)
        credential_high=$((credential_high + 1))
        credential_penalty=$((credential_penalty + 12))
        ;;
      medium)
        credential_medium=$((credential_medium + 1))
        credential_penalty=$((credential_penalty + 6))
        ;;
      low)
        credential_low=$((credential_low + 1))
        credential_penalty=$((credential_penalty + 1))
        ;;
    esac

    if is_ai_string "$credential_type" || is_ai_string "$credential_path"; then
      credential_ai=$((credential_ai + 1))
    fi

    if [ -n "$credential_items_text" ]; then
      credential_items_text="${credential_items_text} || "
    fi
    credential_display_path="$(display_path "$credential_path")"
    credential_items_text="${credential_items_text}${credential_type} | ${credential_display_path} | ${permission_value} | ${risk_value} | ${credential_status}"
    credential_items_html="${credential_items_html}<li><strong>${credential_type}</strong><br>Location: ${credential_display_path}<br>Permission: ${permission_value}<br>Risk: ${risk_value}<br>Status: ${credential_status}<br>Recommendation: Confirm local file permissions and storage location meet enterprise policy.<details><summary>Technical Details</summary><p>Full path: ${credential_path}</p><p>Reason: ${reason_value}</p></details></li>"
  done < <(grep '"EVENT_TYPE":"credential_detected"' "$EVENTS_FILE" 2>/dev/null || true)

  if [ "$credential_events" -eq 0 ]; then
    summary_cn="未发现常见凭据配置。"
    summary_en="No common credential configuration files were observed."
    html_block="<p>未发现常见凭据配置。</p>"
    text_block="No common credential configuration files were observed."
  else
    summary_cn="发现凭据配置并不代表泄露。建议确认权限是否符合企业安全规范。"
    summary_en="Credential-related files were observed. Presence does not imply exposure; review permissions and storage locations against local policy."
    html_block="<p>发现凭据配置并不代表泄露。建议确认权限是否符合企业安全规范。</p><ul>${credential_items_html}</ul>"
    text_block="$credential_items_text"
  fi

  cat <<EOF
$credential_events
$credential_high
$credential_medium
$credential_low
$summary_cn
$summary_en
$html_block
$text_block
$credential_penalty
$credential_ai
EOF
}

build_rule_summary() {
  if [ ! -f "$RULE_RESULTS_FILE" ]; then
    cat <<'EOF'
<p>No rule matches.</p>
No rule matches.
No immediate action required.
Review local findings when new scans are available.
none
0
0
0
0
0
0
0
<p>No score deductions were applied.</p>
0
EOF
    return 0
  fi

  findings_file="$(mktemp "${TMPDIR:-/tmp}/sdmon_report_findings.XXXXXX")"
  rec_file="$(mktemp "${TMPDIR:-/tmp}/sdmon_report_recs.XXXXXX")"
  ded_file="$(mktemp "${TMPDIR:-/tmp}/sdmon_report_deductions.XXXXXX")"
  score_file="$(mktemp "${TMPDIR:-/tmp}/sdmon_report_score.XXXXXX")"
  trap 'rm -f "$findings_file" "$rec_file" "$ded_file" "$score_file"' RETURN

  persistence_findings="0"
  network_findings="0"
  browser_findings="0"
  sensitive_file_findings="0"
  ai_rule_findings="0"

  while IFS= read -r rule_line; do
    [ -n "$rule_line" ] || continue
    rule_id="$(json_get "$rule_line" "RULE_ID")"
    severity="$(json_get "$rule_line" "SEVERITY")"
    message="$(json_get "$rule_line" "MESSAGE")"
    [ "$rule_id" = "no_rule_match" ] && continue

    case "$rule_id" in
      persistence_*|login_item_*) persistence_findings=$((persistence_findings + 1)) ;;
      network_*|remote_login_*|remote_management_*|screen_sharing_*|airdrop_*) network_findings=$((network_findings + 1)) ;;
      browser_*|application_*) browser_findings=$((browser_findings + 1)) ;;
      sensitive_file_*|ssh_*) sensitive_file_findings=$((sensitive_file_findings + 1)) ;;
    esac

    if is_ai_string "$rule_id" || is_ai_string "$message"; then
      ai_rule_findings=$((ai_rule_findings + 1))
    fi

    title_value="$(finding_title "$rule_id")"
    reason_value="$(finding_reason "$rule_id")"
    recommendation_value="$(rule_recommendation "$rule_id")"
    eta_value="$(finding_eta "$rule_id")"
    printf '%s|%s|%s|%s|%s|%s|%s|%s\n' "$(severity_rank "$severity")" "$severity" "$rule_id" "$message" "$title_value" "$reason_value" "$recommendation_value" "$eta_value" >> "$findings_file"
    printf '%s\n' "$(rule_recommendation "$rule_id")" >> "$rec_file"
    printf '%s\n' "$(rule_deduction "$rule_id" "$severity")" >> "$ded_file"
    printf '%s\n' "$(score_bucket "$rule_id" "$severity")" >> "$score_file"
  done < <(grep '"MATCH":"true"' "$RULE_RESULTS_FILE" 2>/dev/null | grep -v '"RULE_ID":"no_rule_match"' || true)

  top_html="<ol>"
  top_text=""
  top_rule="none"
  top_count="0"

  while IFS='|' read -r rank severity rule_id message title_value reason_value recommendation_value eta_value; do
    [ -n "$rule_id" ] || continue
    top_count=$((top_count + 1))
    if [ "$top_rule" = "none" ]; then
      top_rule="$rule_id"
    fi
    if [ -n "$top_text" ]; then
      top_text="${top_text} || "
    fi
    severity_upper="$(upper_text "$severity")"
    recommendation_display="$(printf '%s' "$recommendation_value" | sed 's/^建议//; s/^：//')"
    top_text="${top_text}${title_value} | ${severity_upper} | ${recommendation_value}"
    top_html="${top_html}<li><strong>${title_value}</strong><br>原因：${reason_value}<br>风险：${severity_upper}<br>建议：${recommendation_display}<br>预计耗时：${eta_value}<details><summary>Technical Details</summary><p>${message}</p><p>Rule: ${rule_id}</p></details></li>"
  done < <(sort -t'|' -k1,1n -k2,2 "$findings_file" 2>/dev/null | awk -F'|' '!seen[$3]++' | head -n 5)
  top_html="${top_html}</ol>"

  if [ "$top_count" = "0" ]; then
    top_html="<p>✅ No suspicious activity detected by current rules.</p>"
    top_text="No suspicious activity detected by current rules."
  fi

  recommendations_text=""
  recommendations_html="<ul>"
  while IFS= read -r recommendation; do
    [ -n "$recommendation" ] || continue
    if [ -n "$recommendations_text" ]; then
      recommendations_text="${recommendations_text} || "
    fi
    recommendations_text="${recommendations_text}${recommendation}"
    recommendations_html="${recommendations_html}<li>${recommendation}</li>"
  done < <(sort -u "$rec_file" 2>/dev/null | head -n 5)
  recommendations_html="${recommendations_html}</ul>"
  if [ -z "$recommendations_text" ]; then
    recommendations_text="Continue periodic review. No immediate action is required by current rules."
    recommendations_html="<p>Continue periodic review. No immediate action is required by current rules.</p>"
  fi

  deduction_text=""
  while IFS= read -r deduction_item; do
    [ -n "$deduction_item" ] || continue
    if [ -n "$deduction_text" ]; then
      deduction_text="${deduction_text} || "
    fi
    deduction_text="${deduction_text}${deduction_item}"
  done < <(sort -u "$ded_file" 2>/dev/null | head -n 8)
  if [ -z "$deduction_text" ]; then
    deduction_text="0"
  fi

  score_breakdown_text=""
  score_breakdown_html="<ul>"
  score_total="0"
  while IFS='|' read -r score_label score_points; do
    [ -n "$score_label" ] || continue
    score_total=$((score_total + score_points))
    if [ -n "$score_breakdown_text" ]; then
      score_breakdown_text="${score_breakdown_text} || "
    fi
    score_breakdown_text="${score_breakdown_text}${score_label} -${score_points}"
    score_breakdown_html="${score_breakdown_html}<li>${score_label}<br>-${score_points}</li>"
  done < <(awk -F'|' '
    {
      sum[$1]+=$2
    }
    END {
      cap["Firewall"]=6
      cap["FileVault"]=5
      cap["SIP"]=5
      cap["Gatekeeper"]=5
      cap["Persistence"]=6
      cap["Credential"]=3
      cap["Browser"]=2
      cap["Sensitive File"]=2
      cap["Network"]=5
      cap["High Risk"]=8
      cap["Medium Risk"]=4
      cap["Low Risk"]=2
      cap["Info"]=1
      for (k in sum) {
        limit=(k in cap ? cap[k] : 8)
        if (sum[k] > limit) sum[k]=limit
        printf "%s|%s\n", k, sum[k]
      }
    }
  ' "$score_file" | sort)
  score_breakdown_html="${score_breakdown_html}</ul>"
  if [ -z "$score_breakdown_text" ]; then
    score_breakdown_text="0"
    score_breakdown_html="<p>No score deductions were applied.</p>"
  fi

  cat <<EOF
$top_html
$top_text
$recommendations_html
$recommendations_text
$top_rule
$top_count
$persistence_findings
$network_findings
$browser_findings
$sensitive_file_findings
$ai_rule_findings
$deduction_text
$score_breakdown_text
$score_breakdown_html
$score_total
EOF
}

build_timeline_summary() {
  if [ ! -f "$EVENTS_FILE" ]; then
    cat <<'EOF'
<p>No timeline entries.</p>
No timeline entries.
0
EOF
    return 0
  fi

  timeline_file="$(mktemp "${TMPDIR:-/tmp}/sdmon_report_timeline.XXXXXX")"
  trap 'rm -f "$timeline_file"' RETURN

  while IFS= read -r event_line; do
    [ -n "$event_line" ] || continue
    timestamp="$(json_get "$event_line" "TIMESTAMP")"
    event_category="$(json_get "$event_line" "EVENT_CATEGORY")"
    event_type="$(json_get "$event_line" "EVENT_TYPE")"
    action_value="$(json_get "$event_line" "ACTION")"
    target_value="$(json_get "$event_line" "TARGET")"
    process_value="$(json_get "$event_line" "PROCESS_NAME")"
    if [ "$event_type" = "process_state" ] && [ "$action_value" = "running" ]; then
      continue
    fi
    if [ "$event_type" = "file_inventory" ]; then
      continue
    fi
    printf '%s|%s|%s|%s|%s|%s\n' "$timestamp" "$event_category" "$event_type" "$action_value" "$target_value" "$process_value" >> "$timeline_file"
  done < <(grep '^{' "$EVENTS_FILE" 2>/dev/null || true)

  timeline_html_primary="<ul>"
  timeline_html_more="<ul>"
  timeline_text=""
  timeline_count="0"
  while IFS='|' read -r timestamp event_category event_type action_value target_value process_value; do
    [ -n "$timestamp" ] || continue
    timeline_count=$((timeline_count + 1))
    event_label="$(timeline_label "$event_type" "$action_value")"
    display_target="$(display_path "$target_value")"
    event_detail="$(timeline_detail "$event_type" "$action_value")"
    [ -n "$display_target" ] && event_detail="${event_detail}<br>位置：${display_target}"
    [ -n "$process_value" ] && event_detail="${event_detail} (${process_value})"
    if [ -n "$timeline_text" ]; then
      timeline_text="${timeline_text} || "
    fi
    timeline_text="${timeline_text}${timestamp} | ${event_label} | ${event_detail}"
    if [ "$timeline_count" -le 20 ]; then
      timeline_html_primary="${timeline_html_primary}<li><strong>${timestamp}</strong><br>${event_label}<br>${event_detail}<details><summary>Technical Details</summary><p>Event: ${event_category}/${event_type}</p><p>Action: ${action_value}</p><p>Target: ${target_value}</p></details></li>"
    else
      timeline_html_more="${timeline_html_more}<li><strong>${timestamp}</strong><br>${event_label}<br>${event_detail}<details><summary>Technical Details</summary><p>Event: ${event_category}/${event_type}</p><p>Action: ${action_value}</p><p>Target: ${target_value}</p></details></li>"
    fi
  done < <(sort "$timeline_file" 2>/dev/null | head -n 30)
  timeline_html_primary="${timeline_html_primary}</ul>"
  timeline_html_more="${timeline_html_more}</ul>"

  if [ "$timeline_count" -gt 20 ]; then
    timeline_html="${timeline_html_primary}<details><summary>查看更多</summary>${timeline_html_more}</details>"
  else
    timeline_html="$timeline_html_primary"
  fi

  if [ "$timeline_count" = "0" ]; then
    timeline_html="<p>No timeline entries.</p>"
    timeline_text="No timeline entries."
  fi

  cat <<EOF
$timeline_html
$timeline_text
$timeline_count
EOF
}

percentage() {
  numerator="$1"
  denominator="$2"
  if [ "$denominator" -eq 0 ]; then
    printf '0'
  else
    awk -v a="$numerator" -v b="$denominator" 'BEGIN { printf "%.0f", (a * 100) / b }'
  fi
}

build_report_data() {
  report_data_file="$1"
  analysis_json="$(sed -n '1p' "$INPUT_FILE")"
  risk_score="$(json_get "$analysis_json" "RISK_SCORE")"
  confidence="$(json_get "$analysis_json" "CONFIDENCE")"

  scan_time="$(date -u '+%Y-%m-%dT%H:%M:%SZ')"
  host_name="$(hostname 2>/dev/null || printf 'unknown')"
  current_user="$(whoami 2>/dev/null || printf 'unknown')"
  system_version="$(sw_vers -productName 2>/dev/null || printf 'macOS')"
  os_version="$(sw_vers -productVersion 2>/dev/null || uname -r 2>/dev/null || printf 'unknown')"
  cpu_value="$(cpu_name)"
  memory_value="$(system_memory)"

  total_events="$(count_matches '^{' "$EVENTS_FILE")"
  process_events="$(count_event_category "process")"
  network_events="$(count_event_category "network")"
  launchd_events="$(count_event_category "service")"
  ssh_key_events="$(count_event_type "ssh_authorized_key")"
  sensitive_file_events="$(count_event_type "sensitive_file")"
  gatekeeper_events="$(count_event_type "gatekeeper_status")"
  sip_events="$(count_event_type "sip_status")"
  filevault_events="$(count_event_type "filevault_status")"
  macos_security_events="$((gatekeeper_events + sip_events + filevault_events))"
  permission_events="$(count_event_category "permission")"
  file_events="$(count_event_category "file")"
  system_events="$(count_event_category "system")"

  credential_record="$(build_credential_summary)"
  credential_events="$(printf '%s\n' "$credential_record" | sed -n '1p')"
  credential_high="$(printf '%s\n' "$credential_record" | sed -n '2p')"
  credential_medium="$(printf '%s\n' "$credential_record" | sed -n '3p')"
  credential_low="$(printf '%s\n' "$credential_record" | sed -n '4p')"
  credential_summary_cn="$(printf '%s\n' "$credential_record" | sed -n '5p')"
  credential_summary_en="$(printf '%s\n' "$credential_record" | sed -n '6p')"
  credential_items_html="$(printf '%s\n' "$credential_record" | sed -n '7p')"
  credential_items_text="$(printf '%s\n' "$credential_record" | sed -n '8p')"
  credential_penalty="$(printf '%s\n' "$credential_record" | sed -n '9p')"
  ai_tools_from_credentials="$(printf '%s\n' "$credential_record" | sed -n '10p')"

  rule_record="$(build_rule_summary)"
  top_findings_html="$(printf '%s\n' "$rule_record" | sed -n '1p')"
  top_findings_text="$(printf '%s\n' "$rule_record" | sed -n '2p')"
  recommendations_html="$(printf '%s\n' "$rule_record" | sed -n '3p')"
  recommendations_text="$(printf '%s\n' "$rule_record" | sed -n '4p')"
  top_rule="$(printf '%s\n' "$rule_record" | sed -n '5p')"
  top_findings_count="$(printf '%s\n' "$rule_record" | sed -n '6p')"
  persistence_findings="$(printf '%s\n' "$rule_record" | sed -n '7p')"
  network_findings="$(printf '%s\n' "$rule_record" | sed -n '8p')"
  browser_findings="$(printf '%s\n' "$rule_record" | sed -n '9p')"
  sensitive_findings="$(printf '%s\n' "$rule_record" | sed -n '10p')"
  ai_rule_findings="$(printf '%s\n' "$rule_record" | sed -n '11p')"
  deduction_text="$(printf '%s\n' "$rule_record" | sed -n '12p')"
  score_breakdown_text="$(printf '%s\n' "$rule_record" | sed -n '13p')"
  score_breakdown_html="$(printf '%s\n' "$rule_record" | sed -n '14p')"
  score_total="$(printf '%s\n' "$rule_record" | sed -n '15p')"

  timeline_record="$(build_timeline_summary)"
  timeline_html="$(printf '%s\n' "$timeline_record" | sed -n '1p')"
  timeline_text="$(printf '%s\n' "$timeline_record" | sed -n '2p')"
  timeline_count="$(printf '%s\n' "$timeline_record" | sed -n '3p')"

  sensors_loaded="$(find "$REPO_ROOT/sensors/macos" -name '*_sensor.sh' -type f 2>/dev/null | wc -l | tr -d ' ')"
  sensors_executed="$(count_matches '^{' "$SENSOR_STATUS_FILE")"
  rules_loaded="$(find "$RULES_DIR" -name '*.conf' -type f 2>/dev/null | wc -l | tr -d ' ')"
  rules_evaluated="$((total_events * rules_loaded))"
  rules_matched="$(grep '"MATCH":"true"' "$RULE_RESULTS_FILE" 2>/dev/null | grep -v '"RULE_ID":"no_rule_match"' | wc -l | tr -d ' ')"

  critical_risk="0"
  high_risk="$(count_rule_ids '"SEVERITY":"high"')"
  medium_risk="$(count_rule_ids '"SEVERITY":"medium"')"
  low_risk="$(count_rule_ids '"SEVERITY":"low"')"
  info_risk="$(count_rule_ids '"SEVERITY":"info"')"
  total_checks="$rules_loaded"
  warnings_count="$((info_risk + low_risk + medium_risk))"
  critical_checks="$((high_risk + critical_risk))"
  passed_checks="$((total_checks - warnings_count - critical_checks))"
  [ "$passed_checks" -lt 0 ] && passed_checks="0"

  identity_hits="$(count_rule_ids '"RULE_ID":"ssh_|"RULE_ID":"filevault_recovery_key' )"
  persistence_hits="$(count_rule_ids '"RULE_ID":"persistence_|"RULE_ID":"login_item' )"
  network_hits="$(count_rule_ids '"RULE_ID":"network_|"RULE_ID":"remote_login|screen_sharing|remote_management|airdrop' )"
  application_hits="$(count_rule_ids '"RULE_ID":"application_|"RULE_ID":"browser_' )"
  os_security_hits="$(count_rule_ids '"RULE_ID":"gatekeeper_|"RULE_ID":"xprotect_|"RULE_ID":"mrt_|"RULE_ID":"filevault_|"RULE_ID":"sip_|"RULE_ID":"firewall_|"RULE_ID":"stealth_' )"
  configuration_hits="$(count_rule_ids '"RULE_ID":"remote_login|remote_management|screen_sharing|airdrop|login_item' )"
  credential_hits="$(count_rule_ids '"RULE_ID":"credential_' )"

  identity_score="$(score_component "$((identity_hits * 8))")"
  persistence_score="$(score_component "$((persistence_hits * 12))")"
  network_score="$(score_component "$((network_hits * 10))")"
  application_score="$(score_component "$((application_hits * 8))")"
  os_security_score="$(score_component "$((os_security_hits * 12))")"
  configuration_score="$(score_component "$((configuration_hits * 8))")"
  credential_score="$(score_component "$credential_penalty")"

  security_score="$((100 - score_total))"
  [ "$security_score" -lt 0 ] && security_score="0"

  health_level_value="$(health_level "$security_score")"
  health_class_value="$(health_class "$security_score")"

  abnormal_items="$((critical_risk + high_risk + medium_risk + low_risk))"
  normal_items="$((total_events > abnormal_items ? total_events - abnormal_items : 0))"

  overall_risk="$(overall_risk_from_score "$security_score")"
  device_health="$(device_health_from_score "$security_score")"

  if [ "$total_events" -eq 0 ]; then
    display_summary="No events were collected. Please check permissions."
  elif [ "$rules_matched" -eq 0 ]; then
    display_summary="Collected events successfully. No suspicious activity detected by current rules."
  else
    display_summary="Collected events successfully. Review the executive summary, top findings, and recommendations below."
  fi

  ai_tools_count="$((ai_tools_from_credentials + ai_rule_findings))"
  [ "$ai_tools_count" -lt 0 ] && ai_tools_count="0"

  risk_distribution_info="$(percentage "$info_risk" "$rules_matched")"
  risk_distribution_low="$(percentage "$low_risk" "$rules_matched")"
  risk_distribution_medium="$(percentage "$medium_risk" "$rules_matched")"
  risk_distribution_high="$(percentage "$high_risk" "$rules_matched")"

  score_reason_text="$score_breakdown_text"
  [ -n "$score_reason_text" ] || score_reason_text="0"
  score_reason_html="$score_breakdown_html"

  timeline_note="Collected $total_events events. Matched $rules_matched rules. Generated $rules_matched findings."

  cat > "$report_data_file" <<EOF
{"TITLE":"SDMon Security Assessment","SCAN_STATUS":"Scan completed successfully","SCAN_TIME":"$(json_escape "$scan_time")","SYSTEM_VERSION":"$(json_escape "$system_version")","HOST_NAME":"$(json_escape "$host_name")","CURRENT_USER":"$(json_escape "$current_user")","OS_VERSION":"$(json_escape "$os_version")","CPU":"$(json_escape "$cpu_value")","MEMORY":"$(json_escape "$memory_value")","SDMON_VERSION":"$(json_escape "$SDMON_VERSION")","ELAPSED_TIME":"$(json_escape "$ELAPSED_TIME")","SUMMARY":"$(json_escape "$display_summary")","DEVICE_HEALTH":"$(json_escape "$device_health")","HEALTH_LEVEL":"$(json_escape "$health_level_value")","HEALTH_CLASS":"$(json_escape "$health_class_value")","OVERALL_RISK":"$(json_escape "$overall_risk")","OVERALL_HEALTH":"$(json_escape "$health_level_value")","SECURITY_SCORE":"$security_score","IDENTITY_SCORE":"$identity_score","PERSISTENCE_SCORE":"$persistence_score","NETWORK_SCORE":"$network_score","APPLICATION_SCORE":"$application_score","OS_SECURITY_SCORE":"$os_security_score","CONFIGURATION_SCORE":"$configuration_score","CREDENTIAL_SCORE":"$credential_score","SCORE_REASONS":"$(json_escape "$score_reason_text")","SCORE_REASONS_HTML":"$(json_escape "$score_reason_html")","NORMAL_ITEMS":"$normal_items","ABNORMAL_ITEMS":"$abnormal_items","RECOMMENDED_ACTIONS":"$abnormal_items","RISK_SCORE":"$(json_escape "$risk_score")","CONFIDENCE":"$(json_escape "$confidence")","MATCHED_RULE":"$(json_escape "$top_rule")","TOP_FINDINGS_HTML":"$(json_escape "$top_findings_html")","TOP_FINDINGS_TEXT":"$(json_escape "$top_findings_text")","TOP_FINDINGS_COUNT":"$top_findings_count","RECOMMENDATIONS_HTML":"$(json_escape "$recommendations_html")","RECOMMENDATIONS_TEXT":"$(json_escape "$recommendations_text")","SCAN_ITEMS":"$sensors_executed","SENSORS_LOADED":"$sensors_loaded","SENSORS_EXECUTED":"$sensors_executed","TOTAL_EVENTS":"$total_events","PROCESS_EVENTS":"$process_events","NETWORK_EVENTS":"$network_events","LAUNCHD_EVENTS":"$launchd_events","SSH_KEY_EVENTS":"$ssh_key_events","SENSITIVE_FILE_EVENTS":"$sensitive_file_events","MACOS_SECURITY_EVENTS":"$macos_security_events","PERMISSION_EVENTS":"$permission_events","FILE_EVENTS":"$file_events","SYSTEM_EVENTS":"$system_events","CREDENTIAL_EVENTS":"$credential_events","CREDENTIAL_HIGH_RISK":"$credential_high","CREDENTIAL_MEDIUM_RISK":"$credential_medium","CREDENTIAL_LOW_RISK":"$credential_low","CREDENTIAL_SUMMARY":"$(json_escape "$credential_summary_cn")","CREDENTIAL_SUMMARY_EN":"$(json_escape "$credential_summary_en")","CREDENTIAL_ITEMS_HTML":"$(json_escape "$credential_items_html")","CREDENTIAL_ITEMS_TEXT":"$(json_escape "$credential_items_text")","RULES_LOADED":"$rules_loaded","RULES_EVALUATED":"$rules_evaluated","RULES_MATCHED":"$rules_matched","CRITICAL_RISK":"$critical_risk","HIGH_RISK":"$high_risk","MEDIUM_RISK":"$medium_risk","LOW_RISK":"$low_risk","INFO_RISK":"$info_risk","AI_TOOLS":"$ai_tools_count","CREDENTIAL_FINDINGS":"$credential_hits","PERSISTENCE_FINDINGS":"$persistence_findings","NETWORK_FINDINGS":"$network_findings","SENSITIVE_FILE_FINDINGS":"$sensitive_findings","BROWSER_FINDINGS":"$browser_findings","SYSTEM_FINDINGS":"$os_security_hits","RULE_MATCH_FINDINGS":"$rules_matched","RISK_DISTRIBUTION_INFO":"$risk_distribution_info","RISK_DISTRIBUTION_LOW":"$risk_distribution_low","RISK_DISTRIBUTION_MEDIUM":"$risk_distribution_medium","RISK_DISTRIBUTION_HIGH":"$risk_distribution_high","TOTAL_CHECKS":"$total_checks","PASSED_CHECKS":"$passed_checks","WARNING_CHECKS":"$warnings_count","CRITICAL_CHECKS":"$critical_checks","ENVIRONMENT_CHECK":"SUCCESS","PERMISSION_CHECK":"SUCCESS","SENSOR_COLLECTION":"$(status_for_sensor process)","RULE_RUNTIME":"SUCCESS","ANALYZER":"SUCCESS","REPORTER":"SUCCESS","TIMELINE_NOTE":"$(json_escape "$timeline_note")","TIMELINE_HTML":"$(json_escape "$timeline_html")","TIMELINE_TEXT":"$(json_escape "$timeline_text")","TIMELINE_COUNT":"$timeline_count"}
EOF
}

write_summary_txt() {
  report_json="$(sed -n '1p' "$1")"
  {
    printf '==============================\n'
    printf 'SDMon Security Assessment\n'
    printf '==============================\n'
    printf 'Security Score : %s /100\n' "$(json_get "$report_json" "SECURITY_SCORE")"
    printf 'Overall Risk   : %s\n' "$(json_get "$report_json" "OVERALL_RISK")"
    printf 'Health Level   : %s\n' "$(json_get "$report_json" "HEALTH_LEVEL")"
    printf 'Host Name      : %s\n' "$(json_get "$report_json" "HOST_NAME")"
    printf 'Scan Time      : %s\n' "$(json_get "$report_json" "SCAN_TIME")"
    printf '\nTop Findings\n'
    printf '%s\n' "$(json_get "$report_json" "TOP_FINDINGS_TEXT")"
    printf '\nRecommendation\n'
    printf '%s\n' "$(json_get "$report_json" "RECOMMENDATIONS_TEXT")"
    printf '\nSecurity Statistics\n'
    printf 'AI Tools             : %s\n' "$(json_get "$report_json" "AI_TOOLS")"
    printf 'Credential Findings  : %s\n' "$(json_get "$report_json" "CREDENTIAL_FINDINGS")"
    printf 'Persistence Findings : %s\n' "$(json_get "$report_json" "PERSISTENCE_FINDINGS")"
    printf 'Network Findings     : %s\n' "$(json_get "$report_json" "NETWORK_FINDINGS")"
    printf 'Sensitive File       : %s\n' "$(json_get "$report_json" "SENSITIVE_FILE_FINDINGS")"
    printf 'Browser Findings     : %s\n' "$(json_get "$report_json" "BROWSER_FINDINGS")"
    printf 'System Findings      : %s\n' "$(json_get "$report_json" "SYSTEM_FINDINGS")"
    printf 'Rule Match           : %s\n' "$(json_get "$report_json" "RULE_MATCH_FINDINGS")"
    printf 'Info / Low / Medium / High : %s / %s / %s / %s\n' \
      "$(json_get "$report_json" "INFO_RISK")" \
      "$(json_get "$report_json" "LOW_RISK")" \
      "$(json_get "$report_json" "MEDIUM_RISK")" \
      "$(json_get "$report_json" "HIGH_RISK")"
    printf '==============================\n'
  } > "$OUTPUT_DIR/summary.txt" || die "failed to write summary.txt"
}

write_timeline_txt() {
  report_json="$(sed -n '1p' "$1")"
  printf '%s\n' "$(json_get "$report_json" "TIMELINE_TEXT")" > "$OUTPUT_DIR/timeline.txt" || die "failed to write timeline.txt"
}

write_report_zip() {
  command -v zip >/dev/null 2>&1 || die "zip command is required"
  (
    cd "$OUTPUT_DIR" || exit 1
    zip -q "report.zip" report.html report.pdf report.json report.csv summary.txt timeline.txt
  ) || die "failed to create report.zip"
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --input)
      shift
      [[ $# -gt 0 ]] || die "--input requires a file path"
      INPUT_FILE="$1"
      ;;
    --output-dir)
      shift
      [[ $# -gt 0 ]] || die "--output-dir requires a directory path"
      OUTPUT_DIR="$1"
      ;;
    --events-file)
      shift
      [[ $# -gt 0 ]] || die "--events-file requires a file path"
      EVENTS_FILE="$1"
      ;;
    --rule-results-file)
      shift
      [[ $# -gt 0 ]] || die "--rule-results-file requires a file path"
      RULE_RESULTS_FILE="$1"
      ;;
    --sensor-status-file)
      shift
      [[ $# -gt 0 ]] || die "--sensor-status-file requires a file path"
      SENSOR_STATUS_FILE="$1"
      ;;
    --rules-dir)
      shift
      [[ $# -gt 0 ]] || die "--rules-dir requires a directory path"
      RULES_DIR="$1"
      ;;
    --elapsed-time)
      shift
      [[ $# -gt 0 ]] || die "--elapsed-time requires a value"
      ELAPSED_TIME="$1"
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    *)
      die "unexpected argument: $1"
      ;;
  esac
  shift
done

[[ -n "$INPUT_FILE" ]] || die "missing --input FILE"
[[ -n "$OUTPUT_DIR" ]] || die "missing --output-dir DIR"
[[ -f "$INPUT_FILE" ]] || die "input file does not exist: $INPUT_FILE"

mkdir -p "$OUTPUT_DIR" || die "failed to create output directory"

REPORT_DATA_FILE="$OUTPUT_DIR/report_data.json"
build_report_data "$REPORT_DATA_FILE"

bash "$SCRIPT_DIR/json_reporter.sh" --input "$REPORT_DATA_FILE" --output "$OUTPUT_DIR/report.json"
bash "$SCRIPT_DIR/html_reporter.sh" --input "$REPORT_DATA_FILE" --output "$OUTPUT_DIR/report.html" --template "$REPO_ROOT/templates/report.html"
bash "$SCRIPT_DIR/csv_reporter.sh" --input "$REPORT_DATA_FILE" --output "$OUTPUT_DIR/report.csv"
write_summary_txt "$REPORT_DATA_FILE"
write_timeline_txt "$REPORT_DATA_FILE"
bash "$SCRIPT_DIR/pdf_reporter.sh" --input-html "$OUTPUT_DIR/report.html" --output "$OUTPUT_DIR/report.pdf"
write_report_zip
