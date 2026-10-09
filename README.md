# OSCP Exam Coach

> *"Saddle up boys. We're headed for the brick wall."*

An interactive Bash exam companion that keeps you on pace, reminds you to take breaks, tracks your score, and delivers motivational nudges throughout the full **23 hours and 45 minutes** of the OSCP exam.

By Aaron "The Husky Hacker" Gaddis

---

## Features

- **Exam timer** — live elapsed/remaining countdown, color-coded as time runs low (green → yellow → red)
- **Target & score tracking** — add boxes as AD Set (40pts) or Standalone (20pts), mark user/root flags, running pass/fail scoreboard
- **Break reminders** — configurable interval (default 90 min), break timer with gentle nudges at 15 and 30 minutes
- **Progress check-ins** — asks how you're feeling and gives targeted coaching based on your answer
- **Timeline advisor** — phase-aware guidance based on hours elapsed and current score
- **Background alerts** — desktop notifications at key milestones (4h, 8h, halfway, final 45 min)
- **Session logging** — every event timestamped and saved to `~/.oscp-coach/`
- **20 rotating motivational quotes** — all Husky-flavored

## Requirements

- Bash 4.0+ (for associative arrays)
- A terminal with color support
- Optional: `notify-send` for desktop notifications (Linux)

## Installation

```bash
git clone https://github.com/TheHuskyHacker/oscp-exam-coach.git
cd oscp-exam-coach
chmod +x oscp-exam-coach.sh
```

## Usage

```bash
./oscp-exam-coach.sh
```

On launch, you'll be asked when your exam started — choose "right now" or enter how many minutes ago it began (useful if you forgot to start the coach immediately).

---

## Main Menu

The main screen shows your timer, break count, and current score at a glance.

| Key | Action |
|-----|--------|
| `1` | Add a target (IP/name, AD Set or Standalone) |
| `2` | Update a target (mark user/root flag, add notes) |
| `3` | View the full scoreboard |
| `4` | Take a break (starts break timer) |
| `5` | Progress check-in (how are you feeling?) |
| `6` | Timeline advisor (phase-aware coaching) |
| `7` | Random motivational quote |
| `8` | View session log |
| `9` | Change break reminder interval |
| `q` | End session (shows final summary) |

---

## Features In Detail

### Target Tracking

Add each exam box as you encounter it:

```
> 1
Enter target IP or name: 10.10.10.100
Target type:
  1) AD Set (40 pts)
  2) Standalone (20 pts)
Choose: 1

Added 10.10.10.100 as AD Set (40 pts)
```

When you capture a flag, update the target:

```
> 2
Select target to update:
  1) 10.10.10.100 (AD Set) — user: [ ]  root: [ ]
Choose target #: 1
  1) Got user flag
  2) Got root flag
  3) Add a note
Choose: 1

User flag captured on 10.10.10.100!
```

### Scoreboard

Live point tracking with pass/fail status:

```
━━━ SCORE BOARD ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  ✓ ✓  10.10.10.100 (AD Set) — 40/40 pts
  ✓ ✗  10.10.10.101 (Standalone) — 10/20 pts
  ✗ ✗  10.10.10.102 (Standalone) — 0/20 pts
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Total: 50 / 100 pts  (70 to pass)
  Need 20 more points to pass
```

**Scoring logic:**
- AD Set: 40 pts for full chain (root), 10 pts for user-only
- Standalone: 10 pts user + 10 pts root

### Break System

The coach nudges you every 90 minutes (configurable) to take a break. When you start one:

```
━━━ BREAK TIME ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  "Re-read the nmap. There's a port you glossed over."

  Break checklist:
  • Stand up and stretch
  • Drink water
  • Eat something if it's been 3+ hours
  • Look away from screen (20-20-20 rule)
  • Take a few deep breaths
  • Bathroom break if needed

  Timer running... Press Enter when you're back.
  Break duration: 00:07:23
```

