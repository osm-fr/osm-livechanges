#! /usr/bin/env python3

import json
import os
import sqlite3
import time

print("Content-Type: application/json")
print()

try:
    data = {}
    ts = []

    scale = int(os.environ["QUERY_STRING"].split('=')[1])
    max_delay = 600

    now = int(time.mktime(time.gmtime()))
    now_aligned = now - now % scale
    beg = (now - max_delay)

    db = sqlite3.connect("../backend/changesets.db")
    db.execute("PRAGMA journal_mode=WAL")
    db.execute("PRAGMA busy_timeout=5000")
    db.row_factory = sqlite3.Row
    c = db.cursor()

    rows = []
    max_valid_timestamp = 0
    for row in c.execute("SELECT * from changeset where time > ? ORDER BY time", (beg,)):
        rows.append(row)
        max_valid_timestamp = row["time"]

    data["debug"] = f"I want data from {now_aligned - max_delay} to {now_aligned} and my max is {max_valid_timestamp}"

    def copy(row):
        x = {}
        for key in row.keys():
            x[key] = row[key]
        return x

    for bucket_time in range(now_aligned - max_delay, now_aligned, scale):
        e = {"time": bucket_time, "nbChangesets": 0, "totalActivity": 0,
             "cnode": 0, "mnode": 0, "dnode": 0,
             "cway": 0, "mway": 0, "dway": 0,
             "crel": 0, "mrel": 0, "drel": 0, "changesets": []}
        for row in rows:
            rowTime = int(row["time"])
            if rowTime >= bucket_time and rowTime < bucket_time + scale:
                rowCopy = copy(row)
                rowCopy["countries"] = []
                e["changesets"].append(rowCopy)
                e["cnode"] += int(row["cnode"])
                e["mnode"] += int(row["mnode"])
                e["dnode"] += int(row["dnode"])
                e["cway"] += int(row["cway"])
                e["mway"] += int(row["mway"])
                e["dway"] += int(row["dway"])
                e["crel"] += int(row["crel"])
                e["mrel"] += int(row["mrel"])
                e["drel"] += int(row["drel"])
                e["nbChangesets"] += 1
        e["totalActivity"] += e["cnode"] + e["mnode"] + e["dnode"]
        e["totalActivity"] += e["cway"] + e["mway"] + e["dway"]
        e["totalActivity"] += e["crel"] + e["mrel"] + e["drel"]
        ts.append(e)
        if bucket_time > max_valid_timestamp:
            break

    data["timeseries"] = ts
    print(json.dumps(data))

except Exception as e:
    print(json.dumps({"error": str(e)}))

