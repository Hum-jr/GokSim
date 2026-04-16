# 🚀 Göksim (Gök Simülasyonu)

**Göksim** is an interactive, 3D aerospace launch simulator and decision-support system built with Godot 4. Developed for the **TUA Astrohackathon**, this project allows users to select any coordinate on Earth, fetch live atmospheric data, and simulate a physics-accurate rocket launch sequence based on real-world Launch Commit Criteria (LCC).

## ✨ Key Features

* 🌍 **Interactive 3D Globe:** Select any launch site globally. The system automatically translates 3D raycast coordinates into precise Latitude and Longitude.
* 📡 **Live NOAA GFS Integration:** Fetches real-time temperature, wind speed, precipitation, cloud cover, and humidity data via the Open-Meteo API.
* 🧠 **Smart Offline Fallback:** If network connections fail (e.g., behind strict enterprise/university firewalls), Göksim's procedural algorithm calculates realistic simulated weather based on the selected latitude.
* 🛑 **Autonomous Flight Computer:** Evaluates Launch Commit Criteria (LCC). If conditions are unsafe (e.g., high wind shear, lightning risk, or cryogenic fuel freezing temperatures), the system autonomously aborts the ignition sequence.
* 🚀 **Realistic Flight Dynamics:** The physics engine calculates thrust and drag dynamically. It uses the Barometric Formula and the Ideal Gas Law to calculate real-time air density at the launch site:
    * **Pressure:** $P = P_0 \cdot \exp(-h / 8500)$
    * **Air Density:** $\rho = \frac{P}{R \cdot T}$
* منحنی **Hyperbolic Trajectory (Gravity Turn):** Upon clearing the tower, the rocket automatically executes a mathematically driven gravity turn, pitching downrange to simulate orbital insertion.

## 🛠️ Tech Stack

* **Game Engine:** [Godot Engine 4.x](https://godotengine.org/)
* **Language:** GDScript
* **APIs:** Open-Meteo (NOAA GFS Forecast, Global Elevation API)
* **Assets:** Custom 3D meshes (Blender) and GPU Particles (Godot)

## ⚙️ How It Works (The 3 Pillars)

1.  **The Global Brain (`LaunchData.gd`):** A Singleton Autoload that securely passes payload, telemetry, and environmental data between scenes.
2.  **Mission Control (`globe_manager.gd`):** Handles the interactive 3D UI, asynchronous HTTP requests, and the procedural offline weather logic.
3.  **Flight Physics (`rocket.gd`):** A `RigidBody3D` script that acts as the flight computer. It calculates the aerodynamic drag, local thrust vectors, and manages the T-Minus 3 second ignition countdown.

## 🚀 Installation & Running

1. Clone the repository: `git clone https://github.com/YOUR-USERNAME/goksim.git`
2. Open the **Godot 4 Project Manager**.
3. Click **Import** and navigate to the `project.godot` file in the cloned folder.
4. Press `F5` to run the simulation. 
5. *Note: Ensure TLS options in Godot's network settings allow for `client_unsafe()` if testing on restricted networks.*

## 🧑‍💻 Author
Built for the **TUA Astrohackathon**.
