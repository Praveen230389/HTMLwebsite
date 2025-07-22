# Dockerfile for a static HTML site
FROM nginx:alpine

# Copy your HTML/CSS/JS into the nginx html directory
COPY ./html/ /usr/share/nginx/html/

# Expose port 8082
EXPOSE 80

# Default command
CMD ["nginx", "-g", "daemon off;"]
