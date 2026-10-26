# WindWise — UK wind forecast intelligence

WindWise is a first-version decision portal for a UK energy utility buying electricity in the day-ahead market. It answers two practical questions:

1. What national wind forecast was actually available when the buyer had to make the day-ahead decision?
2. How accurate was that forecast, in quantified MW terms, so the buyer can plan additional procurement or flexible thermal cover?

The pilot uses only national wind actuals and forecasts from Elexon BMRS. It deliberately excludes demand, prices, thermal availability, balancing costs, solar, and other external data.

## Challenge requirements covered

The supplied challenge asks for a React frontend and Python backend using Elexon data, Docker, and deployment to Vercel or Heroku. It asks for actual national wind generation from the Elexon `FUELHH` dataset, forecasted national wind generation from the `WINDFOR` dataset, and data relevant to purchase decisions in January 2026. It also asks for a public GitHub repository with an anonymous/random name, a README explaining the files and how to run the application, a deployed application link, an unlisted YouTube video with a customer pitch and technical walkthrough, and an incognito access check for submitted URLs.

This implementation satisfies the software, data, Docker, README, GitHub, deployment, and public-access portions. The video and challenge-form submission are intentionally left as final user actions because they require the author’s own presentation and submission account.

The January requirement is a **scope requirement**, not a requirement to use only specific dates. The captured dataset covers January 2026. The portal exposes 14, 15, and 16 January as representative delivery-day choices in the first-version interface; these dates were not prescribed by the challenge document.

## Live links

- Application: https://windwise-two.vercel.app/
- Public repository: https://github.com/manesh-06/quiet-wind-pilot-7f3c
- Public API health check: https://windwise-two.vercel.app/api/health
- Public API overview example: https://windwise-two.vercel.app/api/overview?deliveryDate=2026-01-14

## Product behavior

The portal is designed as a quiet utility control-room interface rather than a generic analytics dashboard. It provides:

- January 2026 delivery-day selection.
- The selected day-ahead forecast vintage.
- A visible 23:00 UTC cutoff rule.
- Forecast-versus-actual national wind generation on a 30-minute aligned timeline.
- Hoverable chart inspection.
- Settlement-period drill-down with forecast, actual, error, and signal.
- MAE, RMSE, signed bias, and MAPE.
- A buyer takeaway and procurement signal.
- Data provenance and captured-snapshot status.
- A technical-method view explaining the data contract and selection rule.

The application distinguishes captured Elexon data from a small deterministic fallback. The fallback exists only so the interface remains reviewable if the API or local snapshot is unavailable; it is not presented as a live Elexon observation.

## Decision-safe data methodology

### Actual generation

Actual wind generation comes from the Elexon BMRS `FUELHH` stream. The refresh job filters records to:

```text
fuelType = WIND
```

The relevant fields are:

- `startTime`: target settlement-period start time.
- `generation`: national wind generation in MW.

The FUELHH data is treated as half-hourly generation output.

### Forecast generation

Forecast wind generation comes from the Elexon BMRS `WINDFOR` stream. The relevant fields are:

- `startTime`: target delivery-period start time.
- `publishTime`: time at which the forecast vintage was created or published.
- `generation`: forecast national wind generation in MW.

### Day-ahead vintage rule

For a delivery day `D`, the application considers only forecast vintages satisfying:

```text
publishTime <= D-1 23:00:00 UTC
```

Among those eligible vintages, it selects the latest `publishTime`. This is intended to represent the newest forecast the buyer could reasonably have seen before the decision cutoff, without using hindsight revisions published after the decision point.

The selected forecast is aligned with actual generation using the same `startTime` at 30-minute resolution. Only matched forecast/actual periods are included in the error calculations.

### Error definitions

For each aligned period:

```text
error = actual - forecast
```

The metrics are:

```text
MAE  = mean(abs(error))
RMSE = sqrt(mean(error²))
Bias = mean(error)
MAPE = mean(abs(error / actual)) × 100
```

MAPE excludes periods where actual wind generation is zero, because percentage error is undefined in that case. A negative bias means actual wind output was below the selected forecast on average. A positive bias means actual wind output was above forecast on average.

## Data captured in this repository

The repository includes a captured January 2026 snapshot:

- 1,488 filtered FUELHH wind actual rows.
- 17,904 WINDFOR forecast rows across forecast vintages.
- Raw API payloads under `data/raw/`.
- Normalized and queryable records in `data/windwise.sqlite3`.
- Snapshot metadata including source, fetched time, row count, and mode.

The captured data is useful for a reproducible review of the pilot. The refresh job can fetch a new snapshot from the public Elexon endpoints when the relevant historical data is available.

## Repository structure

