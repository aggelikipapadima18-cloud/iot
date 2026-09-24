#!/usr/bin/env python3
"""
Read sensor lines from TinyOS PrintfClient and store them in MongoDB.

Expected input line:
ID=5 Count=12 Temp=3021 Humidity=4210 Photo=15 Solar=44
"""

import argparse
import datetime
import json
import os
import re
import sys


FIELD_RE = re.compile(
    r"\b(ID|Count|Temp|Humidity|Photo|Solar)\s*[:=]\s*(-?\d+)\b",
    re.IGNORECASE,
)

FIELD_NAMES = {
    "id": "mote_id",
    "count": "count",
    "temp": "temperature",
    "humidity": "humidity",
    "photo": "photo",
    "solar": "solar",
}

REQUIRED_FIELDS = set(["mote_id", "count", "temperature", "humidity"])


def parse_sensor_line(line):
    record = {}
    for key, value in FIELD_RE.findall(line):
        record[FIELD_NAMES[key.lower()]] = int(value)

    if not REQUIRED_FIELDS.issubset(set(record.keys())):
        return None

    record["timestamp"] = datetime.datetime.utcnow()
    record["raw_line"] = line.strip()
    return record


def printable_record(record):
    result = dict(record)
    result["timestamp"] = result["timestamp"].isoformat() + "Z"
    if "_id" in result:
        result["_id"] = str(result["_id"])
    return json.dumps(result, sort_keys=True)


def get_collection(args):
    try:
        from pymongo import MongoClient
    except ImportError:
        print(
            "Missing dependency: install pymongo with `python3 -m pip install -r requirements.txt`.",
            file=sys.stderr,
        )
        raise SystemExit(2)

    client = MongoClient(args.mongo_uri, serverSelectionTimeoutMS=5000)
    client.admin.command("ping")
    return client[args.database][args.collection]


def iter_input_lines(args):
    if args.sample_line:
        for line in args.sample_line:
            yield line
        return

    for line in sys.stdin:
        yield line


def main():
    parser = argparse.ArgumentParser(description="Store TinyOS sensor readings in MongoDB.")
    parser.add_argument(
        "--mongo-uri",
        default=os.environ.get("MONGODB_URI", "mongodb://localhost:27017"),
        help="MongoDB connection string. Default: mongodb://localhost:27017 or MONGODB_URI.",
    )
    parser.add_argument("--database", default="wsn_project", help="MongoDB database name.")
    parser.add_argument("--collection", default="samples", help="MongoDB collection name.")
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Parse and print records without connecting to MongoDB.",
    )
    parser.add_argument(
        "--sample-line",
        action="append",
        help="Parse this line instead of stdin. Can be passed multiple times.",
    )
    args = parser.parse_args()

    collection = None if args.dry_run else get_collection(args)

    for line in iter_input_lines(args):
        record = parse_sensor_line(line)
        if record is None:
            if line.strip():
                print("skip: {0}".format(line.strip()), file=sys.stderr)
            continue

        if args.dry_run:
            print(printable_record(record))
        else:
            result = collection.insert_one(record)
            print("inserted {0}: {1}".format(result.inserted_id, printable_record(record)))
            sys.stdout.flush()


if __name__ == "__main__":
    main()
