@echo off
if not exist .venv (
    py -3.11 -m venv .venv
)
call .venv\Scripts\activate
if not exist .env copy .env.example .env
pip install -r requirements.txt
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