- **15 min**: gentle reminder you've been away a while
- **30 min**: stronger nudge to get back in the fight

### Progress Check-ins

Asks how you're feeling and responds accordingly:

| Feeling | Response |
|---------|----------|
| **Crushing it** | Encouragement to keep momentum |
| **Stuck** | The R.A.N.C.H. reset — 8-step unsticking checklist |
| **Tired** | Offers to start a break immediately |
| **Frustrated** | Reset checklist: clean workspace, re-read notes, pick ONE thing |

### Timeline Advisor

Phase-aware coaching based on where you are in the exam:

| Phase | Hours | Guidance |
|-------|-------|----------|
| Early Game | 0–4 | Focus on AD set, get a foothold |
| Mid Game | 4–8 | AD should be wrapping up, pivot decision |
| Standalone Phase | 8–16 | 3–4 hours per box, stay methodical |
| Late Game | 16–20 | Focus on low-hanging fruit, user flags matter |
| Final Stretch | 20–23:45 | Screenshot everything, document your report |

### Background Alerts

Desktop notifications fire automatically at milestones:

- **4 hours** — AD foothold check
- **8 hours** — one third done, assess standalones
- **12 hours** — halfway point
- **16 hours** — 7:45 remaining
- **20 hours** — 3:45 left, final push
- **22 hours** — under 2 hours, wrap up and document
- **23 hours** — FINAL 45 MINUTES

### Session Log

Every action is timestamped and saved:

```
[00:00:00] 14:00:00 — EXAM SESSION STARTED
[00:05:23] 14:05:23 — TARGET ADDED: 10.10.10.100 (AD Set, 40pts)
[01:47:12] 15:47:12 — USER FLAG: 10.10.10.100
[02:15:00] 16:15:00 — BREAK STARTED (#1)
[02:25:33] 16:25:33 — BREAK ENDED (#1, duration: 00:10:33)
[03:00:00] 17:00:00 — CHECK-IN: Feeling good, making progress
[04:12:45] 18:12:45 — ROOT FLAG: 10.10.10.100
```

Logs are saved to `~/.oscp-coach/exam_YYYYMMDD_HHMMSS.log`.

---

## File Structure

```
~/.oscp-coach/
├── exam_20261015_140000.log    # Session 1
├── exam_20261115_090000.log    # Session 2 (retake)
└── ...
```

---

## Tips for Exam Day

1. **Start the coach before you start hacking** — launch it as soon as your VPN connects
2. **Add targets immediately** — register each box as you discover it
3. **Respect the break reminders** — a 10-minute break saves 30 minutes of staring
4. **Use the check-in honestly** — the "stuck" advice is real methodology, not fluff
5. **Keep it in a dedicated terminal** — one pane of your tmux/screen layout

### Recommended tmux Layout

```
┌─────────────────────┬─────────────────────┐
│                     │                     │
│   Main Terminal     │   Exam Coach        │
│   (hacking)         │   ./oscp-exam-      │
│                     │     coach.sh        │
│                     │                     │
├─────────────────────┼─────────────────────┤
│                     │                     │
│   Secondary         │   Notes / Cherry    │
│   Terminal          │   Tree / Obsidian   │
│                     │                     │
└─────────────────────┴─────────────────────┘
```

---

## Companion Tools

| File | Description |
|------|-------------|
| `oscp-exam-coach.sh` | This tool — exam timer & coach |
| `oscp-methodology-checklist.sh` | Interactive R.A.N.C.H. methodology checklist |
| `oscp-methodology-checklist.md` | Static Markdown version of the checklist |

---

## License

MIT

## Author

**Aaron "The Husky Hacker" Gaddis**
- GitHub: [@HackingHusky](https://github.com/HackingHusky)
- Blog: [husky-hacker-read.com](https://husky-hacker-read.com)
- YouTube: [@TheHuskeyHacker](https://youtube.com/@TheHuskeyHacker)
- Portfolio: [thehuskyhacker.com](https://thehuskyhacker.com)
