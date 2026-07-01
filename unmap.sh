#!/data/data/com.termux/files/usr/bin/bash
###############################################################################
#  ULTIMATE NMAP TOOL  (UNMAP)  ·  v2.0  "TANK EDITION"
#  A professional, analyst-grade menu console around nmap.
#
#  Covers: host discovery, every TCP/UDP/SCTP scan type, service & OS finger-
#  printing, full NSE engine, firewall/IDS evasion, spoofing, IPv6, web enum,
#  timing/performance tuning, and multi-format reporting (TXT/XML/GREP/HTML).
#
#  >>> FOR AUTHORIZED SECURITY TESTING / CTF / EDUCATION ONLY <<<
#  Only scan systems you own or have explicit written permission to test.
###############################################################################

# ------------------------------- Colors ------------------------------------
R="\033[1;31m"; G="\033[1;32m"; Y="\033[1;33m"; B="\033[1;34m"
C="\033[1;36m"; W="\033[1;37m"; M="\033[1;35m"; D="\033[2;37m"; N="\033[0m"

# ------------------------------- Paths -------------------------------------
BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RESULTS_DIR="$BASE_DIR/results"
LOG_FILE="$BASE_DIR/unmap.log"
mkdir -p "$RESULTS_DIR"

# --------------------------- Global scan state -----------------------------
TARGET=""            # current target(s)
PORTS=""             # current port spec (empty = nmap default)
TIMING="-T4"         # timing template
EXTRA=""             # evasion / extra flags carried into scans
IPV6=""              # "-6" when IPv6 mode on
SUDO=""              # "sudo" prefix when privileged scans requested

# ------------------------------- Helpers -----------------------------------
pause()  { echo; read -rp "$(echo -e "${Y}Press ENTER to continue...${N}")"; }
line()   { echo -e "${B}════════════════════════════════════════════════════════${N}"; }
sline()  { echo -e "${D}────────────────────────────────────────────────────────${N}"; }
log()    { echo "[$(date '+%F %T')] $*" >> "$LOG_FILE"; }

banner() {
  clear
  echo -e "${C}"
  echo "  ██╗   ██╗███╗   ██╗███╗   ███╗ █████╗ ██████╗ "
  echo "  ██║   ██║████╗  ██║████╗ ████║██╔══██╗██╔══██╗"
  echo "  ██║   ██║██╔██╗ ██║██╔████╔██║███████║██████╔╝"
  echo "  ██║   ██║██║╚██╗██║██║╚██╔╝██║██╔══██║██╔═══╝ "
  echo "  ╚██████╔╝██║ ╚████║██║ ╚═╝ ██║██║  ██║██║     "
  echo "   ╚═════╝ ╚═╝  ╚═══╝╚═╝     ╚═╝╚═╝  ╚═╝╚═╝     "
  echo -e "${N}${W}     ULTIMATE NMAP TOOL  ·  v2.0  TANK EDITION${N}"
  echo -e "${M}    Authorized security testing / CTF / education only${N}"
  line
}

# Show current session config bar
statusbar() {
  local nm="○ nmap missing"; command -v nmap >/dev/null 2>&1 && nm="● nmap $(nmap --version|head -1|awk '{print $3}')"
  local root="user"; [[ $(id -u) -eq 0 ]] && root="ROOT"
  echo -e " ${G}$nm${N} | ${W}priv:${N}$root${SUDO:+(+sudo)} | ${W}IPv6:${N}${IPV6:+on}${IPV6:-off}"
  echo -e " ${W}TARGET:${N} ${TARGET:-${R}<none>${N}}   ${W}PORTS:${N} ${PORTS:-default}   ${W}TIMING:${N} $TIMING"
  [[ -n "$EXTRA" ]] && echo -e " ${W}EXTRA :${N} ${Y}$EXTRA${N}"
  line
}

