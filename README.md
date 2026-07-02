# ⚡ UNMAP — Ultimate Nmap Tool

**v2.0 · "TANK EDITION"**

A professional, analyst-grade menu console built around Nmap — designed for Termux and Linux terminals. No more memorizing flags: pick a category, pick a scan, and UNMAP builds and runs the command for you.

> 🔒 **For authorized security testing, CTF, and education only.** Only scan systems you own or have explicit written permission to test.

---

## ✨ Features

| Category | What it does |
|---|---|
| 🔍 **Host Discovery** | Find live hosts on any network before scanning ports |
| 🎯 **Port Scan Techniques** | Full range of TCP/UDP/SCTP scan types (SYN, Connect, ACK, and more) |
| 🧬 **Service / OS / Enumeration** | Fingerprint services, detect operating systems, pull version info |
| 🧩 **NSE Script Engine** | Run Nmap's scripting engine for vuln detection, brute force, and recon |
| 🥷 **Firewall / IDS Evasion & Spoofing** | Decoys, fragmentation, spoofed source IPs, custom MTU/timing |
| 🌐 **Web & Specialized Enumeration** | Targeted scans for web servers and specific services |
| ⚡ **One-Click Scan Profiles** | Common scan combos ready to fire with a single keypress |
| 📊 **Reports & Tools** | Auto-saves TXT + XML + Grepable output, converts to HTML reports |

**Also included:**
- 🎨 Colorized banner & live status bar (target / ports / timing / privilege / IPv6 state)
- 🌍 One-key IPv6 toggle
- 🔑 Root/sudo toggle for privileged scan types
- 🛡️ Confirmation prompts before destructive actions (e.g. DoS scripts, clearing results)
- 📁 Auto-organized results folder with timestamped filenames
- 📝 Persistent session log

---

## 📦 Requirements

- **Termux** (Android) or any Linux system with Bash
- [`nmap`](https://nmap.org/) — the tool will offer to install it for you if missing
- `xsltproc` (optional, for HTML report conversion)

---

## 🚀 Installation

```bash
git clone https://github.com/mdbassrza786-eng/Ultimate-nmap.git
cd Ultimate-nmap
chmod +x unmap.sh
./unmap.sh
```

---

## 🕹️ Usage

Launch the script and use the main menu to navigate:

```
1) Host Discovery
2) Port Scan Techniques
3) Service / OS / Enumeration
4) NSE Script Engine
5) Firewall / IDS Evasion & Spoofing
6) Web & Specialized Enumeration
7) Scan Profiles (one-click)
8) Reports & Tools

T) Set Target   P) Set Ports   M) Timing
V) IPv6 toggle  R) Root/sudo   X) Clear evasion flags
0) Exit
```

1. Press **T** to set your target (IP, hostname, or range)
2. Optionally set ports (**P**) and timing (**M**)
3. Pick a category and scan type
4. Results are automatically saved to the `results/` folder in `.nmap`, `.xml`, and `.gnmap` formats

---

## 📁 Output

Every scan is saved with a timestamped filename:

```
results/<scan-label>_<target>_<YYYYMMDD_HHMMSS>.{nmap,xml,gnmap}
```

Use the **Reports & Tools** menu to convert XML results into clean HTML reports.

---

## ⚠️ Disclaimer

This tool is intended strictly for **authorized penetration testing, CTF competitions, and educational purposes**. Scanning networks or systems without explicit permission is illegal in most jurisdictions. The author assumes no liability for misuse.

---

## 📄 License

