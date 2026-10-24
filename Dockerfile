FROM python:3.13-alpine AS builder

WORKDIR /build

RUN python -m venv /opt/venv

ENV PATH="/opt/venv/bin:$PATH"

COPY app/requirements.txt .

RUN pip install --no-cache-dir --upgrade \
        pip==26.2 \
        setuptools==83.0.0 \
        wheel==0.46.2 \
    && pip install --no-cache-dir -r requirements.txt


FROM python:3.13-alpine AS runtime

WORKDIR /app

ENV PATH="/opt/venv/bin:$PATH" \
    PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

COPY --from=builder /opt/venv /opt/venv
COPY app/ /app/

RUN python -m pip uninstall -y pip \
    && addgroup -S app \
    && adduser -S app -G app \
    && chown -R app:app /app /opt/venv

USER app

EXPOSE 5000

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
    CMD python -c "import urllib.request; urllib.request.urlopen('http://127.0.0.1:5000/health', timeout=3)" || exit 1

CMD ["gunicorn", "--bind", "0.0.0.0:5000", "wsgi:app"]