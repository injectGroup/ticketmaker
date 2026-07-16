# Project metadata (S48ODI73lfsZJSn8Kke2)

Structured JSON here syncs with Firestore subcollections `epics`, `phases`, and `sprints` under `projects/S48ODI73lfsZJSn8Kke2`.

Files (each optional for push — absent means "do not touch this subcollection"):

- **epics.json** → `projects/{id}/epics`
- **phases.json** → `projects/{id}/phases`
- **sprints.json** → `projects/{id}/sprints`

Schema examples:

- **epics.json:** `[{ "id": "...", "name": "...", "description": "", "status": "planning"|"active"|"completed", "wbsCode": "1" }]`
- **phases.json:** `[{ "id": "...", "title": "...", "description": "", "status": "planned"|"active"|"completed", "docPath": "", "planMarkdown": "", "sortOrder": 0 }]`
- **sprints.json:** `[{ "id": "...", "title": "...", "goal": "", "startDate": "YYYY-MM-DD", "endDate": "YYYY-MM-DD", "status": "planned"|"active"|"completed" }]`

Markdown elsewhere under `docs/` does **not** populate these files. Use **bidirectional** sync in `.taskmanager/sync.json` or push scripts if repo-first.

See **docs/developers/PROJECT_LAYOUT_AND_BOOTSTRAP.md** and **docs/developers/SYNC_LOCAL_AND_FIRESTORE.md**.