```text
.
├── api/
│   ├── health.py              # Vercel /api/health Python function
│   ├── index.py               # FastAPI function entrypoint and route aliases
│   └── overview.py            # Vercel /api/overview Python function
├── backend/
│   ├── main.py                # FastAPI app, API contracts, and analytics response
│   ├── elexon.py              # Elexon API adapter and source metadata
│   ├── storage.py             # SQLite persistence and aligned queries
│   ├── requirements.txt       # Backend runtime dependencies
│   └── jobs/
│       └── refresh_elexon.py  # Capture, normalize, and persist refresh job
├── data/
│   ├── raw/                   # Captured FUELHH and WINDFOR JSON payloads
│   └── windwise.sqlite3      # Normalized local snapshot database
├── frontend/
│   ├── src/main.tsx           # React application and data loading
│   ├── src/styles.css         # Dashboard visual system and responsive layout
│   ├── package.json            # Vite/React dependencies and scripts
│   ├── package-lock.json       # Reproducible frontend dependency lockfile
│   └── .env.example            # Optional VITE_API_BASE_URL example
├── .github/workflows/
│   └── elexon-refresh.yml     # Daily refresh workflow
├── Dockerfile                 # Multi-stage frontend/backend container
├── docker-compose.yml          # Local Docker development configuration
├── Procfile                   # Heroku process guidance
├── vercel.json                # Vite build and Python function configuration
├── requirements.txt           # Root requirements used by Vercel Python runtime
├── DEMO_SCRIPT.md             # Suggested customer and technical narration
├── PROGRESS_CHECKLIST.md      # Challenge completion checklist
└── README.md                  # This document
```

## Run locally with Docker

Docker is the recommended full-stack local path:

```bash
docker compose up --build
```

Then open:

```text
http://localhost:3000
```

The container builds the Vite frontend in a Node stage, installs the Python dependencies in a Python stage, copies the captured data, and serves the frontend plus FastAPI API from one process. The container exposes port 3000 and honors the deployment port in the Heroku-style command where applicable.

## Run locally without Docker

### Frontend only

```bash
cd frontend
npm install
npm run dev
```

The Vite development server runs on port 3000. Its configuration proxies `/api` requests to the local FastAPI service.

### Python API

From the repository root:

```bash
python -m venv .venv
source .venv/bin/activate
pip install -r backend/requirements.txt
uvicorn backend.main:app --reload --port 8000
```

The local API is then available at:

```text
http://localhost:8000/health
http://localhost:8000/api/overview?deliveryDate=2026-01-14
```

### Refresh the Elexon snapshot manually

```bash
python backend/jobs/refresh_elexon.py
```

The job retrieves the January 2026 FUELHH and WINDFOR payloads, preserves raw JSON, normalizes rows into SQLite, and updates snapshot metadata. It is deliberately simple for the pilot. Production use should add retries, alerting, object storage, and a managed database.

## Scheduled refresh

`.github/workflows/elexon-refresh.yml` runs the refresh job daily. When GitHub Actions is enabled for the repository and the workflow has permission to write, it can commit changed raw payloads and SQLite state. This repository-backed approach is appropriate for a challenge demonstration, but a production system should not use Git as the primary mutable data store.

## API contract

### `GET /health`

Returns service and snapshot status. On Vercel use:

```text
https://windwise-two.vercel.app/api/health
```

### `GET /api/overview?deliveryDate=YYYY-MM-DD`

Returns the selected delivery-day scope, decision rule, source status, selected forecast vintage, aligned periods, buyer takeaway, procurement signal, and calculated metrics. On Vercel use:

```text
https://windwise-two.vercel.app/api/overview?deliveryDate=2026-01-14
```

The deployed frontend uses same-origin calls to `/api/overview`. If the API is hosted separately, set the Vite build variable:

```bash
VITE_API_BASE_URL=https://your-api-host.example.com
```

## Deployment

### Vercel deployment used for this submission

The deployed application uses one Vercel project:

- Vite builds the React frontend into `frontend/dist`.
- Python functions expose `/api/health` and `/api/overview`.
- `vercel.json` includes the captured `data/**` files in the Python function bundles.
- The frontend defaults to same-origin `/api` requests.
- The production URL is https://windwise-two.vercel.app/.

The deployment was tested from an unauthenticated sandbox browser. The homepage loaded without login, `/api/health` returned HTTP 200, and `/api/overview?deliveryDate=2026-01-14` returned HTTP 200 with captured Elexon data.

A fresh CLI deployment can be made from the repository root after authenticating with Vercel:

```bash
npm install --global vercel
vercel login
vercel --prod
```

### Heroku alternative

Heroku was not used for the final submission because the current Heroku account required adding a payment method before allowing apps to build or run. The challenge permits Vercel **or** Heroku, so no Heroku payment was necessary for this submission.

If using a Heroku account that is already enabled for container deployment:

```bash
heroku create your-windwise-app
heroku stack:set container --app your-windwise-app
git push heroku main
```

The included `Dockerfile` serves the complete app. The health path is `/health`. The process should listen on the platform-provided port.

## Public GitHub repository

The required anonymous/random public repository is:

