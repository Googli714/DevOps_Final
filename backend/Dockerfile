# Use Python 3.11 Alpine image for minimal attack surface
FROM python:3.11-alpine

# Set working directory
WORKDIR /app

# Create non-root user for security
RUN addgroup -g 1000 appuser && adduser -u 1000 -G appuser -D appuser

# Install system dependencies (Alpine packages)
RUN apk update && apk upgrade --no-cache \
    && apk add --no-cache \
        gcc \
        musl-dev \
        postgresql-client \
        libpq-dev \
    && rm -rf /var/cache/apk/*

# Copy requirements and install Python dependencies with updated versions
COPY requirements.txt .
RUN pip install --no-cache-dir --upgrade pip \
    && pip install --no-cache-dir -r requirements.txt

# Copy application code
COPY . .

# Change ownership to non-root user
RUN chown -R appuser:appuser /app

# Switch to non-root user
USER appuser

# Expose port
EXPOSE 8000

# Command to run the application
CMD ["uvicorn", "app:app", "--host", "0.0.0.0", "--port", "8000"]