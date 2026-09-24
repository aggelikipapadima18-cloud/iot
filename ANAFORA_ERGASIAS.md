# Αναφορά Εργασίας

## Project 1: End-to-end Wireless Sensor Networks

Η εργασία υλοποιεί ένα ασύρματο δίκτυο αισθητήρων με TinyOS και αποθήκευση μετρήσεων σε MongoDB. Η παρούσα έκδοση καλύπτει τα Ερωτήματα 1 και 2.

## Περιβάλλον

Η ανάπτυξη έγινε σε Ubuntu 16.04 μέσα από VirtualBox. Χρησιμοποιήθηκαν TinyOS, `nescc`, `make`, εργαλεία για TelosB/IRIS, Java TinyOS tools, Python 3, PyMongo και MongoDB.

## Ερώτημα 1

Αρχικά επαληθεύτηκε ότι τα παραδείγματα `Blink`, `BlinkToRadio` και `Sensing` μεταγλωττίζονται. Στη συνέχεια το `examples/Sensing` προσαρμόστηκε σε τοπολογία αστέρα.

Η τοπολογία είναι:

- base station με node id `0`,
- leaf motes με node ids `1`, `2`, κ.λπ.,
- περιοδική αποστολή μετρήσεων από τα leaf motes,
- λήψη και εκτύπωση των μετρήσεων από τον base κόμβο.

Στο `examples/Sensing/SensingConstants.h` ορίστηκαν οι βασικές σταθερές:

```c
SAMPLING_INTERVAL = 20000
BASE_STATION_ADDR = 0
```

Το `SAMPLING_INTERVAL = 20000` σημαίνει ότι οι leaf κόμβοι στέλνουν μετρήσεις κάθε 20 δευτερόλεπτα. Η εκτύπωση στον base κόμβο γίνεται σε μορφή μίας γραμμής:

```text
ID=5 Count=12 Temp=3021 Humidity=4210 Photo=15 Solar=44
```

Αυτή η μορφή επιλέχθηκε ώστε να μπορεί να γίνει εύκολα parsing στο Ερώτημα 2.

## Ερώτημα 2

Για την αποθήκευση των δεδομένων εγκαταστάθηκε και ελέγχθηκε MongoDB. Η βάση που χρησιμοποιείται είναι `wsn_project` και το collection είναι `samples`.

Δημιουργήθηκε το script:

```text
tools/mongo_ingest.py
```

Το script διαβάζει γραμμές από το standard input, κάνει parse τα πεδία `ID`, `Count`, `Temp`, `Humidity`, `Photo`, `Solar` και αποθηκεύει κάθε μέτρηση στη MongoDB ως document με τα πεδία:

```text
timestamp, mote_id, count, temperature, humidity, photo, solar, raw_line
```

Παράδειγμα εκτέλεσης με πραγματική ροή από TinyOS:

```bash
sudo java net.tinyos.sf.SerialForwarder -comm serial@/dev/ttyUSB0:telosb -port 9002
sudo java net.tinyos.tools.PrintfClient -comm sf@localhost:9002 | python3 tools/mongo_ingest.py
```

Παράδειγμα ελέγχου parser:

```bash
python3 tools/mongo_ingest.py --dry-run --sample-line "ID=5 Count=12 Temp=3021 Humidity=4210 Photo=15 Solar=44"
```

Παράδειγμα ελέγχου δεδομένων στη MongoDB:

```bash
mongo wsn_project --quiet --eval 'db.samples.find().sort({timestamp: -1}).limit(5).pretty()'
```

## Συμπέρασμα

Η εργασία οργανώνει το δίκτυο σε τοπολογία αστέρα, ρυθμίζει τους leaf κόμβους να στέλνουν μετρήσεις κάθε 20 δευτερόλεπτα και παρέχει μηχανισμό αποθήκευσης των δεδομένων σε MongoDB. Το επόμενο πρακτικό βήμα είναι η τελική εκτέλεση με πραγματικά motes, ώστε να επιβεβαιωθεί live ότι οι μετρήσεις περνούν από το TinyOS στη MongoDB.
