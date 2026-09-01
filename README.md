# Tailswipe

A free, non-profit Tinder-style pet adoption app. Set your preferences (species, breed, age,
size, distance) and swipe through adoptable pets — right swipe (or "super interest" swipe-up)
opens a chat with the pet's shelter or owner, left swipe passes.

Native iOS (Swift/SwiftUI) client + a Node/Express/Postgres backend, deployed and live at
`https://api.tailswipe.app`. Android is a planned future port once the iOS app is validated.

## Repo layout

```
ios/Tailswipe/
  project.yml                  # XcodeGen spec
  Sources/Tailswipe/
    App/                       # App entry point, DI seam (mock vs live), session state,
                                # AppDelegate (push notification device-token registration)
    Models/                    # Pet, User, AdoptionPreferences, ChatThread/Message, etc.
    Data/
      Repositories/            # PetRepository/UserRepository/ChatRepository protocols
                                # + Mock* (in-memory demo data) and API* (talks to the backend)
      Networking/               # APIClient, APIEndpoint, ChatSocketService (WebSocket chat)
      Location/                 # LocationService protocol + CoreLocation/mock impls
      MockData/                 # In-memory data store + seeded sample pets (demo mode)
    ViewModels/                 # One per screen family, MVVM
    Views/                     # SwipeDeck, Onboarding, Interests, Chat, Profile, ListPet, Auth
  Tests/TailswipeTests/        # Unit tests for mock filtering/sorting and swipe decisions

backend/
  src/
    routes/                    # auth, pets, me, threads, uploads
    server.js                  # Express app + WebSocket server (chat)
    push.js                    # APNs push notifications (needs a paid Apple Developer
                                # account to actually enable — see below)
    mailer.js                  # SMTP email verification codes
  migrations/                  # Plain SQL, applied in order by `npm run migrate`

docs/BACKEND_SPEC.md           # Data model + endpoint contract the iOS client is built against
```

## Running the iOS app (on a Mac)

The project was built without Xcode installed locally, so it uses
[XcodeGen](https://github.com/yonaskolb/XcodeGen) to generate the `.xcodeproj` rather than
committing a hand-crafted one.

```sh
brew install xcodegen
cd ios/Tailswipe
xcodegen generate
open Tailswipe.xcodeproj
```

Build and run the `Tailswipe` scheme (iOS 17+). By default it points at the live backend
(`https://api.tailswipe.app`) — tap **Try the Demo Account** on the sign-in screen for a
working seeded account, or sign up for real (email verification required).

To run fully offline against in-memory mock data instead, change `AppEnvironment(mode:)` in
`Sources/Tailswipe/App/TailswipeApp.swift` to `.mock`.

Run tests: `Cmd+U` in Xcode, or:
```sh
xcodebuild test -scheme Tailswipe -destination 'platform=iOS Simulator,name=iPhone 15'
```

## Running the backend

```sh
cd backend
cp .env.example .env   # fill in DATABASE_URL, JWT_SECRET, etc.
npm install
npm run migrate
npm run seed            # optional: same demo data the iOS mock mode uses
npm start
```

Requires PostgreSQL. See `.env.example` for every configurable value (SMTP for verification
emails, APNs for push, upload storage, rate limits).

## What's not built yet

- Android app (planned as a follow-up port of this iOS app once it's validated)
- **Push notifications**: fully implemented (device token registration, APNs sender, triggers
  on new messages/matches/requests) but dormant — Apple does not allow the Push Notifications
  capability on a free "Personal Team" account at all, so this needs a paid Apple Developer
  Program membership before it can be enabled.
- Petfinder sync / shelter bulk-upload tooling (see `docs/BACKEND_SPEC.md`)
