# WindWise demo script — 8 to 9 minutes

## Part 1 — client pitch (about 4 minutes)

Open on the dashboard and say: “WindWise turns the wind forecast into a decision-ready position. It is deliberately scoped to the January 2026 pilot and uses only Elexon national wind actuals and forecasts.”

Select 14 January. Point to the forecast vintage card: “This is not the latest hindsight revision. It is the latest forecast published by 23:00 UTC on 13 January, which is the information a day-ahead buyer could actually have used.” Explain the three top cards: forecast average, realized average, and the procurement signal.

Trace the chart from midnight to 23:30. Say that both series are in MW and aligned at the same 30-minute target periods. Select another delivery day to show the decision desk is not a single static screenshot. Scroll to the settlement table and explain that the error is visible in MW, not hidden behind a single accuracy score.

Finish with the metrics: “MAE is the typical miss, RMSE penalizes larger misses, bias shows direction, and MAPE is only computed where actual output is non-zero.” This lets the team plan cover with a quantified uncertainty rather than treating the forecast as exact.

## Part 2 — technical lead walkthrough (about 4 minutes)

Open “Technical method”. Explain the four blocks: ingest, select vintage, align and score, operate. Name the Elexon datasets and fields: FUELHH `startTime`, `generation`, `fuelType`; WINDFOR `startTime`, `publishTime`, `generation`.

Explain the cutoff algorithm: filter forecast rows to `publishTime <= delivery_day - 1 day at 23:00 UTC`, choose the maximum eligible publish time, then join forecast and actual by `startTime`. Define the metric formulas in plain language.

Show the repository structure: `frontend` is React/Vite, `backend` is FastAPI, `Dockerfile` packages both, and `docker-compose.yml` is the local entry point. Call out `/health` and `/api/overview` as the API contract.

Be candid about limitations: the first version does not include demand, price, thermal availability, authentication, or a database. The visible portal is populated with deterministic pilot data and labels the backend mode as `demo-fallback`; a production next step is to persist raw Elexon responses and schedule refreshes. Close by pointing to the README's AI-assistance disclosure and deployment notes.
