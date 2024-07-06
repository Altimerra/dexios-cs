import tkinter as tk
from tkinter import ttk
import paho.mqtt.client as mqtt

# MQTT setup
mqtt_broker_address = "localhost"  # Replace with your MQTT broker address
mqtt_client = mqtt.Client()

try:
    mqtt_client.connect(mqtt_broker_address, 1883, 60)
    print(f"Connected to MQTT broker at {mqtt_broker_address}")
except Exception as e:
    print(f"Could not connect to MQTT broker: {e}")

def send_mqtt_message(topic, message):
    mqtt_client.publish(topic, message)

motor_topics = [
    "dexioscs/value/mix",
    "dexioscs/value/mmd",
    "dexioscs/value/mrl",
    "dexioscs/value/mtf",
    "dexioscs/value/mto"
]

class RobotHandControl(tk.Tk):
    def __init__(self):
        super().__init__()
        self.title("Robot Hand Control")
        self.geometry("800x600")

        self.create_widgets()

        # Activity tracker to prevent GUI from going to sleep
        self.activity_tracker()
    
    def activity_tracker(self):
        # Dummy call to update IDLE event loop
        self.update_idletasks()
        # Schedule the next call
        self.after(1000, self.activity_tracker)  # Call every 1 second

    def create_widgets(self):
        # Create a notebook (tabbed interface)
        self.notebook = ttk.Notebook(self)
        self.notebook.pack(fill="both", expand=True, padx=10, pady=10)

        # Manual mode tab
        self.manual_tab = ttk.Frame(self.notebook)
        self.notebook.add(self.manual_tab, text="Manual")
        self.create_manual_mode_widgets(self.manual_tab)

        # PID mode tab
        self.pid_tab = ttk.Frame(self.notebook)
        self.notebook.add(self.pid_tab, text="PID")
        self.create_pid_mode_widgets(self.pid_tab)

        # Grasps mode tab
        self.grasps_tab = ttk.Frame(self.notebook)
        self.notebook.add(self.grasps_tab, text="Grasps")
        self.create_grasps_mode_widgets(self.grasps_tab)

        # Selecting manual tab by default
        self.notebook.select(self.manual_tab)

        # Event handler for tab changes
        self.notebook.bind("<<NotebookTabChanged>>", self.on_tab_change)

    def create_manual_mode_widgets(self, tab):
        # Sliders and buttons for motors
        sliders_frame = ttk.LabelFrame(tab, text="Motors Control")
        sliders_frame.pack(fill="both", expand=True, padx=10, pady=10)

        motor_names = ["Index", "Middle", "Ring and Small", "Thumb Distal", "Thumb Opposition"]
        self.manual_sliders = []
        self.manual_slider_labels = []
        self.manual_center_buttons = []
        self.manual_step = 20  # Step size for manual mode

        for i, motor_name in enumerate(motor_names):
            label = ttk.Label(sliders_frame, text=motor_name)
            label.grid(row=i, column=0, padx=10, pady=5, sticky="w")

            slider = ttk.Scale(sliders_frame, from_=-255, to=255, orient="horizontal", command=lambda val, idx=i: self.update_motor(idx, val, "manual"))
            slider.grid(row=i, column=1, padx=10, pady=5, sticky="we")
            self.manual_sliders.append(slider)

            value_label = ttk.Label(sliders_frame, text="0")
            value_label.grid(row=i, column=2, padx=10, pady=5)
            self.manual_slider_labels.append(value_label)

            minus_button = ttk.Button(sliders_frame, text="-", command=lambda idx=i: self.adjust_motor_value(idx, -self.manual_step, "manual"))
            minus_button.grid(row=i, column=3, padx=5, pady=5)

            plus_button = ttk.Button(sliders_frame, text="+", command=lambda idx=i: self.adjust_motor_value(idx, self.manual_step, "manual"))
            plus_button.grid(row=i, column=4, padx=5, pady=5)

            reset_button = ttk.Button(sliders_frame, text="Reset", command=lambda idx=i: self.center_slider(idx, "manual"))
            reset_button.grid(row=i, column=5, padx=5, pady=5)

        # Solenoids control
        solenoids_frame = ttk.LabelFrame(tab, text="Solenoids Control")
        solenoids_frame.pack(fill="x", padx=10, pady=10)

        self.solenoid1_state = tk.StringVar(value="OFF")
        self.solenoid2_state = tk.StringVar(value="OFF")

        solenoid1_button = ttk.Button(solenoids_frame, textvariable=self.solenoid1_state, command=lambda: self.toggle_solenoid(1))
        solenoid1_button.pack(side="left", padx=10)

        solenoid2_button = ttk.Button(solenoids_frame, textvariable=self.solenoid2_state, command=lambda: self.toggle_solenoid(2))
        solenoid2_button.pack(side="left", padx=10)

        # Activate button for Manual mode
        activate_manual_button = ttk.Button(tab, text="Activate Manual Mode", command=self.activate_manual_mode)
        activate_manual_button.pack(pady=10)

    def create_pid_mode_widgets(self, tab):
        # Sliders and buttons for motors
        sliders_frame = ttk.LabelFrame(tab, text="Motors Control")
        sliders_frame.pack(fill="both", expand=True, padx=10, pady=10)

        motor_names = ["Index", "Middle", "Ring and Small", "Thumb Distal", "Thumb Opposition"]
        self.pid_sliders = []
        self.pid_slider_labels = []
        self.pid_reset_buttons = []
        self.pid_step = 500  # Step size for PID mode

        for i, motor_name in enumerate(motor_names):
            label = ttk.Label(sliders_frame, text=motor_name)
            label.grid(row=i, column=0, padx=10, pady=5, sticky="w")

            slider = ttk.Scale(sliders_frame, from_=0, to=12000, orient="horizontal", command=lambda val, idx=i: self.update_motor(idx, val, "pid"))
            slider.grid(row=i, column=1, padx=10, pady=5, sticky="we")
            self.pid_sliders.append(slider)

            value_label = ttk.Label(sliders_frame, text="0")
            value_label.grid(row=i, column=2, padx=10, pady=5)
            self.pid_slider_labels.append(value_label)

            minus_button = ttk.Button(sliders_frame, text="-", command=lambda idx=i: self.adjust_motor_value(idx, -self.pid_step, "pid"))
            minus_button.grid(row=i, column=3, padx=5, pady=5)

            plus_button = ttk.Button(sliders_frame, text="+", command=lambda idx=i: self.adjust_motor_value(idx, self.pid_step, "pid"))
            plus_button.grid(row=i, column=4, padx=5, pady=5)

            reset_button = ttk.Button(sliders_frame, text="Reset", command=lambda idx=i: self.center_slider(idx, "pid"))
            reset_button.grid(row=i, column=5, padx=5, pady=5)

        # Solenoids control
        solenoids_frame = ttk.LabelFrame(tab, text="Solenoids Control")
        solenoids_frame.pack(fill="x", padx=10, pady=10)

        solenoid1_button = ttk.Button(solenoids_frame, text="OFF", command=lambda: self.toggle_solenoid(1))
        solenoid1_button.pack(side="left", padx=10)

        solenoid2_button = ttk.Button(solenoids_frame, text="OFF", command=lambda: self.toggle_solenoid(2))
        solenoid2_button.pack(side="left", padx=10)

        # Activate button for PID mode
        activate_pid_button = ttk.Button(tab, text="Activate PID Mode", command=self.activate_pid_mode)
        activate_pid_button.pack(pady=10)

    def create_grasps_mode_widgets(self, tab):
        # Dropdown for grasps selection
        grasps_frame = ttk.Frame(tab)
        grasps_frame.pack(expand=True)

        ttk.Label(grasps_frame, text="Select Grasp:").pack(pady=10)

        grasps_options = ["None", "Pinch", "Spherical"]
        self.grasps_dropdown = ttk.Combobox(grasps_frame, values=grasps_options, state="readonly")
        self.grasps_dropdown.pack(pady=10)
        self.grasps_dropdown.current(0)  # Set initial state to "None"

        # Reset button for Grasp mode
        reset_grasp_button = ttk.Button(tab, text="Reset", command=self.reset_grasp)
        reset_grasp_button.pack(pady=10)

        # Activate button for Grasps mode
        activate_grasp_button = ttk.Button(tab, text="Activate Grasps Mode", command=self.activate_grasp_mode)
        activate_grasp_button.pack(pady=10)

    def reset_grasp(self):
        self.grasps_dropdown.current(0)
        send_mqtt_message("dexioscs/grasp", "none")

    def activate_manual_mode(self):
        send_mqtt_message("dexioscs/mode", "manual")

    def activate_pid_mode(self):
        send_mqtt_message("dexioscs/mode", "pid")

    def activate_grasp_mode(self):
        if self.grasps_dropdown.get() != "None":
            send_mqtt_message("dexioscs/grasp", self.grasps_dropdown.get().lower())
        else:
            send_mqtt_message("dexioscs/mode", "grasp")

    def center_slider(self, idx, mode):
        if mode == "manual":
            self.manual_sliders[idx].set(0)
        elif mode == "pid":
            self.pid_sliders[idx].set(0)
        self.update_slider_labels(mode)

    def adjust_motor_value(self, idx, step, mode):
        current_value = int(self.manual_slider_labels[idx].cget("text")) if mode == "manual" else int(self.pid_slider_labels[idx].cget("text"))
        new_value = current_value + step
        if mode == "manual":
            if -255 <= new_value <= 255:
                self.manual_sliders[idx].set(new_value)
                self.update_motor(idx, new_value, mode)
        elif mode == "pid":
            if 0 <= new_value <= 12000:
                self.pid_sliders[idx].set(new_value)
                self.update_motor(idx, new_value, mode)

    def update_motor(self, motor_idx, value, mode):
        value = int(float(value))
        if mode == "manual":
            self.manual_slider_labels[motor_idx].config(text=f"{value}")
        elif mode == "pid":
            self.pid_slider_labels[motor_idx].config(text=f"{value}")

        topic = motor_topics[motor_idx]
        send_mqtt_message(topic, value)

    def toggle_solenoid(self, solenoid_idx):
        if solenoid_idx == 1:
            current_state = self.solenoid1_state.get()
            new_state = "OFF" if current_state == "ON" else "ON"
            self.solenoid1_state.set(new_state)
            send_mqtt_message(f"dexioscs/value/six", new_state.lower())
        elif solenoid_idx == 2:
            current_state = self.solenoid2_state.get()
            new_state = "OFF" if current_state == "ON" else "ON"
            self.solenoid2_state.set(new_state)
            send_mqtt_message(f"dexioscs/value/smd", new_state.lower())

    def on_tab_change(self, event=None):
        selected_tab = event.widget.select()

        if selected_tab == self.manual_tab:
            send_mqtt_message("dexioscs/mode", "manual")

        elif selected_tab == self.pid_tab:
            send_mqtt_message("dexioscs/mode", "pid")

        elif selected_tab == self.grasps_tab:
            # Check if grasp dropdown is set to "None" to avoid unnecessary messages
            if self.grasps_dropdown.get() != "None":
                send_mqtt_message("dexioscs/grasp", self.grasps_dropdown.get().lower())
            else:
                send_mqtt_message("dexioscs/mode", "grasp")

    def update_slider_labels(self, mode):
        if mode == "manual":
            for i, slider in enumerate(self.manual_sliders):
                value = int(slider.get())
                self.manual_slider_labels[i].config(text=f"{value}")

                send_mqtt_message(motor_topics[i], value)
        elif mode == "pid":
            for i, slider in enumerate(self.pid_sliders):
                value = int(slider.get())
                self.pid_slider_labels[i].config(text=f"{value}")
                send_mqtt_message(motor_topics[i], value)

if __name__ == "__main__":
    app = RobotHandControl()
    app.mainloop()
