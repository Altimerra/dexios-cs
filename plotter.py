import paho.mqtt.client as mqtt
import matplotlib.pyplot as plt
import matplotlib.animation as animation

# MQTT settings
MQTT_BROKER = "localhost"
MQTT_PORT = 1883
MQTT_TOPICS = [("dexioscs/value/mix", 0), ("dexioscs/value/mmd", 0)]  # List of tuples (topic, qos)

# Data storage
data = {topic: [] for topic, _ in MQTT_TOPICS}
timestamps = {topic: [] for topic, _ in MQTT_TOPICS}

# Set up the figure and axis
fig, ax = plt.subplots()
lines = {topic: ax.plot([], [], label=topic)[0] for topic, _ in MQTT_TOPICS}

# Function to update the plot
def update(frame):
    for topic in MQTT_TOPICS:
        t = topic[0]
        if len(data[t]) > 0:
            lines[t].set_data(timestamps[t], data[t])
            ax.relim()
            ax.autoscale_view()
    ax.legend()
    return lines.values()

# MQTT callback functions
def on_connect(client, userdata, flags, rc):
    print("Connected with result code "+str(rc))
    client.subscribe(MQTT_TOPICS)

def on_message(client, userdata, msg):
    topic = msg.topic
    payload = float(msg.payload.decode())
    data[topic].append(payload)
    timestamps[topic].append(len(data[topic]))

# Set up the MQTT client
client = mqtt.Client()
client.on_connect = on_connect
client.on_message = on_message
client.connect(MQTT_BROKER, MQTT_PORT, 60)

# Start the MQTT client loop in a separate thread
client.loop_start()

# Set up the animation
ani = animation.FuncAnimation(fig, update, frames=None, blit=True, interval=1000)

# Show the plot
plt.show()

# Stop the MQTT client loop when the plot window is closed
client.loop_stop()
client.disconnect()