check_nmap() {
  if ! command -v nmap >/dev/null 2>&1; then
    echo -e "${R}[!] nmap not installed.${N}"
    read -rp "$(echo -e "${Y}Install now via pkg? [y/N]: ${N}")" a
    [[ "$a" =~ ^[Yy]$ ]] && pkg install -y nmap
    command -v nmap >/dev/null 2>&1 || return 1
  fi
  return 0
}

need_target() {
  if [[ -z "$TARGET" ]]; then
    echo -e "${R}[!] No target set. Use main menu option 'T' to set target first.${N}"
    return 1
  fi
  return 0
}

# Core scan runner: run_scan <label> <nmap-args...>
run_scan() {
  local label="$1"; shift
  check_nmap || { echo -e "${R}nmap unavailable.${N}"; return 1; }
  need_target || return 1
  local stamp base
  stamp="$(date +%Y%m%d_%H%M%S)"
  base="$RESULTS_DIR/$(echo "${label}_${TARGET}" | tr ' /:,' '____')_$stamp"

  # Assemble full command
  local cmd=( $SUDO nmap $IPV6 $TIMING $EXTRA "$@" )
  [[ -n "$PORTS" ]] && cmd+=( -p "$PORTS" )
  cmd+=( "$TARGET" -oA "$base" )   # -oA = normal + xml + grepable at once

  echo -e "${G}[*] Command :${N} ${cmd[*]}"
  echo -e "${G}[*] Outputs :${N} ${base}.{nmap,xml,gnmap}"
  sline
  "${cmd[@]}"
  local rc=$?
  sline
  if [[ $rc -eq 0 ]]; then
    echo -e "${G}[✓] Completed.${N} Saved: ${base}.nmap"
    log "OK  $label -> $base (${cmd[*]})"
    # Try to auto-build an HTML report if xsltproc is present
    if command -v xsltproc >/dev/null 2>&1 && [[ -f "${base}.xml" ]]; then
      xsltproc "${base}.xml" -o "${base}.html" 2>/dev/null && \
        echo -e "${G}[✓] HTML report:${N} ${base}.html"
    fi
  else
    echo -e "${R}[x] nmap exited with code $rc.${N}"
    log "ERR $label rc=$rc (${cmd[*]})"
  fi
}

# ===========================================================================
#  CONFIG MENU  (Target / Ports / Timing / IPv6 / Sudo / Evasion)
# ===========================================================================
set_target() {
  echo -e "${C}Examples: 192.168.1.1 | scanme.nmap.org | 10.0.0.0/24 | 10.0.0.1-50 | host1,host2${N}"
  read -rp "$(echo -e "${C}Target(s): ${N}")" t
  [[ -n "$t" ]] && TARGET="$t" && echo -e "${G}Target set:${N} $TARGET"
}
set_ports() {
  echo -e "${C}Examples: 80 | 22,80,443 | 1-1000 | - (all 65535) | U:53,T:22 | (blank=default)${N}"
  read -rp "$(echo -e "${C}Ports: ${N}")" p
  PORTS="$p"; echo -e "${G}Ports set:${N} ${PORTS:-default}"
}
set_timing() {
  banner
  echo -e "${W}Timing template (higher = faster + noisier):${N}"
  echo "  0) -T0 Paranoid   1) -T1 Sneaky   2) -T2 Polite"
  echo "  3) -T3 Normal     4) -T4 Aggressive   5) -T5 Insane"
  read -rp "$(echo -e "${C}Choose 0-5: ${N}")" t
  case "$t" in 0|1|2|3|4|5) TIMING="-T$t"; echo -e "${G}Timing:${N} $TIMING";; *) echo -e "${R}Invalid.${N}";; esac
}
toggle_ipv6() { [[ -z "$IPV6" ]] && IPV6="-6" || IPV6=""; echo -e "${G}IPv6 mode:${N} ${IPV6:-off}"; }
toggle_sudo() {
  if [[ -z "$SUDO" ]]; then
    command -v sudo >/dev/null 2>&1 && SUDO="sudo" || SUDO="tsu"
    echo -e "${G}Privileged mode ON${N} (prefix: $SUDO). Needed for -sS/-sU/-O/raw packets."
  else SUDO=""; echo -e "${G}Privileged mode OFF${N}"; fi
}
clear_extra() { EXTRA=""; echo -e "${G}Extra/evasion flags cleared.${N}"; }

