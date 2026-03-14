# TeenWorkly Release Smoke Test Checklist

Run this before each production deploy. Keep it quick (about 10-15 minutes).

## 0) Build + Deploy Sanity

- [ ] `flutter analyze` passes
- [ ] `flutter build web` (or target build) succeeds
- [ ] If backend changed: deploy rules/functions first
  - [ ] `firebase deploy --only firestore:rules`
  - [ ] `firebase deploy --only functions`
- [ ] Deploy hosting/app build succeeds

## 1) Auth

- [ ] Email/password login works
- [ ] Logout works
- [ ] Google sign-in works (single prompt, no cancel loop)
- [ ] Guest is redirected from protected pages (`dashboard`, `post job`, `post service`, `settings`)

## 2) Jobs (Apply Flow)

- [ ] Post a job successfully
- [ ] Job appears in `Find a Job`
- [ ] Apply to a job works when GPS is enabled
- [ ] Apply is blocked with clear error when GPS is off/denied
- [ ] Applied/open status colors render correctly

## 3) Messaging

- [ ] Open conversation and send a message
- [ ] Lazy conversation creation works (only created on first send)
- [ ] Pre-hire applicant limit blocks after 5 messages
- [ ] Limit unlocks after poster sends one reply
- [ ] For job/service chats, message send is blocked if GPS is not recently verified

## 4) Post Service

- [ ] Service post succeeds with required fields
- [ ] Location is locked to profile/home location as expected
- [ ] Work radius selection is saved correctly
- [ ] Editing existing service works

## 5) Huddle

- [ ] Create post works
- [ ] Reply works
- [ ] Report/hide/block controls are visible and functional
- [ ] "New!" badge clears after opening Huddle

## 6) Settings + Theme

- [ ] Settings page opens for logged-in users
- [ ] Guest users are redirected from Settings
- [ ] Theme toggle works (`light/dark/system`)
- [ ] Theme preference persists after closing and reopening

## 7) Map + Focus

- [ ] "Open in map" from job detail centers on that job (no white screen jump)
- [ ] Manual distance input works (and slider steps by 1km)
- [ ] Editable "Your location" chip updates map results
- [ ] Map markers/colors match status rules (open/applied/focused)

## 8) Quick Regression Spot Check (Mobile)

- [ ] `Find a Job` and `Dashboard` are usable on narrow screens (< 400px)
- [ ] No major text overlap in cards (ellipsis appears where needed)
- [ ] Chat input autofocus + tap-to-focus still works

---

If any checkbox fails, stop release, fix, and re-run only affected sections plus section 0.
