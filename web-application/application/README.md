# web-app application

This directory contains a minimal Python Flask application used by the web-application lab.

Build and run locally:

```bash
# build
docker build -t yourrepo/web-app:latest .

# run
docker run -p 8080:80 yourrepo/web-app:latest
```

Health endpoint: http://localhost:8080/healthz
