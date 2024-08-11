FROM python:3.12-slim

# install pyaudio dependencies
RUN apt-get update && apt-get install -y build-essential python3-dev gcc g++ portaudio19-dev

WORKDIR /app

COPY ./app /app

COPY requirements.txt /app
RUN pip install --no-cache-dir -r requirements.txt

EXPOSE 5000

CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "5000"]