from app import app
import uvicorn

if __name__ == "__main__":
    port = 8080
    uvicorn.run(app, host="0.0.0.0", port=port, log_level="info")