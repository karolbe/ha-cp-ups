# CyberPower UPS Monitor for Home Assistant

A standalone Docker container that monitors CyberPower UPS devices and integrates with Home Assistant via MQTT.

Originally based on the [deprecated HassOS-Addons/pwrstat](https://github.com/DanielWinks/HassOS-Addons) addon, converted to run as a standalone Docker container on Intel x64 systems.


![Alt text](assets/dashboard.png?raw=true "Dashboard")

## Features

- 📊 **Real-time UPS monitoring** - Battery level, load, voltage, runtime
- 🏠 **Home Assistant integration** - MQTT sensors with dashboard
- 📈 **Multiple data outputs** - MQTT, REST API, Prometheus metrics
- 🔌 **USB device support** - Direct USB connection to UPS
- 🐳 **Docker deployment** - Easy setup with docker-compose

## Supported UPS Models

Any CyberPower UPS supported by PowerPanel Linux (CP1500, CP1350, etc.)

## Quick Start

1. **Clone and configure**:
   ```bash
   git clone <this-repo>
   cd pwrstat
   ```

2. **Edit configuration**:
   ```bash
   nano docker-compose.yml
   ```
   Update these variables:
   ```yaml
   - MQTT_HOST=192.168.1.100        # Your Home Assistant IP
   - MQTT_USER=your_mqtt_user       # Your MQTT username
   - MQTT_PASS=your_mqtt_password   # Your MQTT password
   ```

3. **Start the container**:
   ```bash
   docker-compose up -d
   ```

4. **Verify it's working**:
   ```bash
   docker-compose logs pwrstat
   ```

## Home Assistant Configuration

### MQTT Sensors

Add this to your `configuration.yaml`:

```yaml
mqtt:
  sensor:
    - name: "UPS Model"
      state_topic: "pwrstat/power/ups"
      value_template: "{{ value_json['Model Name'] }}"
      icon: mdi:information
      
    - name: "UPS State"
      state_topic: "pwrstat/power/ups"
      value_template: "{{ value_json['State'] }}"
      icon: mdi:power-plug
      
    - name: "UPS Power Supply"
      state_topic: "pwrstat/power/ups"
      value_template: "{{ value_json['Power Supply by'] }}"
      icon: mdi:transmission-tower
      
    - name: "UPS Utility Voltage"
      state_topic: "pwrstat/power/ups"
      value_template: "{{ value_json['Utility Voltage'] | regex_replace(' V', '') }}"
      unit_of_measurement: "V"
      device_class: voltage
      icon: mdi:flash
      
    - name: "UPS Output Voltage"
      state_topic: "pwrstat/power/ups"
      value_template: "{{ value_json['Output Voltage'] | regex_replace(' V', '') }}"
      unit_of_measurement: "V"
      device_class: voltage
      icon: mdi:flash
      
    - name: "UPS Battery Capacity"
      state_topic: "pwrstat/power/ups"
      value_template: "{{ value_json['Battery Capacity'] | regex_replace(' %', '') }}"
      unit_of_measurement: "%"
      device_class: battery
      icon: mdi:battery
      
    - name: "UPS Remaining Runtime"
      state_topic: "pwrstat/power/ups"
      value_template: "{{ value_json['Remaining Runtime'] | regex_replace(' min', '') }}"
      unit_of_measurement: "min"
      icon: mdi:timer
      
    - name: "UPS Load Watts"
      state_topic: "pwrstat/power/ups"
      value_template: "{{ value_json['Load'].split('(')[0] | regex_replace(' Watt', '') }}"
      unit_of_measurement: "W"
      device_class: power
      icon: mdi:flash
      
    - name: "UPS Load Percentage"
      state_topic: "pwrstat/power/ups"
      value_template: >-
        {{ value_json['Load'].split('(')[1].split(' %')[0] if '(' in value_json['Load'] else '0' }}
      unit_of_measurement: "%"
      icon: mdi:percent
      
    - name: "UPS Line Interaction"
      state_topic: "pwrstat/power/ups"
      value_template: "{{ value_json['Line Interaction'] }}"
      icon: mdi:sine-wave
      
    - name: "UPS Last Power Event"
      state_topic: "pwrstat/power/ups"
      value_template: "{{ value_json['Last Power Event'] }}"
      icon: mdi:history
```

### Dashboard Card

Add this card to your Home Assistant dashboard:

```yaml
type: vertical-stack
cards:
  - type: horizontal-stack
    cards:
      - type: gauge
        entity: sensor.ups_battery_capacity
        name: Battery Level
        min: 0
        max: 100
        severity:
          green: 80
          yellow: 50
          red: 20
        needle: true
      - type: gauge
        entity: sensor.ups_load_percentage
        name: Load
        min: 0
        max: 100
        severity:
          green: 0
          yellow: 70
          red: 90
        needle: true
  
  - type: entities
    title: UPS Status
    show_header_toggle: false
    entities:
      - entity: sensor.ups_state
        name: Status
        icon: mdi:power-plug
      - entity: sensor.ups_power_supply
        name: Power Source
        icon: mdi:transmission-tower
      - entity: sensor.ups_remaining_runtime
        name: Runtime Left
        icon: mdi:timer
      - type: divider
      - entity: sensor.ups_utility_voltage
        name: Input Voltage
        icon: mdi:flash-triangle
      - entity: sensor.ups_output_voltage
        name: Output Voltage
        icon: mdi:flash
      - entity: sensor.ups_load_watts
        name: Load (Watts)
        icon: mdi:lightning-bolt
  
  - type: entities
    title: UPS Information
    show_header_toggle: false
    entities:
      - entity: sensor.ups_model
        name: Model
        icon: mdi:information
      - entity: sensor.ups_line_interaction
        name: Line Interaction
        icon: mdi:sine-wave
      - entity: sensor.ups_last_power_event
        name: Last Event
        icon: mdi:history
```

## Configuration Options

| Variable | Default | Description |
|----------|---------|-------------|
| `LOG_LEVEL` | INFO | Log level (DEBUG, INFO, WARNING, ERROR) |
| `MQTT_HOST` | localhost | MQTT broker hostname/IP |
| `MQTT_PORT` | 1883 | MQTT broker port |
| `MQTT_USER` | (empty) | MQTT username |
| `MQTT_PASS` | (empty) | MQTT password |
| `MQTT_PREFIX` | pwrstat | MQTT topic prefix |
| `MQTT_CLIENT_ID` | pwrstat | MQTT client ID |
| `MQTT_TOPIC` | power/ups | MQTT topic path |
| `MQTT_RETAIN` | true | MQTT retain messages |
| `MQTT_QOS` | 2 | MQTT quality of service |
| `MQTT_REFRESH` | 30 | Refresh interval in seconds |

## Alternative Data Access

### REST API
- **Endpoint**: `http://localhost:5003/pwrstat`
- **Method**: GET
- **Response**: JSON with UPS status

### Prometheus Metrics
- **Endpoint**: `http://localhost:9222/metrics`
- **Format**: Prometheus metrics format

## Testing MQTT Connection

Test from command line:
```bash
# Install MQTT clients
sudo apt install mosquitto-clients

# Listen for UPS data
mosquitto_sub -h YOUR_HA_IP -p 1883 -u mqtt_user -P mqtt_pass -t "pwrstat/power/ups" -v

# Test publishing
mosquitto_pub -h YOUR_HA_IP -p 1883 -u mqtt_user -P mqtt_pass -t "test/topic" -m "hello"
```

## Troubleshooting

### UPS Not Detected
- Ensure UPS is connected via USB
- Check USB device: `lsusb | grep -i cyber`
- Verify device permissions
- Try different USB port

### MQTT Connection Issues
- Verify MQTT broker is running in Home Assistant
- Check MQTT credentials
- Test with `mosquitto_sub` command above
- Ensure Home Assistant MQTT allows external connections

### Container Issues
```bash
# Check container logs
docker-compose logs pwrstat

# Check USB access in container
docker exec pwrstat lsusb
docker exec pwrstat pwrstat -status

# Restart container
docker-compose restart pwrstat
```

### No Data in Home Assistant
- Restart Home Assistant after adding sensors
- Check Developer Tools → MQTT → Listen to topic `pwrstat/power/ups`
- Verify sensor entity names match in dashboard YAML

## Sample Data

The UPS publishes JSON data like this:
```json
{
  "Model Name": "CP1500EPFCLCD",
  "Firmware Number": "CRMHW2000028", 
  "Rating Voltage": "230 V",
  "Rating Power": "900 Watt",
  "State": "Normal",
  "Power Supply by": "Utility Power",
  "Utility Voltage": "227 V",
  "Output Voltage": "227 V", 
  "Battery Capacity": "100 %",
  "Remaining Runtime": "38 min",
  "Load": "189 Watt(21 %)",
  "Line Interaction": "None",
  "Test Result": "Unknown",
  "Last Power Event": "None"
}
```

## Requirements

- Intel x64 Linux system
- Docker and Docker Compose
- CyberPower UPS with USB connection
- Home Assistant with MQTT integration

## Credits

Based on the original work by Daniel Winks:
- [HassOS-Addons/pwrstat](https://github.com/DanielWinks/HassOS-Addons/tree/main/pwrstat)

Converted to standalone Docker container for broader compatibility.