# ===========================================================================
#  1) HOST DISCOVERY
# ===========================================================================
menu_discovery() {
  while true; do
    banner; statusbar
    echo -e "${W} HOST DISCOVERY${N}"
    echo "  1) Ping sweep / list live hosts        (-sn)"
    echo "  2) No-ping (treat all as up)           (-Pn)"
    echo "  3) TCP SYN ping                        (-PS21,22,80,443)"
    echo "  4) TCP ACK ping                        (-PA80,443)"
    echo "  5) UDP ping                            (-PU53,161)"
    echo "  6) ICMP echo/timestamp/netmask ping    (-PE -PP -PM)"
    echo "  7) ARP scan (local LAN, very fast)     (-PR)"
    echo "  8) List scan (no packets, just list)   (-sL)"
    echo "  9) Reverse-DNS only                    (-sn -R)"
    echo -e "  ${R}0) Back${N}"; sline
    read -rp "$(echo -e "${Y}> ${N}")" c
    case "$c" in
      1) run_scan discovery_ping   -sn ;;
      2) run_scan discovery_noping -Pn -sn ;;
      3) run_scan discovery_synping -sn -PS21,22,80,443,3389 ;;
      4) run_scan discovery_ackping -sn -PA80,443 ;;
      5) run_scan discovery_udpping -sn -PU53,161,123 ;;
      6) run_scan discovery_icmp   -sn -PE -PP -PM ;;
      7) run_scan discovery_arp    -PR -sn ;;
      8) run_scan discovery_list   -sL ;;
      9) run_scan discovery_rdns   -sn -R ;;
      0) return ;; *) echo -e "${R}Invalid.${N}" ;;
    esac; pause
  done
}

# ===========================================================================
#  2) PORT SCAN TYPES
# ===========================================================================
menu_portscan() {
  while true; do
    banner; statusbar
    echo -e "${W} PORT SCAN TECHNIQUES${N}"
    echo "  1) TCP SYN / stealth   (-sS)  ${D}fast, needs root${N}"
    echo "  2) TCP Connect         (-sT)  ${D}no root needed${N}"
    echo "  3) UDP scan            (-sU)"
    echo "  4) TCP FIN             (-sF)  ${D}firewall evasion${N}"
    echo "  5) TCP NULL            (-sN)"
    echo "  6) TCP Xmas            (-sX)"
    echo "  7) TCP ACK (fw mapping)(-sA)"
    echo "  8) TCP Window          (-sW)"
    echo "  9) TCP Maimon          (-sM)"
    echo " 10) Custom TCP flags    (--scanflags)"
    echo " 11) SCTP INIT           (-sY)"
    echo " 12) SCTP COOKIE-ECHO    (-sZ)"
    echo " 13) IP protocol scan    (-sO)"
    echo " 14) Idle / zombie scan  (-sI)  ${D}stealthiest${N}"
    echo " 15) FTP bounce          (-b)"
    echo " 16) Fast top-100        (-F)"
    echo " 17) All 65535 ports     (-p-)"
    echo -e "  ${R}0) Back${N}"; sline
    read -rp "$(echo -e "${Y}> ${N}")" c
    case "$c" in
      1) run_scan syn        -sS ;;
      2) run_scan connect    -sT ;;
      3) run_scan udp        -sU ;;
      4) run_scan fin        -sF ;;
      5) run_scan null       -sN ;;
      6) run_scan xmas       -sX ;;
      7) run_scan ack        -sA ;;
      8) run_scan window     -sW ;;
      9) run_scan maimon     -sM ;;
      10) read -rp "scanflags (e.g. SYNACK,URGPSH): " f; run_scan flags -sS --scanflags "$f" ;;
      11) run_scan sctp_init -sY ;;
      12) run_scan sctp_echo -sZ ;;
      13) run_scan ipproto   -sO ;;
      14) read -rp "Zombie host IP: " z; run_scan idle -sI "$z" ;;
      15) read -rp "FTP relay host: " f; run_scan ftpbounce -b "$f" ;;
      16) run_scan top100    -F ;;
      17) run_scan allports  -p- ;;
      0) return ;; *) echo -e "${R}Invalid.${N}" ;;
    esac; pause
  done
}

