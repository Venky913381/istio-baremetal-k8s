FROM python:3.11-slim-bookworm

WORKDIR /app

# psycopg2-binary ships precompiled wheels, so no gcc/libpq-dev build toolchain is needed here.

# Install Python requirements
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application source code
COPY ./app ./app

EXPOSE 8000

ENV PORT=8000
ENV PYTHONUNBUFFERED=1

CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
