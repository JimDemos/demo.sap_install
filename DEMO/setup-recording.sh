#!/usr/bin/env bash
# setup-recording.sh
# Creates the tmux multiscreen layout for the kpatch demo recording.
# Run this on the bastion or recording host before starting OBS.
#
# Layout:
#   +---------------------------+------------------+
#   |                           |                  |
#   |   PANE 1: main terminal   |  PANE 2: watch   |
#   |   (AAP commands, kpatch)  |  (uptime/status) |
#   |                           |                  |
#   +---------------------------+------------------+
#   |                           |                  |
#   |   PANE 3: before report   |  PANE 4: after   |
#   |   (w3m or lynx)           |  report          |
#   |                           |                  |
#   +---------------------------+------------------+

SESSION="kpatch-demo"
REPORT_DIR="/tmp/oscap-demo"
TARGET="hana-sdmhr2"   # or whatever your target host is

# Kill existing session if running
tmux kill-session -t "$SESSION" 2>/dev/null

# Create session with 4 panes
tmux new-session -d -s "$SESSION" -x 220 -y 50

# Split horizontally (top/bottom)
tmux split-window -v -t "$SESSION:0"

# Split each half vertically (left/right)
tmux split-window -h -t "$SESSION:0.0"
tmux split-window -h -t "$SESSION:0.2"

# Set pane titles
tmux select-pane -t "$SESSION:0.0" -T "COMMANDS"
tmux select-pane -t "$SESSION:0.1" -T "STATUS WATCH"
tmux select-pane -t "$SESSION:0.2" -T "BEFORE REPORT"
tmux select-pane -t "$SESSION:0.3" -T "AFTER REPORT"

# Pane 1 (top-left): main terminal — cursor starts here
tmux send-keys -t "$SESSION:0.0" "echo '=== kpatch demo — main terminal ===' && uname -r" Enter

# Pane 2 (top-right): live status watch
tmux send-keys -t "$SESSION:0.1" \
  "watch -n2 'echo \"=== SYSTEM STATE ===\"; uname -r; echo; uptime; echo; kpatch list 2>/dev/null || echo kpatch: not installed'" Enter

# Pane 3 (bottom-left): before report placeholder
tmux send-keys -t "$SESSION:0.2" \
  "echo 'BEFORE report will appear here after step 1' && echo 'File: $REPORT_DIR/${TARGET}-report-before.html'" Enter

# Pane 4 (bottom-right): after report placeholder
tmux send-keys -t "$SESSION:0.3" \
  "echo 'AFTER report will appear here after step 4' && echo 'File: $REPORT_DIR/${TARGET}-report-after.html'" Enter

# Focus main pane
tmux select-pane -t "$SESSION:0.0"

# Attach
echo ""
echo "Recording layout ready. Attach with:"
echo "  tmux attach -t $SESSION"
echo ""
echo "When reports are ready, open them in panes 3/4 with:"
echo "  w3m $REPORT_DIR/${TARGET}-report-before.html   # in pane 3"
echo "  w3m $REPORT_DIR/${TARGET}-report-after.html    # in pane 4"
echo ""
tmux attach -t "$SESSION"