# ===========================================================================
#  3) SERVICE / OS / FINGERPRINTING
# ===========================================================================
menu_enum() {
  while true; do
    banner; statusbar
    echo -e "${W} SERVICE / OS / ENUMERATION${N}"
    echo "  1) Service & version detection   (-sV)"
    echo "  2) Aggressive version (intensity 9) (-sV --version-intensity 9)"
    echo "  3) OS detection                  (-O)"
    echo "  4) OS + guess aggressively       (-O --osscan-guess)"
    echo "  5) Aggressive (OS+ver+script+trace)(-A)"
    echo "  6) Banner grab (NSE banner)      (--script banner)"
    echo "  7) Full fingerprint combo        (-sS -sV -O -A)"
    echo "  8) Traceroute                    (--traceroute)"
    echo -e "  ${R}0) Back${N}"; sline
    read -rp "$(echo -e "${Y}> ${N}")" c
    case "$c" in
      1) run_scan ver        -sV ;;
      2) run_scan ver_max    -sV --version-intensity 9 ;;
      3) run_scan os         -O ;;
      4) run_scan os_guess   -O --osscan-guess ;;
      5) run_scan aggressive -A ;;
      6) run_scan banner     -sV --script=banner ;;
      7) run_scan fullprint  -sS -sV -O -A ;;
      8) run_scan trace      --traceroute ;;
      0) return ;; *) echo -e "${R}Invalid.${N}" ;;
    esac; pause
  done
}

# ===========================================================================
#  4) NSE SCRIPT ENGINE
# ===========================================================================
menu_nse() {
  while true; do
    banner; statusbar
    echo -e "${W} NSE SCRIPT ENGINE${N}"
    echo "  1) default scripts        (-sC / --script=default)"
    echo "  2) vuln  (find vulns)     (--script vuln)"
    echo "  3) safe                   (--script safe)"
    echo "  4) discovery              (--script discovery)"
    echo "  5) auth                   (--script auth)"
    echo "  6) brute (login brute)    (--script brute)"
    echo "  7) malware / backdoor     (--script malware)"
    echo "  8) exploit                (--script exploit)"
    echo "  9) dos  ${D}(careful!)${N}      (--script dos)"
    echo " 10) Run a SPECIFIC script  (e.g. http-title)"
    echo " 11) Run a script CATEGORY combo (comma list)"
    echo " 12) Search installed scripts (--script-help)"
    echo -e "  ${R}0) Back${N}"; sline
    read -rp "$(echo -e "${Y}> ${N}")" c
    case "$c" in
      1) run_scan nse_default  -sC ;;
      2) run_scan nse_vuln     -sV --script vuln ;;
      3) run_scan nse_safe     --script safe ;;
      4) run_scan nse_disc     --script discovery ;;
      5) run_scan nse_auth     --script auth ;;
      6) run_scan nse_brute    --script brute ;;
      7) run_scan nse_malware  --script malware ;;
      8) run_scan nse_exploit  --script exploit ;;
      9) echo -e "${R}DoS scripts can crash the target. Only on authorized lab systems.${N}"
         read -rp "Type YES to continue: " y; [[ "$y" == "YES" ]] && run_scan nse_dos --script dos ;;
      10) read -rp "script name(s) (comma ok): " s; run_scan nse_custom --script "$s" ;;
      11) read -rp "categories (e.g. vuln,exploit,auth): " s; run_scan nse_cats --script "$s" ;;
      12) read -rp "search term: " s; nmap --script-help "$s" 2>&1 | ${PAGER:-cat} ;;
      0) return ;; *) echo -e "${R}Invalid.${N}" ;;
    esac; pause
  done
}

