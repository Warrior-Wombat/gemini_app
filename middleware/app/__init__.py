from fastapi import FastAPI
from app.routes import gemini, autocomplete, voice, image

def create_app() -> FastAPI:
    app = FastAPI()

    app.include_router(gemini.router, prefix="/gemini", tags=["Gemini"])
    app.include_router(autocomplete.router, prefix="/autocomplete", tags=["Autocomplete"])
    app.include_router(voice.router, prefix="/voice", tags=["Voice"])
    app.include_router(image.router, prefix="/image", tags=["Image"])

    return app

app = create_app()
