# Native finish review

Code-led review of the established native identity. No image comp or new brand was approved.
The owner asked for “less boring, but not too complicated.” Native system typography,
semantic surfaces, SF Symbols and standard navigation are intentional.

## First independent review

Disposition: **fix**. The reviewer inspected ten unmodified iOS 17.5 XCTest screenshots and
relevant code. TYPE, MATERIAL, GROUND, Local organization, search/source links and meeting
hierarchy matched the brief. Largest-text reflow was an accepted accessibility adaptation.

One material fix: dark-mode caption links used RGB(38,99,217) on RGB(28,28,30), measured at
3.13:1. Use the existing brighter dark accent for action text while preserving white-on-blue
filled-button contrast. Existing dark AccentColor RGB(96,165,250) yields 6.69:1 on that panel.

Scope limits: Following, Council action details, iOS 27 and hardware behavior were not in the
reviewer's initial inspected captures. The Calendar fixture screenshot is test evidence only.

## Post-fix verdict — November 25

The independent reviewer became unavailable due to its usage limit. The final scoring pass
was performed inline using Impeccable's degraded finish-reviewer procedure; this is not an
independent final approval. No native detector ran. This pass scores the existing findings,
not a new full-surface design review.

### verdict

- **Resolved — dark caption links:** `local-dark-services.png` shows the brighter adaptive
  accent on the dark panel. Root tint uses the existing dark asset; measured contrast is 6.69:1.
- **Resolved — capture completeness:** `local-welcome.png` and `redesign-map.png` show the
  status bar, native title, content, tabs and home indicator. The final Map capture has normal
  top safe-area placement; no speculative navigation/layout patch was applied.
- **Resolved — Following evidence:** `local-following.png` shows a retained DEBUG meeting,
  its date and following state, plus the explicit no-notifications explanation.
- No visual regressions identified in this fix batch. Council dispositions remain procedural
  where the official record is procedural, rather than being relabeled final approval.

### remaining

Clear for the scored visual fixes. Hardware behavior and newer-runtime automated results are
separate validation gates; see VALIDATION.md. The saved captures are raw simulator evidence.

**disposition: ship** — applies only to the scored visual fixes, not deployment or release.
