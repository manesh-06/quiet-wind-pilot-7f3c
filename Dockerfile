FROM node:22-alpine AS frontend
WORKDIR /app/frontend
COPY frontend/package.json package.json
COPY frontend/package-lock.json package-lock.json
RUN npm ci
COPY frontend/ .
RUN npm run build

FROM python:3.12-slim
WORKDIR /app
COPY backend/requirements.txt ./backend/requirements.txt
RUN pip install --no-cache-dir -r backend/requirements.txt
COPY backend ./backend
COPY data ./data
COPY --from=frontend /app/frontend/dist ./frontend/dist
RUN printf '%s\n' 'from fastapi import FastAPI' 'from fastapi.staticfiles import StaticFiles' 'from fastapi.responses import FileResponse' 'from backend.main import app' 'app.mount("/assets", StaticFiles(directory="/app/frontend/dist/assets"), name="assets")' '@app.get("/")' 'def index():' '    return FileResponse("/app/frontend/dist/index.html")' > /app/server.py
EXPOSE 3000
CMD ["uvicorn","server:app","--host","0.0.0.0","--port","3000"]
