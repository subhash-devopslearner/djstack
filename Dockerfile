FROM python:3.12-slim

RUN apt-get update && apt-get install -y libpq-dev gcc

WORKDIR /app

COPY requirements.txt .

COPY entrypoint.sh .

RUN pip install --upgrade pip

RUN pip install -r requirements.txt

COPY djstack/ .

RUN useradd -m django

RUN chmod +x /app/entrypoint.sh

EXPOSE 8000

ENTRYPOINT ["/app/entrypoint.sh"]