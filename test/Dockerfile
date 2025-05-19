FROM heroku/heroku:22-cnb

# Install basic testing tools
USER root
RUN apt-get update && apt-get install -y \
    curl \
    gpg \
    && rm -rf /var/lib/apt/lists/*

# Create test directory
WORKDIR /app

# Copy buildpack and test files
COPY . /buildpack
COPY test/test_buildpack.sh /app/

# Make test script executable
RUN chmod +x /app/test_buildpack.sh

# Set up test environment
ENV PATH="/buildpack/bin:${PATH}"

# Run tests
CMD ["/app/test_buildpack.sh"]
