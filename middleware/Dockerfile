FROM python:3.12-slim

RUN apt-get update && apt-get install -y build-essential python3-dev gcc g++ portaudio19-dev

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . /app

EXPOSE 8080
ENV PORT=8080
ENV GEMINI_API_KEY=IzaSyACvTC2a4fWn06wDvj9nCfViXLtUiCJ7lo

CMD ["python", "run.py"]
