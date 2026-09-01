# pet-swipe backend spec (handoff doc)

This is the contract the iOS app's `API*Repository` implementations (`ios/PetSwipe/Sources/PetSwipe/Data/Repositories/`) are already built against. The backend doesn't exist yet — this document is what unblocks building it on the Ubuntu server, in a separate Claude Code session. The app currently runs entirely on an in-memory mock (`MockDataStore`) and can be pointed at this API later by switching `AppEnvironment(mode: .mock)` to `.live(baseURL:)` in `PetSwipeApp.swift` — no other app code should need to change if this contract is honored.

## Data sources this API needs to reconcile

Three kinds of pet listings, all served back to the app identically via `GET /pets`:
1. **Individual users** listing their own pet via `POST /pets` (app already sends these).
2. **Shelter/rescue organizations** — accounts that can post listings, possibly in bulk. Not designed yet; needs its own onboarding/verification flow and probably a bulk-import endpoint, but listings still land in the same `pets` table/shape.
3. **Petfinder public API sync** — this is entirely a backend concern. The iOS app never calls Petfinder directly or holds a Petfinder API key. The backend should run a scheduled job that pulls from Petfinder, de-duplicates, and normalizes into the `Pet` shape below, tagging `source.type = "petfinder"`.

## Auth

Simple token-based auth (JWT or opaque session token, your choice).

```
POST /auth/signup   { email, password, displayName } -> { token, user: User }
POST /auth/signin   { email, password }               -> { token, user: User }
```

All other endpoints require `Authorization: Bearer <token>`.

## Core resources

### Pet
```json
{
  "id": "uuid",
  "name": "string",
  "species": "dog | cat | other",
  "breed": ["string"],
  "ageCategory": "baby | young | adult | senior",
  "ageMonths": "int | null",
  "size": "small | medium | large | xlarge",
  "sex": "male | female | unknown",
  "temperamentTags": ["string"],
  "description": "string",
  "photoURLs": ["string"],
  "location": { "latitude": 0.0, "longitude": 0.0, "city": "string | null", "region": "string | null" },
  "distanceMiles": "double | null",
  "source": { "type": "individual | shelter | petfinder", "label": "string | null" },
  "listedBy": { "id": "uuid", "displayName": "string", "contactType": "individual | shelter" },
  "status": "available | pending | adopted",
  "createdAt": "ISO8601 date"
}
```
`distanceMiles` is server-computed relative to the requesting user's `lat`/`lng` query params and only populated on feed responses.

### User
```json
{ "id": "uuid", "email": "string", "displayName": "string", "location": { "latitude": 0.0, "longitude": 0.0 } | null, "createdAt": "ISO8601 date" }
```

### AdoptionPreferences
```json
{
  "species": ["dog", "cat"],
  "breeds": ["string"] | null,
  "ageCategories": ["baby", "young", "adult", "senior"],
  "sizes": ["small", "medium", "large", "xlarge"],
  "maxDistanceMiles": 25.0,
  "temperamentTags": ["string"] | null
}
```

### ChatThread / ChatMessage
```json
// ChatThread
{ "id": "uuid", "petID": "uuid", "participantUserID": "uuid", "listerID": "uuid", "createdAt": "ISO8601 date", "lastMessagePreview": "string | null", "lastMessageAt": "ISO8601 date | null" }

// ChatMessage
{ "id": "uuid", "threadID": "uuid", "senderID": "uuid", "body": "string", "sentAt": "ISO8601 date" }
```

## Endpoints implied by the app's repository protocols

```
GET   /pets?species=&ageCategories=&sizes=&breeds=&maxDistanceMiles=&lat=&lng=   -> [Pet]
GET   /pets/{id}                                                                  -> Pet
POST  /pets                          { ...Pet fields, id/createdAt server-set }   -> Pet
POST  /pets/{id}/swipe                { decision: "interested" | "passed" }       -> {} (any 2xx)
GET   /me/interests                                                               -> [Pet]   (pets the user swiped "interested" on)
GET   /me/listings                                                                -> [Pet]   (pets the current user has listed)
GET   /me/preferences                                                             -> AdoptionPreferences
PATCH /me/preferences                 AdoptionPreferences                         -> AdoptionPreferences

GET   /threads                                                                    -> [ChatThread]
POST  /threads                        { petID }                                   -> ChatThread  (finds-or-creates, mirrors app's fetchOrCreateThread)
GET   /threads/{id}/messages                                                      -> [ChatMessage]
POST  /threads/{id}/messages          { body }                                    -> ChatMessage
```

Notes for whoever builds this:
- `POST /pets/{id}/swipe` should exclude that pet from future `GET /pets` responses for that user (mirrors `MockPetRepository`'s swiped-pet filtering).
- `GET /pets` should sort by distance ascending when `lat`/`lng` are present, otherwise by `createdAt` descending (mirrors mock behavior).
- Pagination isn't specified yet — the mock re-fetches the full filtered set on each load. Add a `cursor`/`page` param when real data volume warrants it; the app's `loadMore()` in `SwipeDeckViewModel` will need a small follow-up change to use it instead of re-fetching everything.
- Petfinder sync, dedup, and normalization are entirely backend-owned — see "Data sources" above.