# ===========================================================================
#  5) FIREWALL / IDS EVASION & SPOOFING
# ===========================================================================
menu_evasion() {
  while true; do
    banner; statusbar
    echo -e "${W} FIREWALL / IDS EVASION & SPOOFING${N}  ${D}(sets EXTRA flags)${N}"
    echo "  1) Fragment packets            (-f)"
    echo "  2) Fragment MTU (custom)       (--mtu N)"
    echo "  3) Decoy scan                  (-D ...)"
    echo "  4) Spoof source IP             (-S ip)"
    echo "  5) Spoof source MAC            (--spoof-mac)"
    echo "  6) Custom source port          (-g / --source-port)"
    echo "  7) Append random data bytes    (--data-length N)"
    echo "  8) Bad checksum                (--badsum)"
    echo "  9) Randomize target order      (--randomize-hosts)"
    echo " 10) Set network interface       (-e iface)"
    echo " 11) Slow/max stealth combo      (-T1 -f -D RND:5)"
    echo -e "  ${G}S) SHOW current EXTRA   ${Y}C) CLEAR EXTRA${N}"
    echo -e "  ${R}0) Back${N}"; sline
    read -rp "$(echo -e "${Y}> ${N}")" c
    case "$c" in
      1) EXTRA+=" -f" ;;
      2) read -rp "MTU (multiple of 8): " m; EXTRA+=" --mtu $m" ;;
      3) echo "Use RND:10 for 10 random decoys, or ip1,ip2,ME"; read -rp "decoys: " d; EXTRA+=" -D $d" ;;
      4) read -rp "spoof source IP: " s; EXTRA+=" -S $s"; echo -e "${Y}Note: usually needs -e iface & -Pn${N}" ;;
      5) echo "Use 0 (random), a vendor like Apple, or full MAC"; read -rp "mac: " m; EXTRA+=" --spoof-mac $m" ;;
      6) read -rp "source port: " p; EXTRA+=" --source-port $p" ;;
      7) read -rp "data length bytes: " l; EXTRA+=" --data-length $l" ;;
      8) EXTRA+=" --badsum" ;;
      9) EXTRA+=" --randomize-hosts" ;;
      10) read -rp "interface (e.g. wlan0): " i; EXTRA+=" -e $i" ;;
      11) EXTRA+=" -f -D RND:5"; TIMING="-T1" ;;
      S|s) echo -e "${G}EXTRA:${N} ${EXTRA:-<empty>}" ;;
      C|c) clear_extra ;;
      0) return ;; *) echo -e "${R}Invalid.${N}" ;;
    esac
    [[ "$c" =~ ^([1-9]|1[01])$ ]] && echo -e "${G}Added.${N} EXTRA now:${Y}$EXTRA${N}"
    pause
  done
}

