import os
import glob
from datetime import datetime

# An output time for the entire workflow
RUN_NAME = config['inputs']['run_name']

# INPUT_SEQUENCE = config["input"]['query_sequence']
INPUT_SEQUENCE = "data/GCA_003733365.1_PDT000396410.1_genomic.fna.gz"
FILE_NAME = os.path.basename(INPUT_SEQUENCE)

# For our quick screen, we'll look for 6 genes known to indicate pESI presence.
PESI_GENES = [
    "pESI RepA",
    "trbA",
    "irp2",
    "traI",
    "ardA",
    "faeH"
]

# For the initial 
INPUT_GENOMES_PATHS = glob.glob(
    os.path.join(
        config['inputs']['input_directory'],
        "*.fna.gz"
    )
)

# The full file paths for the genomes
INPUT_GENOMES = [os.path.basename(fin) for fin in INPUT_GENOMES_PATHS]

# The genome file names without the trailing gz if it exists:
INPUT_GENOMES_NO_GZ = [fin[:-3] for fin in INPUT_GENOMES if fin.endswith(".gz")]

# Suffixes for the BLAST db files
BLAST_DB_SUFFIXES = [
    "ndb", "nhr", "nin", "njs", "nog", "nos", "not", "nsq", "ntf", "nto"
]
