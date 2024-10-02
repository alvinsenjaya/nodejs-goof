FROM node:22.6.0-slim

# Create a non-root user and group, and give ownership of the application directory
RUN groupadd -r appgroup && useradd -r -g appgroup appuser
RUN mkdir /usr/src/goof /tmp/extracted_files && chown -R appuser:appgroup /usr/src/goof /tmp/extracted_files

COPY . /usr/src/goof
WORKDIR /usr/src/goof

RUN npm install

# Switch to the non-root user
USER appuser

# Add a HEALTHCHECK command to verify the application is running
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 CMD curl -f http://localhost:3001/ || exit 1

EXPOSE 3001
EXPOSE 9229

ENTRYPOINT ["npm", "start"]
