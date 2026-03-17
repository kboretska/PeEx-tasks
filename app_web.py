import multiprocessing
import time
from flask import Flask, render_template, request, jsonify

app = Flask(__name__)


class CPULoadSimulator:
    @staticmethod
    def run(duration_seconds: int):
        end_time = time.time() + duration_seconds
        while time.time() < end_time:
            sum(i * i for i in range(10000))


@app.route('/')
def index():
    return render_template('index.html')


@app.route('/health')
def health():
    return jsonify({"status": "ok"}), 200


@app.route('/start', methods=['POST'])
def start_load():
    data = request.get_json(silent=True) or {}

    duration = int(data.get('duration', 5))
    cores = int(data.get('cores', 1))

    if duration <= 0:
        return jsonify({"error": "duration must be greater than 0"}), 400

    if cores < 0:
        return jsonify({"error": "cores must be 0 or greater"}), 400

    max_cores = multiprocessing.cpu_count()
    cores_to_use = max_cores if cores == 0 else min(cores, max_cores)

    for _ in range(cores_to_use):
        multiprocessing.Process(
            target=CPULoadSimulator.run,
            args=(duration,)
        ).start()

    return jsonify({
        "status": f"Load started on {cores_to_use} cores for {duration} seconds."
    })


if __name__ == "__main__":
    app.run(host='0.0.0.0', port=5000)