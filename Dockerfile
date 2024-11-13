# FROM node:6-stretch
FROM node:18.20.4-alpine3.20


RUN mkdir /usr/src
RUN mkdir /usr/src/goof
RUN mkdir /tmp/extracted_files
COPY . /usr/src/goof
WORKDIR /usr/src/goof

RUN npm install
EXPOSE 3001
EXPOSE 9229

# Create a non-root user with a specific UID and assign ownership of directories
RUN adduser --disabled-password --gecos "" --uid 1001 appuser && \
    chown -R appuser:appuser /usr/src/goof /tmp/extracted_files

USER appuser

# Add a health check to verify the app is running
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
  CMD curl -f http://localhost:3001 || exit 1

ENTRYPOINT ["npm", "start"]
