from fastapi import FastAPI

app = FastAPI(title="PropSense ML Service")


@app.get("/health")
def health():
    return {"status": "ok"}
