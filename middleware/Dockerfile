FROM python:3.12-slim

# Install PyAudio dependencies
RUN apt-get update && apt-get install -y build-essential python3-dev gcc g++ portaudio19-dev

WORKDIR /app

COPY ./app /app
COPY requirements.txt /app
RUN pip install --no-cache-dir -r requirements.txt

EXPOSE 8080

CMD ["uvicorn", "app.__init__:app", "--host", "0.0.0.0", "--port", "8080"]
