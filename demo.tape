# ===============================
#  Professional CLI Showcase
#  Author: monkeymonk
#  Project: alx
# ===============================

# -------- Output --------
Output demo.gif

# -------- Terminal Look --------
Set Shell "bash"
Set FontSize 18
Set Width 1200
Set Height 700
Set Theme "Dracula"
Set Padding 20
Set CursorBlink true

# Optional: for slower, more polished feel
Set TypingSpeed 80ms
Set Framerate 60

# Hidden setup: clean environment + prompt
Hide
Type `export PS1='$ '`
Enter
Type "export XDG_CONFIG_HOME=/tmp/alx-demo-vhs"
Enter
Type "rm -rf /tmp/alx-demo-vhs"
Enter
Type "export PATH=$PWD/bin:/usr/local/bin:/usr/bin:/bin"
Enter
Type "clear"
Enter
Sleep 500ms
Show

# -------- Intro Section --------
Sleep 500ms

# Big clean intro
Type `# alx - A modern CLI alias manager for your shell`
Enter
Sleep 800ms

# -------- Basic Usage --------
Type "alx --help"
Enter
Sleep 2000ms

# -------- Add Aliases --------
Type "alx add gs 'git status' --desc 'Git status' --tags git,core"
Enter
Sleep 500ms

Type "alx add gp 'git push' --desc 'Push to remote' --tags git"
Enter
Sleep 500ms

Type "alx add ll 'ls -la' --desc 'Long listing' --tags files,core"
Enter
Sleep 500ms

Type "alx add greet 'echo Hello from alx!' --desc 'Greeting' --tags demo"
Enter
Sleep 500ms

# -------- List Aliases --------
Type "alx list"
Enter
Sleep 2000ms

Type "alx list --table"
Enter
Sleep 3000ms

# -------- Search --------
Type "alx search git"
Enter
Sleep 2000ms

# -------- Show Details --------
Type "alx show gs"
Enter
Sleep 2500ms

# -------- Where --------
Type "alx where gs"
Enter
Sleep 2000ms

# -------- Export / Import Round-Trip --------
Type "alx export --shell"
Enter
Sleep 3000ms

Type "alx export --shell > /tmp/alx-export.sh"
Enter
Sleep 1000ms

Type "alx import /tmp/alx-export.sh --force"
Enter
Sleep 2000ms

# -------- Run --------
Type "alx run greet"
Enter
Sleep 2000ms

# -------- Doctor --------
Type "alx doctor"
Enter
Sleep 3000ms

# -------- Remove + Confirm --------
Type "alx remove greet"
Enter
Sleep 1500ms

Type "alx list --table"
Enter
Sleep 3000ms

# -------- Outro --------
Type `# Documentation: https://github.com/monkeymonk/alx`
Enter
Sleep 1500ms
