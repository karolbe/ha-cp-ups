FROM ubuntu:22.04

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Install dependencies
RUN apt-get update && \
    apt-get install -y procps curl python3-pip python3-venv usbutils && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Copy application files
COPY rootfs/pwrstat /app
COPY rootfs/PPL-1.3.3-64bit.deb /tmp/

# Install PowerPanel Linux and Python dependencies
RUN apt-get update && \
    apt-get install -y /tmp/PPL-1.3.3-64bit.deb && \
    pip3 install --no-cache-dir -r /app/requirements.txt && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/PPL-1.3.3-64bit.deb

# Create startup script
COPY <<'EOF' /app/start.sh
#!/bin/bash
cd /app

# Generate config from environment variables
cat > /app/pwrstat.json << EOL
{
  "pwrstat_api": {
    "log_level": "${LOG_LEVEL:-WARNING}"
  },
  "mqtt": {
    "broker": "${MQTT_HOST:-localhost}",
    "port": ${MQTT_PORT:-1883},
    "client_id": "${MQTT_CLIENT_ID:-pwrstat}",
    "topic": "${MQTT_PREFIX:-pwrstat}/${MQTT_TOPIC:-power/ups}",
    "refresh": ${MQTT_REFRESH:-30},
    "qos": ${MQTT_QOS:-2},
    "retained": ${MQTT_RETAIN:-true},
    "username": "${MQTT_USER:-}",
    "password": "${MQTT_PASS:-}"
  },
  "rest": {
    "port": 5003,
    "bind_address": "0.0.0.0"
  },
  "prometheus": {
    "port": 9222,
    "bind_address": "0.0.0.0",
    "labels": {
      "rack": "0"
    }
  }
}
EOL

echo "Starting pwrstat with config:"
cat pwrstat.json

echo "=== USB Device Debug Info ==="
echo "USB devices in container:"
lsusb 2>/dev/null || echo "lsusb not available"
echo "USB bus devices:"
ls -la /dev/bus/usb/ 2>/dev/null || echo "/dev/bus/usb not accessible"
ls -la /dev/bus/usb/001/ 2>/dev/null || echo "/dev/bus/usb/001 not accessible"
echo "PowerPanel daemon status:"
ps aux | grep pwrstatd || echo "No pwrstatd processes found"
echo "Trying to start pwrstatd daemon..."
/usr/sbin/pwrstatd >/dev/null 2>&1 &
sleep 2
echo "PowerPanel daemon status after start attempt:"
ps aux | grep pwrstatd || echo "Still no pwrstatd processes found"
echo "Testing pwrstat command:"
pwrstat -status 2>&1 || echo "pwrstat command failed"
echo "=== End Debug Info ==="

exec python3 /app/pwrstat_api.py JSON
EOF

RUN chmod +x /app/start.sh

WORKDIR /app

# Expose ports
EXPOSE 5003 9222

# Environment variables with defaults
ENV LOG_LEVEL=WARNING \
    MQTT_PREFIX=pwrstat \
    MQTT_CLIENT_ID=pwrstat \
    MQTT_RETAIN=true \
    MQTT_QOS=2 \
    MQTT_TOPIC=power/ups \
    MQTT_REFRESH=30

CMD ["/app/start.sh"]