# Play closed test: status and hand-off (updated 2026-10-24)

Written on MUKA (Surface) so the work can continue from another PC. Complements `docs/play_release_guide.md`.

## Where things stand

| Item | State (checked 2026-10-20) |
|------|----------------------------|
| App | Panduan Umrah, package `com.faeq.umrahmas`. Alpha track serves `1.1.0+3` until review ends. **`1.2.0+4` was tested on a real phone, uploaded to Alpha and submitted for review on 2026-10-24** (release "4 (1.2.0)", Publishing overview shows "Changes in review"; check it did not bounce after the quick checks) |
| New bundle | `build/app/outputs/bundle/release/app-release.aab`, 85.0 MB, 1.2.0+4. Gitignored; rebuild with `flutter build appbundle --release` (~10 min on `P:`) if missing. `flutter analyze` clean, 14 tests pass |
| Review | **Passed.** Publishing overview shows "Last published on October 19, 2026" (no "in review" banner); Dashboard ticks "Publish a closed testing release" |
| Closed track | "Closed testing - Alpha", release name `tadika`, active, 5 countries (MY, ID, SG, SA, TH) |
| Tester list | `closed1`, 15 Gmail accounts (the addresses live only in Play Console, see below) |
| Opted-in testers | **0** (Dashboard: "0 testers currently opted-in"), nobody has been sent the link yet |
| Production | Locked until **12+ testers stay opted in for 14 consecutive days** |
| Earliest production date | About 14 days after the 12th tester opts in |

## Opt-in links

Taken from Play Console > Closed testing - Alpha > Testers > "How testers join your test" (the console shows them only as "Copy link" buttons).

- **Web (send this one):** https://play.google.com/apps/testing/com.faeq.umrahmas
- **Android (Play Store page):** https://play.google.com/store/apps/details?id=com.faeq.umrahmas

The links never change, so people added to the list later use the same ones.

## Play Console access

- Developer ID `6825242996668375605`, app ID `4973153973617292523`, Alpha track ID `4699776071743671746`.
- **The console only loads under `/console/u/1/`** for this Google account. `/u/0/` redirects to "Creating a developer account"; do not create one.
- Dashboard: `https://play.google.com/console/u/1/developers/6825242996668375605/app/4973153973617292523/app-dashboard`
- Alpha track (tester list + links): `.../app/4973153973617292523/tracks/4699776071743671746?tab=testers`
- On 2026-10-20 Play showed a "New Play Console Terms of Service" page (oddly dated "by 30 May 2020") before the console; the user accepted it manually. Claude must not accept terms on the user's behalf.
- `.../tracks/closed-testing` threw "unexpected error 7C849FE5" once in browser automation; `.../closed-testing` (no `tracks/`) worked.

## Tester list (invitees)

**Not recorded in this file on purpose.** The 15 addresses are personal data and are not kept anywhere in this repo. To see or edit them: Alpha track > Testers tab > `closed1` > edit list. Add or remove people there at any time (limit 100 per list); new people use the same links. Anyone not on the list cannot opt in, and the Google account they open the link with must be the one on the list.

If you want them tracked here (who was invited, who opted in), add a private table below or keep it outside git.

## What "opted in" and "dropping out" mean

- **Opted in** = on the `closed1` list **and** tapped "Become a tester" on the web link while signed in with that account. Being on the list alone counts as 0.
- **14 days** = at least 12 testers opted in continuously; the clock starts when the count first reaches 12.
- **Drops out** if the tester leaves the test, uninstalls the app, switches or removes the Google account, or is removed from the list. Not opening the app, being offline or updating the app does not.
- Falling below 12 can reset the streak, so invite all 15 for a buffer of 3.

## Invite email (also saved as a Gmail draft)

A bilingual (Malay then English) draft named "Jemputan uji Panduan Umrah (Android)..." is in dominggo@gmail.com's Drafts, recipients blank. Put the 15 addresses in **Bcc**. Text:

> Assalamualaikum, thank you for helping test Panduan Umrah. Google needs at least 12 testers to stay opted in for 14 consecutive days before the app can be published.
>
> 1. On your Android phone sign into Google Play with the Gmail account I registered.
> 2. Open https://play.google.com/apps/testing/com.faeq.umrahmas
> 3. Tap "Become a tester", then "Download it on Google Play" and install.
>
> Please do not leave the test or uninstall the app during the 14 days, and open the app now and then (umrah and wida' flows). Fallback link: https://play.google.com/store/apps/details?id=com.faeq.umrahmas

## Next steps

Decision (2026-10-24): upload 1.2.0+4 to Alpha first, then send invites without waiting for its review. The 14-day clock counts opted-in testers, not app version, so testers auto-updating from +3 to +4 stay opted in.

1. [x] DONE 2026-10-24 (uploaded via Claude in Chrome, submitted for review): upload `app-release.aab` by hand to Alpha (Create new release; the file picker step is manual, 85 MB is too big for browser automation). Release notes (Malay): "Versi 1.2.0: auto-main doa berturutan, penjejakan GPS lebih stabil (skrin kekal hidup semasa perjalanan), eksport PDF tanpa internet, dan pelbagai pembaikan." Send to review.
2. [x] DONE 2026-10-24 (draft rewritten with clean links, recipients still blank): edit the Gmail invite draft: add a line that the app may update itself during the test (fine, stay opted in), and ask testers to try GPS tracking and auto-play as well as the umrah and wida' flows.
3. [ ] Send the invite email (Bcc the 15 testers; addresses only in Play Console `closed1`). Not sent as of 2026-10-24.
4. [ ] Check Dashboard "N testers currently opted-in" on day 2 and day 7; add testers to `closed1` if below 12 (keep a buffer of 3+).
5. [ ] When 12+ have been opted in for 14 consecutive days, Dashboard > **Apply for production access** (answer the questions about the closed test).
6. [ ] Submit a production release (build number above 4; manual `.aab` upload).
7. [ ] Then the other open items in `mine-proxmox` `docs/todo.md` under "Umrah Guide" (Firebase/AD_ID decision, icon set, screenshots, keystore backup).

## Notes for continuing in Claude in Chrome

- Use `/console/u/1/` URLs only. Claude must not accept Play terms on the user's behalf.
- Gmail draft: search Drafts for "Jemputan uji Panduan Umrah"; recipients are blank.
- Do not record tester addresses in this repo.
