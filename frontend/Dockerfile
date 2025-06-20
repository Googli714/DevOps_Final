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