https://github.com/manesh-06/quiet-wind-pilot-7f3c

It contains the refreshed submission archive, README, checklist, Dockerfile, and demo script. The downloadable local archive is also available as `windwise-submission.zip`.

## Video demo requirement and recording instructions

The challenge requires **one unlisted YouTube video with two parts**, with a total maximum length of 10 minutes:

- Part 1: customer pitch, maximum 5 minutes.
- Part 2: internal technical walkthrough, maximum 5 minutes.

This should be a screen recording with your voice. It is not expected to be a plain text webpage or a silent screenshot. You can use Loom, OBS, Zoom recording, Windows Game Bar, macOS Screenshot, or any available screen recorder.

### Suggested recording format

1. Open https://windwise-two.vercel.app/.
2. Start screen recording and microphone recording.
3. Spend up to five minutes on the customer pitch.
4. Keep the app visible while explaining the business value.
5. Switch to the GitHub repository and, if useful, the source files for the technical section.
6. Spend up to five minutes explaining the architecture and methodology.
7. Stop before 10 minutes total.
8. Upload the single video to YouTube as **Unlisted**, not Private.
9. Open the YouTube URL in an incognito window and verify it plays.

### Part 1: customer pitch content

Show the dashboard, delivery-day selector, forecast vintage, chart, buyer takeaway, procurement signal, and metrics. Explain that the tool helps a day-ahead buyer understand forecast uncertainty before purchasing power. For example:

> “WindWise shows the latest wind forecast that was available before the day-ahead decision cutoff. For the selected delivery day, it compares that forecast with realized national wind output over the same half-hour periods. The buyer can see whether wind ran above or below forecast and quantify the typical and larger misses using MAE, RMSE, bias, and MAPE. This supports a more disciplined decision about how much flexible cover to retain instead of treating one forecast number as certain.”

Switch between the visible January delivery days and hover the chart so the reviewer can see the period-level values.

### Part 2: technical walkthrough content

Show the repository and explain:

- React/Vite frontend in `frontend/`.
- FastAPI backend in `backend/`.
- Elexon FUELHH actuals filtered to wind.
- Elexon WINDFOR forecast vintages.
- 23:00 UTC day-ahead cutoff.
- `startTime` alignment at 30-minute resolution.
- Error and metric definitions.
- Raw snapshots in `data/raw/`.
- SQLite persistence in `data/windwise.sqlite3`.
- Refresh job in `backend/jobs/refresh_elexon.py`.
- Daily workflow in `.github/workflows/elexon-refresh.yml`.
- Dockerfile and Docker Compose configuration.
- Vercel functions under `api/` and `vercel.json`.
- AI assistance disclosure in this README.
- Public deployment and GitHub repository.

The video does not need studio production quality. A clear browser screen, readable URL, audible explanation, and total duration under 10 minutes are the important constraints.

## Final submission checklist

Before submitting the challenge form:

- [x] React frontend implemented.
- [x] Python backend implemented.
- [x] January 2026 Elexon scope implemented.
- [x] FUELHH actual wind data used.
- [x] WINDFOR forecast data used.
- [x] Day-ahead forecast cutoff implemented.
- [x] Quantitative forecast error metrics implemented.
- [x] Docker configuration included.
- [x] Public anonymous GitHub repository created.
- [x] Application deployed to Vercel.
- [x] Public homepage and API tested without login.
- [ ] Record the two-part video under 10 minutes total.
- [ ] Upload the video to YouTube as unlisted.
- [ ] Open GitHub, Vercel, and YouTube URLs in incognito mode.
- [ ] Submit all URLs and details in the challenge form.

## AI assistance disclosure

AI tools were used to accelerate scaffolding, UX copy, code generation, data-pipeline implementation, deployment configuration, and documentation. The author remains responsible for the product decisions, source interpretation, forecast-vintage selection rule, metric definitions, implementation review, and final submission. No AI-generated value is presented as a live Elexon observation without an explicit captured-data or fallback label.

## Limitations and production next steps

This is a first-version pilot, not a live trading system. It does not include demand, prices, thermal availability, balancing costs, authentication, user roles, alerts, or an order workflow because the challenge limits the analysis to national Elexon wind actuals and forecasts.

The captured snapshot and SQLite database are repository-backed for reproducibility. A production version should move raw snapshots to object storage, move normalized records and audit history to a managed database, add retry and alerting around refresh jobs, add authentication and permissions, add data-quality monitoring, and avoid committing mutable operational state to Git.

## Source links

- Elexon FUELHH documentation: https://bmrs.elexon.co.uk/api-documentation/endpoint/datasets/FUELHH/stream
- Elexon WINDFOR documentation: https://bmrs.elexon.co.uk/api-documentation/endpoint/datasets/WINDFOR/stream
- Live WindWise application: https://windwise-two.vercel.app/
- Public GitHub repository: https://github.com/manesh-06/quiet-wind-pilot-7f3c
