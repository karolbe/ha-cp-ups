"""Create MQTT publisher."""
import time
import json
import logging
from typing import Any, Dict, Optional

import paho.mqtt.client as mqtt

import pwrstat_api

_LOGGER = logging.getLogger("PwrstatApi")
_CLIENT = mqtt.Client()


class PwrstatMqtt:
    """Create MQTT publisher."""

    def __init__(self, mqtt_config: Dict[str, Any]) -> None:
        """Start MQTT loop."""
        self.mqtt_config = mqtt_config
        client_id: Optional[str] = self.mqtt_config.get("client_id")
        if client_id:
            _CLIENT.reinitialise(client_id=client_id)
        username = self.mqtt_config.get("username")
        password = self.mqtt_config.get("password")
        if None not in (username, password):
            _CLIENT.username_pw_set(username=username, password=password)
        self.refresh_interval: int = self.mqtt_config["refresh"]

    def _connect_mqtt(self) -> None:
        """Connect to MQTT broker."""
        mqtt_host: str = self.mqtt_config["broker"]
        mqtt_port: int = self.mqtt_config["port"]
        _LOGGER.info(f"Connecting to MQTT broker {mqtt_host}:{mqtt_port}...")
        
        try:
            _CLIENT.connect(host=mqtt_host, port=mqtt_port, keepalive=60)
            _CLIENT.loop_start()
            
            # Wait for connection with timeout
            timeout = 30
            while not _CLIENT.is_connected() and timeout > 0:
                time.sleep(1)
                timeout -= 1
                
            if _CLIENT.is_connected():
                _LOGGER.info(f"MQTT Broker connected successfully")
            else:
                _LOGGER.error(f"Failed to connect to MQTT broker after 30 seconds")
                
        except Exception as e:
            _LOGGER.error(f"MQTT connection error: {e}")

    def loop(self) -> None:
        """Loop for MQTT updates."""
        _LOGGER.info("Starting MQTT loop...")
        while True:
            if not is_connected():
                self._connect_mqtt()
            self._publish_update()
            _LOGGER.debug("Publishing message to MQTT broker...")
            time.sleep(self.refresh_interval)

    def _publish_update(self) -> bool:
        """Update MQTT topic with latest status."""
        if not _CLIENT.is_connected():
            _LOGGER.warning("MQTT client not connected, skipping publish")
            return False
            
        topic = self.mqtt_config["topic"]
        qos: int = self.mqtt_config["qos"]
        retain: bool = self.mqtt_config["retained"]
        status = pwrstat_api.get_status()
        
        if status is not None:
            json_payload = json.dumps(status)
            try:
                result = _CLIENT.publish(topic, json_payload, qos=qos, retain=retain)
                if result.rc == 0:
                    _LOGGER.debug(f"Published to {topic}: {json_payload}")
                    return True
                else:
                    _LOGGER.error(f"Publish failed with code {result.rc}")
                    return False
            except Exception as e:
                _LOGGER.error(f"MQTT publish error: {e}")
                return False
        return False


def is_connected() -> bool:
    """Check connection to MQTT broker."""
    return _CLIENT.is_connected()


if __name__ == "__main__":
    pass
