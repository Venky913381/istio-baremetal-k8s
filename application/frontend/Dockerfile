FROM python:3.11-slim

WORKDIR /app

# Copy requirements and install dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application source code
COPY . .

EXPOSE 5000

ENV PORT=5000
ENV PYTHONUNBUFFERED=1
ENV BACKEND_URL="http://backend:8000"

CMD ["gunicorn", "--bind", "0.0.0.0:5000", "app:app"]
