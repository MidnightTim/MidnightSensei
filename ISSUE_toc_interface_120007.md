# TOC Interface Bump — 120007 (Patch 12.0.7)

**Type:** Enhancement  
**Version:** 1.7.1  
**Date:** 06/16/2026

## Summary

Updated the TOC `## Interface:` version from `120005` to `120007` for compatibility with World of Warcraft patch 12.0.7.

## Context

WoW addons declare their compatible game version in the `.toc` file via `## Interface:`. When the game patches and the TOC interface number is behind, the addon is flagged as out-of-date in the addon list. No functional changes were made — this is a compatibility declaration only.

## Change

- `MidnightSensei.toc`: `## Interface: 120005` → `## Interface: 120007`
- `MidnightSensei.toc`: `## Version: 1.7.0` → `## Version: 1.7.1`
- `Core.lua`: version fallback updated to `"1.7.1"`
- `Core.CHANGELOG`: entry added for 1.7.1
