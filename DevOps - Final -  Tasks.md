# DevOps - Final

## Vulnerabilities

Before fixing vulnerabilities

![image-20250620201614338](/home/churchin/.config/Typora/typora-user-images/image-20250620201614338.png)

After fixing vulnerabilities:

![image-20250620204833587](/home/churchin/.config/Typora/typora-user-images/image-20250620204833587.png)

Some of the vulnerabilities were fixed by changing the image version to newer one, but some required Dockerfile changes, for example frontend and backend need their Dockerfiles changed so that use less privileged user to run the actual backend/frontend. Unfortunately Postgres has many issues which are not easily fixable, I changed the image version to fix some vulnerabilities but some are still present. (Recommend solutions include: 1, Wait for new image version where vulnerabilities are fixed 2. Research ways to fix the vulnerabilities and implement them).

Fixed backend Dockerfile:

```dockerfile
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
```

Fixed frontend Dockerfile:

```dockerfile
# Use nginx alpine image with latest security updates
FROM nginx:1.27-alpine

# Install security updates for Alpine packages
RUN apk update && apk upgrade --no-cache \
    && apk add --no-cache libxml2=2.13.4-r6 \
    && rm -rf /var/cache/apk/*

# nginx user already exists, just ensure proper setup

# Copy custom nginx configuration
COPY nginx.conf /etc/nginx/nginx.conf

# Copy frontend files
COPY . /usr/share/nginx/html/

# Set proper permissions
RUN chown -R nginx:nginx /usr/share/nginx/html/ \
    && chown -R nginx:nginx /var/cache/nginx \
    && chown -R nginx:nginx /var/log/nginx \
    && chown -R nginx:nginx /etc/nginx/conf.d \
    && touch /var/run/nginx.pid \
    && chown -R nginx:nginx /var/run/nginx.pid

# Switch to non-root user
USER nginx

# Expose port 80
EXPOSE 80

# Start nginx
CMD ["nginx", "-g", "daemon off;"]
```



## Incident Sumulation

Let's kill/pause the backend container:

```bash
docker pause todo_backend
```



![image-20250620210217605](/home/churchin/.config/Typora/typora-user-images/image-20250620210217605.png)

As we can see when backend is killed/paused the frontends requests don't get a response since backend is paused



## Prometheus + Grafana

![image-20250620210915716](/home/churchin/.config/Typora/typora-user-images/image-20250620210915716.png)

![image-20250620211006767](/home/churchin/.config/Typora/typora-user-images/image-20250620211006767.png)

![image-20250620211856245](/home/churchin/.config/Typora/typora-user-images/image-20250620211856245.png)