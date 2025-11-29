# Install Python3, pip, and locust for benchmark testing
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y -o Dpkg::Options::=--force-confold \
    python3 \
    python3-pip \
    && rm -rf /var/lib/apt/lists/*

# Install locust via pip (using --break-system-packages is safe in Docker containers)
RUN pip3 install --break-system-packages --no-cache-dir locust

