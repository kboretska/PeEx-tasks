"""Desktop version"""
import tkinter as tk
from tkinter import messagebox
import multiprocessing
import time
import os


def cpu_load_task(duration):
    end_time = time.time() + duration
    while time.time() < end_time:
        _ = 100 * 100


class LoadApp:
    def __init__(self, root):
        self.root = root
        self.root.title("Load Simulator")
        self.root.geometry("300x400")
        self.processes = []

        tk.Label(root, text="Server Load Simulator", font=("Arial", 14, "bold")).pack(
            pady=20
        )

        tk.Button(
            root,
            text="Low Load (5s)",
            command=lambda: self.start_load(1, 5),
            bg="#90ee90",
            width=20,
        ).pack(pady=10)

        tk.Button(
            root,
            text="Medium Load (10s)",
            command=lambda: self.start_load(2, 10),
            bg="#ffdb58",
            width=20,
        ).pack(pady=10)

        tk.Button(
            root,
            text="HIGH LOAD (15s)",
            command=lambda: self.start_load(multiprocessing.cpu_count(), 15),
            bg="#ff4500",
            fg="white",
            width=20,
        ).pack(pady=10)

    def start_load(self, cores, duration):
        messagebox.showinfo("Status", f"Запуск навантаження на {cores} ядрах...")
        for _ in range(cores):
            p = multiprocessing.Process(target=cpu_load_task, args=(duration,))
            p.start()
            self.processes.append(p)


if __name__ == "__main__":
    multiprocessing.freeze_support()
    root = tk.Tk()
    app = LoadApp(root)
    root.mainloop()