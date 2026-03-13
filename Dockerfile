FROM python:3.12-slim

# Install Postgres, Apache, and Supervisor
RUN apt-get update && apt-get install -y --no-install-recommends \
    postgresql \
    postgresql-client \
    apache2 \
    supervisor \
    && rm -rf /var/lib/apt/lists/*

# Enable Apache proxy modules
RUN a2enmod proxy proxy_http

# --- Backend setup ---
WORKDIR /app
COPY backend/requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY backend/app.py .

# --- Frontend setup ---
COPY frontend/index.html /var/www/html/index.html
COPY frontend/apache-site.conf /etc/apache2/sites-available/000-default.conf
COPY frontend/ports.conf /etc/apache2/ports.conf

# --- Supervisor + startup ---
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY start.sh /start.sh
RUN chmod +x /start.sh

EXPOSE 8080

CMD ["/start.sh"]
