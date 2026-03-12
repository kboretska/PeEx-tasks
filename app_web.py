import multiprocessing
import time
from flask import Flask, render_template, request, jsonify

app = Flask(__name__)

class CPULoadSimulator:
    @staticmethod
    def run(duration_seconds: int):
        end_time = time.time() + duration_seconds
        while time.time() < end_time:
            _ = 100 * 100

@app.route('/')
def index():
    return render_template('index.html')

@app.route('/start', methods=['POST'])
def start_load():
    data = request.json
    duration = data.get('duration', 5)
    cores = data.get('cores', 1)
    
    cores_to_use = multiprocessing.cpu_count() if cores == 0 else cores
    
    for _ in range(cores_to_use):
        multiprocessing.Process(target=CPULoadSimulator.run, args=(duration,)).start()
        
    return jsonify({"status": f"Load started on {cores_to_use} cores for {duration} seconds."})

if __name__ == "__main__":
    app.run(host='0.0.0.0', port=5000)