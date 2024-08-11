FROM python:3.12-slim

# pyaudio dependencies since we are using slim version
RUN apt-get update && apt-get install -y build-essential python3-dev gcc g++ portaudio19-dev

WORKDIR /app

COPY requirements.txt .

RUN pip install --no-cache-dir -r requirements.txt

COPY ./app /app

EXPOSE 8080

ENV PORT 8080

CMD ["uvicorn", "app.__init__:app", "--host", "0.0.0.0", "--port", "8080"]
