# WindWise — UK wind forecast intelligence

WindWise is a focused pilot portal for a UK utility buying power in the day-ahead market. It answers two operational questions: **what wind forecast was available when the buyer had to decide?** and **how wrong was it, in measurable MW terms?** The pilot is deliberately limited to January 2026 national wind data from Elexon.

## What is included

The React portal provides delivery-day selection, the selected forecast vintage, an aligned forecast-versus-actual chart, settlement-period drill-down, MAE/RMSE/bias/MAPE, and an internal technical method view. The FastAPI backend exposes `/health` and `/api/overview` and records the data contract and provenance used by the interface.

## Decision-safe methodology

Actual generation comes from Elexon BMRS `FUELHH`, filtered to `fuelType=WIND`; the relevant fields are `startTime` and `generation`. Forecasts come from `WINDFOR`; the relevant fields are `startTime`, `publishTime`, and `generation`. For a delivery day D, only forecasts with `publishTime <= D-1 23:00:00 UTC` are eligible. The latest eligible publish vintage is selected. Forecast and actual rows are aligned by `startTime` at 30-minute resolution. Error is `actual - forecast`; MAE is the mean absolute error, RMSE is the square root of mean squared error, bias is mean signed error, and MAPE is calculated only where actual output is non-zero.

The repository now contains a captured January 2026 Elexon snapshot under `data/raw/` plus a SQLite store at `data/windwise.sqlite3`. The API reads selected forecast vintages and aligned actuals from that store and labels the response `captured-elexon-snapshot`. If the store is unavailable, the React app retains a small deterministic fallback so the interface remains reviewable.

## Run locally

With Docker:

```bash
docker compose up --build
```

Then open `http://localhost:3000`.

For frontend-only iteration:

```bash
cd frontend
npm install
npm run dev
```

For the API:

```bash
python -m venv .venv
source .venv/bin/activate
pip install -r backend/requirements.txt
uvicorn backend.main:app --reload --port 8000
```

To refresh the captured snapshot manually:

```bash
python backend/jobs/refresh_elexon.py
```

The repository also includes `.github/workflows/elexon-refresh.yml`, which runs the same refresh job daily and commits changed raw data and SQLite state when the public repository has Actions enabled.

## Elexon sources

- FUELHH stream: https://bmrs.elexon.co.uk/api-documentation/endpoint/datasets/FUELHH/stream
- WINDFOR stream: https://bmrs.elexon.co.uk/api-documentation/endpoint/datasets/WINDFOR/stream

Elexon documents FUELHH as half-hourly generation outturn with average MW values, and WINDFOR as forecast data that can be filtered by publish time.

## Deployment guidance

For Heroku, deploy the repository with the included Dockerfile. Set the web process to `uvicorn server:app --host 0.0.0.0 --port $PORT` and use `/health` as the health check. For Vercel, the checked-in `vercel.json` builds `frontend` as a Vite static project; host the FastAPI service separately and configure the frontend API base URL through a build-time environment variable. The single-container route is the simplest review deployment.

## AI assistance disclosure

AI tools were used to accelerate scaffolding, UX copy, code generation, and documentation. The implementation, data-selection rule, metric definitions, source interpretation, and final review remain the responsibility of the author. No AI-generated value is presented as a live Elexon observation without an explicit demo/fallback label.

## Known limitations

This submission does not claim to be a live trading system. It does not include demand, prices, thermal availability, balancing costs, or authentication because the challenge scope excludes all non-Elexon data. The snapshot refresh is intentionally simple and repository-backed; a production deployment should move raw snapshots and the audit trail to managed object/database storage, add retry and alerting, and avoid committing mutable SQLite files to Git.
