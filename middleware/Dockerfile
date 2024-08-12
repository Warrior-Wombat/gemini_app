FROM python:3.12-slim

RUN apt-get update && apt-get install -y build-essential python3-dev gcc g++ portaudio19-dev

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . /app

RUN chmod +x /app/entrypoint.sh

EXPOSE 8080
ENV PORT 8080

ENTRYPOINT ["./entrypoint.sh"]
CMD ["python", "run.py"]
