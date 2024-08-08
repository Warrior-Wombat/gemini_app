import logging
from fastapi import FastAPI
from app.routes import autocomplete
from app.services import config
from fastapi.middleware.cors import CORSMiddleware

def create_app() -> FastAPI:
    app = FastAPI()
    logging.basicConfig(level=logging.DEBUG)
    app.add_middleware(
        CORSMiddleware,
        allow_origins=["*"],
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )

    app.include_router(autocomplete.router, prefix="/autocomplete", tags=["Autocomplete"])
    return app

app = create_app()
