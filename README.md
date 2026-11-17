@"
# Tower of Hanoi - Sakura

A Tower of Hanoi game with a Prolog solver. The server is written in SWI-Prolog and the interface is HTML/JavaScript. Prolog solves the puzzle from any peg to any peg, which powers the Hint and Auto Play buttons.

**Play it online:** https://tower-of-hanoi-2-aen3.onrender.com

The free hosting plan sleeps when idle, so the first load may take 30 to 60 seconds.

## Features
- 4 difficulty modes: Easy, Hard, Difficult, Expert
- Hint and Auto Play powered by Prolog
- Undo, Restart, Pause, and a move/time counter

## Run locally
1. Install SWI-Prolog.
2. Run: ``swipl towerofhanoiSakura.pl``
3. Open http://localhost:8080

## Tech
SWI-Prolog (HTTP server and solver), JavaScript (UI), Docker, Render (hosting)
"@ | Set-Content -Path README.md -Encoding utf8

