#!/bin/bash

echo "===== HOSPITAL CPU SCHEDULER ====="

echo "Enter number of patients:"
read n

input_data=""

for ((i=1; i<=n; i++))
do
  echo "Enter arrival burst priority for Patient $i:"
  read line
  input_data+="$line\n"
done

echo "Choose Scheduling Algorithm:"
echo "1. FCFS"
echo "2. Priority"
echo "3. Round Robin"
read choice

echo "Enter Time Quantum (only for RR, else 0):"
read tq

python3 <<EOF

class Patient:
    def __init__(self, pid, arrival, burst, priority):
        self.pid = pid
        self.arrival = arrival
        self.burst = burst
        self.priority = priority
        self.waiting = 0
        self.turnaround = 0

n = int("$n")
data = """$input_data""".split("\\n")
choice = int("$choice")
tq = int("$tq")

# 🔥 REMOVE EMPTY LINES (FIX)
valid_data = []
for line in data:
    if line.strip() != "":
        valid_data.append(line)

patients = []

for i in range(n):
    a, b, p = map(int, valid_data[i].split())
    patients.append(Patient(i+1, a, b, p))

time = 0
gantt = []

# ---------------- FCFS ----------------
if choice == 1:
    patients.sort(key=lambda x: x.arrival)

    for p in patients:
        if time < p.arrival:
            time = p.arrival
        p.waiting = time - p.arrival
        time += p.burst
        p.turnaround = p.waiting + p.burst
        gantt.append((p.pid, time))

# ---------------- PRIORITY ----------------
elif choice == 2:
    remaining = patients[:]

    while remaining:
        ready = [p for p in remaining if p.arrival <= time]

        if not ready:
            time += 1
            continue

        p = min(ready, key=lambda x: x.priority)

        p.waiting = time - p.arrival
        time += p.burst
        p.turnaround = p.waiting + p.burst

        gantt.append((p.pid, time))
        remaining.remove(p)

# ---------------- ROUND ROBIN ----------------
elif choice == 3:
    queue = patients[:]
    rem_bt = {p.pid: p.burst for p in patients}

    while queue:
        p = queue.pop(0)

        if rem_bt[p.pid] > tq:
            time += tq
            rem_bt[p.pid] -= tq
            gantt.append((p.pid, time))
            queue.append(p)
        else:
            time += rem_bt[p.pid]
            p.waiting = time - p.arrival - p.burst
            p.turnaround = p.waiting + p.burst
            gantt.append((p.pid, time))
            rem_bt[p.pid] = 0

# ---------------- OUTPUT ----------------

print("\\n===== GANTT CHART =====")
print("0", end=" ")
for pid, t in gantt:
    print(f"| P{pid} | {t}", end=" ")
print()

print("\\n===== RESULTS =====")
total_wt = total_tat = 0

for p in patients:
    print(f"P{p.pid}: Waiting Time = {p.waiting}, Turnaround Time = {p.turnaround}")
    total_wt += p.waiting
    total_tat += p.turnaround

print(f"\\nAverage Waiting Time: {total_wt/n:.2f}")
print(f"Average Turnaround Time: {total_tat/n:.2f}")

EOF
