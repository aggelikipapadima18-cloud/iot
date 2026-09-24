# IoT - End-to-end Wireless Sensor Network

Υλοποίηση εργασίας IoT/WSN μέχρι το Ερώτημα 2.

## Τι περιέχει

- `examples/Blink`: βασικό TinyOS παράδειγμα LED blink με printf υποστήριξη.
- `examples/BlinkToRadio`: TinyOS παράδειγμα αποστολής/λήψης radio μηνυμάτων.
- `examples/Sensing`: τροποποιημένο sensing παράδειγμα για τοπολογία αστέρα.
- `tools/mongo_ingest.py`: Python script που διαβάζει γραμμές από `PrintfClient` και τις αποθηκεύει σε MongoDB.
- `docker-compose.yml`: προαιρετική εκκίνηση MongoDB με Docker.
- `ANAFORA_ERGASIAS.md`: συνοπτική αναφορά της υλοποίησης.

## Ερώτημα 1

Το `examples/Sensing` ρυθμίστηκε ώστε να δουλεύει ως star topology:

- base station: node id `0`,
- leaf motes: node ids `1`, `2`, ...,
- αποστολή μετρήσεων κάθε 20 δευτερόλεπτα,
- εκτύπωση κάθε μέτρησης σε μία γραμμή για εύκολο parsing.

Η βασική ρύθμιση βρίσκεται στο:

```text
examples/Sensing/SensingConstants.h
```

Παράδειγμα γραμμής εξόδου:

```text
ID=5 Count=12 Temp=3021 Humidity=4210 Photo=15 Solar=44
```

## Ερώτημα 2

Η MongoDB χρησιμοποιείται για αποθήκευση των μετρήσεων στη βάση `wsn_project` και στο collection `samples`.

Εκκίνηση MongoDB στο Ubuntu VM:

```bash
sudo apt-get update
sudo apt-get install -y mongodb
sudo systemctl enable mongodb
sudo systemctl restart mongodb
mongo --quiet --eval 'printjson(db.runCommand({ping: 1}))'
```

Εναλλακτικά με Docker:

```bash
docker compose up -d mongodb
```

Εγκατάσταση Python dependency:

```bash
sudo apt-get install -y python3-pymongo
# ή
python3 -m pip install -r requirements.txt
```

Dry-run του parser:

```bash
python3 tools/mongo_ingest.py --dry-run --sample-line "ID=5 Count=12 Temp=3021 Humidity=4210 Photo=15 Solar=44"
```

Live ροή με TelosB base:

```bash
sudo java net.tinyos.sf.SerialForwarder -comm serial@/dev/ttyUSB0:telosb -port 9002
sudo java net.tinyos.tools.PrintfClient -comm sf@localhost:9002 | python3 tools/mongo_ingest.py
```

Έλεγχος τελευταίων δεδομένων:

```bash
mongo wsn_project --quiet --eval 'db.samples.find().sort({timestamp: -1}).limit(5).pretty()'
```

## Flash παραδείγματα

Base node για TelosB:

```bash
cd examples/Sensing/Base
sudo make telosb install.0 bsl,/dev/ttyUSB0 SENSOR_DIR=tmote_onboard_sensors
```

Leaf node για TelosB:

```bash
cd examples/Sensing/Sampler
sudo make telosb install.1 bsl,/dev/ttyUSB0 SENSOR_DIR=tmote_onboard_sensors
```

Για IRIS χρησιμοποιείται target `iris` και programmer `mib520,/dev/ttyUSBx`.