# ===========================================================================
#  6) WEB / SPECIALIZED
# ===========================================================================
menu_web() {
  while true; do
    banner; statusbar
    echo -e "${W} WEB & SPECIALIZED ENUMERATION${N}"
    echo "  1) HTTP recon combo (title,headers,methods,enum)"
    echo "  2) HTTP directory brute (http-enum)"
    echo "  3) Web vuln scripts (http-*vuln*)"
    echo "  4) SSL/TLS ciphers & certs (ssl-enum-ciphers)"
    echo "  5) DNS brute subdomains (dns-brute)"
    echo "  6) SMB enumeration (smb-enum-*, smb-os-discovery)"
    echo "  7) SMB vuln (ms17-010 etc.)"
    echo "  8) SNMP enumeration"
    echo "  9) FTP anon + vsftpd backdoor check"
    echo " 10) Full web app sweep (-p80,443,8080,8443 combo)"
    echo -e "  ${R}0) Back${N}"; sline
    read -rp "$(echo -e "${Y}> ${N}")" c
    case "$c" in
      1) run_scan web_recon -sV --script "http-title,http-headers,http-methods,http-enum" ;;
      2) run_scan web_enum  --script http-enum ;;
      3) run_scan web_vuln  -sV --script "http-*vuln*" ;;
      4) run_scan ssl       --script ssl-enum-ciphers,ssl-cert ;;
      5) read -rp "domain: " d; TARGET="$d"; run_scan dnsbrute --script dns-brute ;;
      6) run_scan smb_enum  --script "smb-os-discovery,smb-enum-shares,smb-enum-users" -p445 ;;
      7) run_scan smb_vuln  --script "smb-vuln-ms17-010,smb-vuln-ms08-067" -p445 ;;
      8) run_scan snmp      -sU --script "snmp-info,snmp-sysdescr" -p161 ;;
      9) run_scan ftp       --script "ftp-anon,ftp-vsftpd-backdoor" -p21 ;;
      10) PORTS="80,443,8080,8443"; run_scan webfull -sV --script "http-title,http-enum,ssl-cert" ;;
      0) return ;; *) echo -e "${R}Invalid.${N}" ;;
    esac; pause
  done
}

# ===========================================================================
#  7) PROFILES  (one-click pro workflows)
# ===========================================================================
menu_profiles() {
  while true; do
    banner; statusbar
    echo -e "${W} SCAN PROFILES (one-click workflows)${N}"
    echo "  1) FAST      quick top-ports + version   (-F -sV)"
    echo "  2) STANDARD  default+version+OS+scripts  (-sS -sV -O -sC)"
    echo "  3) DEEP      all ports + full scripts     (-p- -sV -sC -O)"
    echo "  4) VULN HUNT version + vuln NSE           (-sV --script vuln)"
    echo "  5) STEALTH   slow + fragmented + decoys   (-sS -T1 -f -D RND:5)"
    echo "  6) NETWORK MAP  discover + light scan /24"
    echo "  7) PENTEST FULL everything (loud, thorough)"
    echo -e "  ${R}0) Back${N}"; sline
    read -rp "$(echo -e "${Y}> ${N}")" c
    case "$c" in
      1) run_scan prof_fast     -F -sV ;;
      2) run_scan prof_standard -sS -sV -O -sC ;;
      3) PORTS="-"; run_scan prof_deep -sV -sC -O ;;
      4) run_scan prof_vuln     -sV --script vuln ;;
      5) run_scan prof_stealth  -sS -T1 -f -D RND:5 ;;
      6) run_scan prof_netmap   -sn --traceroute ;;
      7) PORTS="-"; run_scan prof_pentest -sS -sU -sV -O -sC --script "default,vuln" -A ;;
      0) return ;; *) echo -e "${R}Invalid.${N}" ;;
    esac; pause
  done
}

