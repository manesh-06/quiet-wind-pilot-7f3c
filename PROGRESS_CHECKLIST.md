# WindWise challenge progress checklist

## Completed

- [x] Read and decomposed the challenge requirements.
- [x] Created the React/Vite frontend and Python/FastAPI backend.
- [x] Added January 2026 scope and the 23:00 UTC day-ahead forecast cutoff.
- [x] Added Elexon FUELHH and WINDFOR provenance and relevant fields.
- [x] Added forecast-versus-actual chart, aligned-period drill-down, MAE/RMSE/bias/MAPE, and technical walkthrough.
- [x] Captured real January 2026 Elexon data: 1,488 FUELHH wind rows and 17,904 WINDFOR forecast rows.
- [x] Persisted raw JSON payloads in `data/raw/` and normalized records plus snapshot metadata in `data/windwise.sqlite3`.
- [x] Connected React to FastAPI `/api/overview?deliveryDate=...` through the Vite proxy.
- [x] Added API delivery-day selection, forecast-vintage selection, aligned points, and snapshot-status metadata.
- [x] Added a daily GitHub Actions refresh workflow and a manual refresh command.
- [x] Added Dockerfile, Docker Compose, Heroku Procfile, Vercel configuration, and `.dockerignore`.
- [x] Installed Docker Engine in the sandbox.
- [x] Built the Docker image successfully with host networking in this restricted sandbox.
- [x] Ran the built container and verified `/health` plus captured-data `/api/overview` responses.
- [x] Frontend production build passes.
- [x] Python backend checks pass.
- [x] Preview dashboard was visually checked at desktop and mobile widths.
- [x] Source was committed and pushed to the initialized project repository.

## Still pending

- [ ] Enable the GitHub connector in Manus so the repository can be created safely under the user’s GitHub account.
- [ ] Create the required public anonymous GitHub repository and push this source to it.
- [ ] Deploy the container to Heroku or deploy the frontend/backend separately to Vercel plus a Python host.
- [ ] Configure the deployed frontend API URL and run an incognito access check.
- [ ] Record the customer pitch section, maximum 5 minutes.
- [ ] Record the internal technical walkthrough section, maximum 5 minutes.
- [ ] Upload the combined video to YouTube as unlisted.
- [ ] Open the GitHub URL, deployed app URL, and YouTube URL in incognito mode and verify access.
- [ ] Submit the final URLs and details through the challenge form.
