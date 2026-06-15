FROM nginx:stable-alpine
# Customize the index page to confirm it's the containerized version
RUN echo '<h1>Auto-Healing Web Tier Is Operational</h1>' > /usr/share/nginx/html/index.html
EXPOSE 80