# ===========================================================================
#  8) REPORTS & TOOLS
# ===========================================================================
menu_reports() {
  while true; do
    banner
    echo -e "${W} REPORTS & TOOLS${N}"
    echo -e "  Saved in: ${C}$RESULTS_DIR${N}"; sline
    echo "  1) List saved scans"
    echo "  2) View a saved .nmap report"
    echo "  3) Build HTML report from an XML scan"
    echo "  4) Grep open ports across all scans"
    echo "  5) Show activity log"
    echo "  6) Delete ALL saved results"
    echo "  7) Custom raw nmap command"
    echo "  8) Install / update nmap (+xsltproc for HTML)"
    echo -e "  ${R}0) Back${N}"; sline
    read -rp "$(echo -e "${Y}> ${N}")" c
    case "$c" in
      1) ls -1t "$RESULTS_DIR" 2>/dev/null | nl -w2 -s') ' ;;
      2) ls -1t "$RESULTS_DIR"/*.nmap 2>/dev/null | nl -w2 -s') '
         read -rp "number: " n; f="$(ls -1t "$RESULTS_DIR"/*.nmap 2>/dev/null | sed -n "${n}p")"
         [[ -f "$f" ]] && ${PAGER:-cat} "$f" || echo -e "${R}Not found.${N}" ;;
      3) ls -1t "$RESULTS_DIR"/*.xml 2>/dev/null | nl -w2 -s') '
         read -rp "number: " n; f="$(ls -1t "$RESULTS_DIR"/*.xml 2>/dev/null | sed -n "${n}p")"
         if [[ -f "$f" ]] && command -v xsltproc >/dev/null 2>&1; then
           xsltproc "$f" -o "${f%.xml}.html" && echo -e "${G}HTML:${N} ${f%.xml}.html"
         else echo -e "${R}Need xsltproc (option 8) and a valid file.${N}"; fi ;;
      4) grep -H "open" "$RESULTS_DIR"/*.nmap 2>/dev/null | grep -vi "filtered" | sort -u || echo "none" ;;
      5) [[ -f "$LOG_FILE" ]] && ${PAGER:-cat} "$LOG_FILE" || echo "no log yet" ;;
      6) read -rp "Type DELETE to confirm: " y; [[ "$y" == "DELETE" ]] && rm -f "$RESULTS_DIR"/* && echo -e "${G}Cleared.${N}" ;;
      7) echo -e "${Y}Enter nmap args only (target auto-appended if set). Do NOT type 'nmap'.${N}"
         read -rp "nmap " a; [[ -n "$a" ]] && run_scan custom $a ;;
      8) pkg install -y nmap libxslt && echo -e "${G}Done.${N} $(nmap --version|head -1)" ;;
      0) return ;; *) echo -e "${R}Invalid.${N}" ;;
    esac; pause
  done
}

# ===========================================================================
#  MAIN MENU
# ===========================================================================
main_menu() {
  banner; statusbar
  echo -e "${W} MAIN MENU${N}"
  echo -e "   ${G}1${N}) Host Discovery"
  echo -e "   ${G}2${N}) Port Scan Techniques"
  echo -e "   ${G}3${N}) Service / OS / Enumeration"
  echo -e "   ${G}4${N}) NSE Script Engine"
  echo -e "   ${G}5${N}) Firewall / IDS Evasion & Spoofing"
  echo -e "   ${G}6${N}) Web & Specialized Enumeration"
  echo -e "   ${G}7${N}) Scan Profiles (one-click)"
  echo -e "   ${G}8${N}) Reports & Tools"
  sline
  echo -e "  ${C}T${N}) Set Target     ${C}P${N}) Set Ports     ${C}M${N}) Timing"
  echo -e "  ${C}6${N}→IPv6 toggle: ${C}V${N})    ${C}R${N}) Root/sudo toggle   ${C}X${N}) Clear evasion"
  echo -e "   ${R}0${N}) Exit"
  sline
  read -rp "$(echo -e "${Y}Choose: ${N}")" MC
}

# ------------------------------- Loop --------------------------------------
[[ ! -f "$LOG_FILE" ]] && log "UNMAP started"
while true; do
  main_menu
  case "$MC" in
    1) menu_discovery ;;
    2) menu_portscan ;;
    3) menu_enum ;;
    4) menu_nse ;;
    5) menu_evasion ;;
    6) menu_web ;;
    7) menu_profiles ;;
    8) menu_reports ;;
    T|t) set_target; pause ;;
    P|p) set_ports; pause ;;
    M|m) set_timing; pause ;;
    V|v) toggle_ipv6; pause ;;
    R|r) toggle_sudo; pause ;;
    X|x) clear_extra; pause ;;
    0) echo -e "${G}Bye! Scan only what you're authorized to. Stay ethical.${N}"; exit 0 ;;
    *) echo -e "${R}Invalid option.${N}"; pause ;;
  esac
done
