from fastapi import FastAPI
import uvicorn
import os

app = FastAPI()

@app.get("/")
async def read_root():
    return {"Hello": "Wrld"}

if __name__ == "__main__":
    port = 8080
    uvicorn.run(app, host="0.0.0.0", port=port, log_level="info")