# Build from the repository root (the app also needs capalit_ml/ and data/splits/):
#   docker build -f deployment/Dockerfile -t readmitguard .
#   docker run -p 8501:8501 -p 8000:8000 readmitguard
FROM python:3.12-slim

WORKDIR /app

COPY deployment/requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY deployment/ .
COPY capalit_ml /capalit_ml
COPY data/splits /data/splits

EXPOSE 8501 8000

CMD ["sh", "-c", "uvicorn api.main:app --host 0.0.0.0 --port 8000 & streamlit run app/Home.py --server.port 8501 --server.address 0.0.0.0"]
