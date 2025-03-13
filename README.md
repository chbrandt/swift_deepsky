# Swift DeepSky

[Docker Hub Repository](https://hub.docker.com/r/chbrandt/swift_deepsky/) | [Swift Satellite](https://en.wikipedia.org/wiki/Neil_Gehrels_Swift_Observatory)

The _Swift DeepSky_ pipeline provides automated **deep observations** of the X-ray sky from the Swift satellite, processing data based on user-defined sky positions (Right Ascension and Declination).

## Docker Setup and Usage

### Prerequisites
To use Swift DeepSky, ensure Docker is installed on your system:
- [Install Docker](https://www.docker.com/get-started)

### Quick Start with Docker

**Step 1: Launch CalDB Container**

Swift DeepSky depends on calibration data provided by the CalDB container:

```bash
docker run --name caldb chbrandt/heasoft_caldb:swift
```

**Step 2: Run Swift DeepSky Container**

Run the Swift DeepSky pipeline, binding the CalDB container and mounting a local directory (`$HOME/sds_output`) to store outputs:

```bash
docker run --rm -it --volumes-from caldb -v $HOME/sds_output:/work chbrandt/swift_deepsky swift_deepsky --ra 34.2608 --dec 1.2455
```

Replace `$HOME/sds_output` with your desired output directory.

**Tip:** Create an alias for simplicity:

```bash
alias swift_deepsky='docker run --rm -it --volumes-from caldb -v $HOME/sds_output:/work chbrandt/swift_deepsky swift_deepsky'
```

### Docker Configuration Details

- **`--volumes-from caldb`**: Mounts calibration data from CalDB.
- **`-v $HOME/sds_output:/work`**: Maps a local directory to store outputs.

### Example Usage

Process Swift-XRT images within a 15-arcmin radius:
```bash
swift_deepsky --ra 22 --dec 33 --radius 15
```

Process observations for a specific object and time period:

```bash
swift_deepsky --object 3c279 --start 1/1/2018 --end 28/2/2018
```

### Using a Local Master Table

To avoid network traffic, use a local master table (`--master_table`). Place your table (e.g., `my_swift_master_table.csv`) in a dedicated directory:

```bash
docker run --rm -it --volumes-from caldb -v $PWD/sds_runs:/work chbrandt/swift_deepsky --master_table /work/my_swift_master_table.csv --ra 22 --dec 33
```

## Command-Line Reference

A complete help message with options is displayed using:

```bash
swift_deepsky --help
```

## Manual Installation (Advanced Users Only)

### Dependencies
- HEASoft (v6.21)
- Python (Pandas, Astropy)
- Perl
- Bash

Detailed instructions can be found [here](#manual-install).

## About Swift DeepSky

Swift DeepSky automates the combination and analysis of Swift satellite X-ray data, allowing deep-sky observations from user-defined sky coordinates (Right Ascension, Declination). Data is automatically retrieved as needed unless provided by the user.

### Additional Resources
- [Neil Gehrels Swift Observatory](https://en.wikipedia.org/wiki/Neil_Gehrels_Swift_Observatory)

---

