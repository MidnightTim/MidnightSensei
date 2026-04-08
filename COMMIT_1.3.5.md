feat: guild leaderboard sync, rank detection, and Midnight 12.0 fixes

Guild leaderboard sync now works end-to-end across all guild members regardless of rank. Officers now push their complete guild DB to all members on login, leaderboard open, and Refresh, while non-officers receive a fully populated leaderboard passively.

- Added officer Pull/Push leaderboard sync protocol
- Replaced unavailable Midnight 12.0 guild APIs with roster cache logic
- Fixed PUSHDATA duplicate row and self-skip bugs
- Fixed officer self-entry missing location data in PUSHDATA
- Fixed dungeon names bleeding into raid leaderboard tab
- Fixed delve boss name capture in Midnight 12.0
- Fixed leaderboard frame width and history panel text overflow
- Added debug inject commands for guild pipeline validation
- Added officerRankThreshold saved setting