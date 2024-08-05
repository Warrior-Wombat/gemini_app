import logging
from fastapi import FastAPI
from app.routes import gemini, autocomplete, voice, image, auth
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

    app.include_router(auth.router, prefix="/auth", tags=["Auth"])
    app.include_router(gemini.router, prefix="/gemini", tags=["Gemini"])
    app.include_router(autocomplete.router, prefix="/autocomplete", tags=["Autocomplete"])
    app.include_router(voice.router, prefix="/voice", tags=["Voice"])
    app.include_router(image.router, prefix="/image", tags=["Image"])

    return app

app = create_app()
