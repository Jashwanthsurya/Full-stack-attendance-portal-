# Frontend Dockerfile for serving static files with Nginx
FROM nginx:alpine

# Copy static files
COPY static/ /usr/share/nginx/html/static/
COPY templates/ /usr/share/nginx/html/templates/

# Copy custom nginx configuration
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Expose port 80
EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]