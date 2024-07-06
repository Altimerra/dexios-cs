import serial
import threading
import time
import logging
import json
import paho.mqtt.client as mqtt

# Configure logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(message)s')
logger = logging.getLogger(__name__)

# MQTT broker settings
MQTT_BROKER = "localhost"  # Replace with your MQTT broker address
MQTT_PORT = 1883  # MQTT broker port (default: 1883)

# Serial port settings
SERIAL_PORT = 'COM12'  # Replace with your Arduino's serial port
BAUD_RATE = 115200

# Function to generate multiple JSON strings for "dexioscs/grasp" topic
def generate_grasp_messages(grasp_value):
    grasps = {
        "spherical" : [
            {"actuator": "mix", "val": -3000, "action": "setval"},
            {"actuator": "mmd", "val": -3500, "action": "setval"},
            {"actuator": "mrl", "val": 7000, "action": "setval"},
            {"actuator": "mto", "val": -4000, "action": "setval"},
        ],
        "pinch" : [
            {"actuator": "mix", "val": -3500, "action": "setval"},
            {"actuator": "mto", "val": -7000, "action": "setval"},
        ],
        "none" : [
            {"actuator": "mix", "val": 0, "action": "setval"},
            {"actuator": "mmd", "val": 0, "action": "setval"},
            {"actuator": "mrl", "val": 0, "action": "setval"},
            {"actuator": "mto", "val": 0, "action": "setval"},
        ],
    }
    grasp_commands = grasps[grasp_value]
    return [json.dumps(command) for command in grasp_commands]

# Mapping of MQTT topics to Arduino commands (with JSON data)
topic_commands = {
    "dexioscs/value/mix": lambda value: json.dumps({"actuator": "mix", "val": -int(value), "action": "setval"}),
    "dexioscs/value/mrl": lambda value: json.dumps({"actuator": "mrl", "val": int(value), "action": "setval"}),
    "dexioscs/value/mtf": lambda value: json.dumps({"actuator": "mtf", "val": int(value), "action": "setval"}),
    "dexioscs/value/mmd": lambda value: json.dumps({"actuator": "mmd", "val": -int(value), "action": "setval"}),
    "dexioscs/value/mto": lambda value: json.dumps({"actuator": "mto", "val": -int(value), "action": "setval"}),
    "dexioscs/value/six": lambda value: json.dumps({"actuator": "six", "val": value == "on", "action": "setval"}),
    "dexioscs/value/smd": lambda value: json.dumps({"actuator": "smd", "val": value == "on", "action": "setval"}),
    "dexioscs/mode": lambda value: json.dumps({"val": value, "action": "modesel"}),
    "dexioscs/grasp": generate_grasp_messages,
}

# Function to read from serial port in a separate thread
def serial_read(serial_port):
    while True:
        if serial_port.in_waiting > 0:
            message = serial_port.readline().decode().strip()
            logger.info(f"Received from Arduino: {message}")

# Function to create message to send to Arduino based on MQTT topic and message
def create_message(topic, payload):
    if topic in topic_commands:
        return topic_commands[topic](payload)
    else:
        logger.warning(f"Unknown MQTT topic: {topic}")
        return None

# Function to send message to Arduino
def send_message_to_arduino(serial_port, message):
    serial_port.write(message.encode())
    logger.info(f"Sent to Arduino: {message}")

# Callback when MQTT message is received
def on_message(client, userdata, message):
    topic = message.topic
    payload = message.payload.decode()
    logger.info(f"Received MQTT message on topic '{topic}': {payload}")
    
    # Create message to send to Arduino based on MQTT topic and payload
    arduino_messages = create_message(topic, payload)
    if arduino_messages:
        if isinstance(arduino_messages, list):
            for arduino_message in arduino_messages:
                send_message_to_arduino(serial_port, arduino_message)
        else:
            send_message_to_arduino(serial_port, arduino_messages)

# Set up MQTT client
mqtt_client = mqtt.Client()
mqtt_client.on_message = on_message

# Connect to MQTT broker
mqtt_client.connect(MQTT_BROKER, MQTT_PORT)
# Subscribe to all MQTT topics in topic_commands
for topic in topic_commands:
    mqtt_client.subscribe(topic)

# Open serial port
serial_port = serial.Serial(SERIAL_PORT, BAUD_RATE, timeout=1)

# Create and start the serial read thread
read_thread = threading.Thread(target=serial_read, args=(serial_port,), daemon=True)
read_thread.start()

# Start MQTT loop to listen for messages
mqtt_client.loop_start()

try:
    while True:
        time.sleep(1)  # Main loop can perform other tasks or sleep
except KeyboardInterrupt:
    logger.info("KeyboardInterrupt: Exiting...")
    mqtt_client.disconnect()
    serial_port.close()
