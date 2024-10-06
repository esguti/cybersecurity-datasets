This repository is part of the research work titled "A Dataset to Train Intrusion Detection Systems based on Machine Learning Models for Electrical Substations," which is currently awaiting approval for publication. It contains code for preprocessing and testing datasets designed to train and evaluate machine learning models for cybersecurity in electrical substations. It includes tools to process network captures in PCAP format from IEC61850 or IEC60870-5-104 (also known as IEC104), and provides code for testing datasets with different machine learning algorithms for substation cyber-protection.

# Folders

- *ids*: contains the python scripts for execution of the machine learning algorithms to test the datasets.
- *tools*: tools to process dataset files

# Requisites

- A dataset in PCAP or PCAPNG format
- It is not mandatory, but it is better to have a **GPU**
- tshark for preprocessing scripts
- Python and libraries for executing IDS algorithms.

# Installation

## Install tools

- install tshark

```bash
    sudo apt-get install tshark
```

- install Sanicap

```bash
    git clone https://github.com/thepacketgeek/sanicap.git
    cd sanicap
    docker build -t sanicap .
```

- install Cicflowmeter


```bash
    cd tools/cicflowmeter
    docker build --build-arg UID=$(id -u) --build-arg GID=$(id -g) -f CICFlowMeter.Dockerfile -t cicflowmeter .
```

    NOTE: instructions from obtained from [maybe-hello-world/CICFlowMeter.Dockerfile](https://gist.github.com/maybe-hello-world/dba3b6825a3dd6f558e8c464e7ad210a)


## Install Python and libraries

create a virtual environment using CONDA


- MiniConda installation in a Linux environment:

```bash
    wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh
    chmod -v +x Miniconda*.sh
    ./Miniconda3-latest-Linux-x86_64.sh
    vim ~/.bashrc # (Add Conda to path: PATH="$HOME/miniconda3/bin:$PATH")
    source ~/.bashrc
    conda config --set auto_activate_base false
    rm Miniconda3-latest-Linux-x86_64.sh
    conda init
```

- create environment

```bash
    conda create --solver=libmamba -n pycaretgpu -c rapidsai -c conda-forge -c nvidia -c esri rapids=24.04 python=3.9 cuda-version=12.2 tensorflow-gpu xgboost
    conda activate pycaretgpu
    cd ids
    pip install -r requirements_pycaret.txt
```

- check environments installed

```bash
    conda info --envs
```

# EXECUTION

## IDS

```bash
conda activate pycaretgpu
cd ids
./pycaret_ids.py PATH_TO_CSV_DATASET
```
**NOTE**: PATH_TO_CSV_DATASET is the path to the folder with the CSV files processed of your dataset and a header file (CSV file with headers to process).

**NOTE**: for using pycaret with GPU, set the parameter **use_gpu=True** in *setup* in file *pycaret_ids.py*.

Other Python algorithm comparison tools (extracted from [here](https://www.linkedin.com/pulse/tools-smartlazy-data-scientist-ft-lazypredict-rithwik-chhugani)):

- lazypredict
- tpot
- h2o automl
- auto keras
- Auto-sklearn
- AutoML
- MLBox
- Pycaret
- Uber Ludwig

## Pre-Processing

### Filter and Split

Filtering is performed using Wireshark, specifically with the command line tool **tshark**. Due to issues handling large files, the files had to be split into *10GB* units, which are later merged (see [Merge](#merge)). The splitting and filtering are conducted using the script **filter_and_split.sh**:

```bash
cd tools
./filter_and_split.sh IN_FOLDER [IEC104|IEC61850]
```

**NOTE**: "*IN_FOLDER*" is the path to the folder with the PCAP files to be processed.

**NOTE**: you have to choose the protocol to be filtered using the options "*IEC104*" or "*IEC61850*".

### Merge

The subsequent merging after filtering and splitting is done with the script **merge_pcap.sh**. The script takes the input folder (it can be used a wilcard to select several folders)

```bash
./merge_pcap.sh IN_FOLDER OUT_FILE
```

**NOTE**: "*IN_FOLDER*" is the path to the folder with the PCAP files splitted. Ex: *./pcap/filtered**.

**NOTE**: "*OUT_FILE*" is the file name for the result of merging all the input files.


### Anonymize

Anonymization is carried out using the tool Sanicap, through the script **anonymize.sh**. The script converts PCAPNG files to PCAP (if necessary) and randomizes MAC and IP addresses while MAC and IP addresses for a specific machine will remain consistent.

```bash
./anonymize.sh IN_FILE OUT_FILE
```

**NOTE**: "*IN_FILE*" is the PCAP file be anonymized.

**NOTE**: "*OUT_FILE*" is the file name for the result of anonymizing the input file.

### Generate CSV

For feature extraction, we have to distinguish between IEC104 and IEC61850.

IEC104 standard operates over TCP/IP (Transport Layer) and uses the tool CICFlowMeter for extracting data flows.

GOOSE and SV protocols from IEC61850 operates at the MAC (link layer). For that, we have employed the tool tshark for extracting specific fields from the packets.

A final step common for both protocols after the feature extraction is the *labeling*. An extra column, denoted as "*Label*", is appended to each CSV file. This column is designated to store the type of attack, or its absence, which is derived from the file name.

The label is derivated using the text following the last "**-**" symbol in the file name. As an example, the file *merged_anon_filtrado7dias-attackfree.pcap* will generate the label *attackfree*.

- Generate CSV for IEC104

    Feature extraction for IEC104 is performed with the following command:

```bash
    ./generatecsv_iec104.sh -i IN_FOLDER -o OUT_FOLDER
```

    **NOTE**: "*IN_FOLDER*" is the path to the folder with the PCAP files for extracting features.

    **NOTE**: "*OUT_FOLDER*" is the path to the folder to save the result CSV files.


- Generate CSV for IEC61850

    Feature extraction for IEC104 is performed with the following command:

```bash
    ./generatecsv_iec61850.sh -i IN_FOLDER -o OUT_FOLDER
```

    **NOTE**: "*IN_FOLDER*" is the path to the folder with the PCAP files for extracting features.

    **NOTE**: "*OUT_FOLDER*" is the path to the folder to save the result CSV files.
This repository is part of the research work titled "A Dataset to Train Intrusion Detection Systems based on Machine Learning Models for Electrical Substations," which is currently awaiting approval for publication. It contains code for preprocessing and testing datasets designed to train and evaluate machine learning models for cybersecurity in electrical substations. It includes tools to process network captures in PCAP format from IEC61850 or IEC60870-5-104 (also known as IEC104), and provides code for testing datasets with different machine learning algorithms for substation cyber-protection.

# Folders

- **ids**: contains the python scripts for execution of the machine learning algorithms to test the datasets.
- **tools**: tools to process dataset files

# Requisites

- A dataset in PCAP or PCAPNG format
- It is not mandatory, but it is better to have a *GPU*
- tshark for preprocessing scripts
- Python and libraries for executing IDS algorithms.

# Installation

## Install tools

- install **tshark**

```bash
    sudo apt-get install tshark
```

- install **Sanicap**

```bash
    git clone https://github.com/thepacketgeek/sanicap.git
    cd sanicap
    docker build -t sanicap .
```

- install **Cicflowmeter**


```bash
    cd tools/cicflowmeter
    docker build --build-arg UID=$(id -u) --build-arg GID=$(id -g) -f CICFlowMeter.Dockerfile -t cicflowmeter .
```

    NOTE: instructions from obtained from [maybe-hello-world/CICFlowMeter.Dockerfile](https://gist.github.com/maybe-hello-world/dba3b6825a3dd6f558e8c464e7ad210a)


## Install Python and libraries

create a virtual environment using **CONDA**


- MiniConda installation in a Linux environment:

```bash
    wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh
    chmod -v +x Miniconda*.sh
    ./Miniconda3-latest-Linux-x86_64.sh
    vim ~/.bashrc # (Add Conda to path: PATH="$HOME/miniconda3/bin:$PATH")
    source ~/.bashrc
    conda config --set auto_activate_base false
    rm Miniconda3-latest-Linux-x86_64.sh
    conda init
```

- create environment

```bash
    conda create --solver=libmamba -n pycaretgpu -c rapidsai -c conda-forge -c nvidia -c esri rapids=24.04 python=3.9 cuda-version=12.2 tensorflow-gpu xgboost
    conda activate pycaretgpu
    cd ids
    pip install -r requirements_pycaret.txt
```

- check environments installed

```bash
    conda info --envs
```

# EXECUTION

## IDS

```bash
conda activate pycaretgpu
cd ids
./pycaret_ids.py PATH_TO_CSV_DATASET
```
**NOTE**: PATH_TO_CSV_DATASET is the path to the folder with the CSV files processed of your dataset and a header file (CSV file with headers to process).

**NOTE**: for using pycaret with GPU, set the parameter **use_gpu=True** in *setup* in file *pycaret_ids.py*.

Other Python algorithm comparison tools (extracted from [here](https://www.linkedin.com/pulse/tools-smartlazy-data-scientist-ft-lazypredict-rithwik-chhugani)):

- lazypredict
- tpot
- h2o automl
- auto keras
- Auto-sklearn
- AutoML
- MLBox
- Pycaret
- Uber Ludwig

## Pre-Processing

### Filter and Split

Filtering is performed using Wireshark, specifically with the command line tool *tshark*. Due to issues handling large files, the files had to be split into *10GB* units, which are later merged (see [Merge](#merge)). The splitting and filtering are conducted using the script **filter_and_split.sh**:

```bash
cd tools
./filter_and_split.sh IN_FOLDER [IEC104|IEC61850]
```

**NOTE**: "*IN_FOLDER*" is the path to the folder with the PCAP files to be processed.

**NOTE**: you have to choose the protocol to be filtered using the options "*IEC104*" or "*IEC61850*".

### Merge

The subsequent merging after filtering and splitting is done with the script **merge_pcap.sh**. The script takes the input folder (it can be used a wilcard to select several folders)

```bash
./merge_pcap.sh IN_FOLDER OUT_FILE
```

**NOTE**: "*IN_FOLDER*" is the path to the folder with the PCAP files splitted. Ex: *./pcap/filtered**.

**NOTE**: "*OUT_FILE*" is the file name for the result of merging all the input files.


### Anonymize

Anonymization is carried out using the tool Sanicap, through the script **anonymize.sh**. The script converts PCAPNG files to PCAP (if necessary) and randomizes MAC and IP addresses while MAC and IP addresses for a specific machine will remain consistent.

```bash
./anonymize.sh IN_FILE OUT_FILE
```

**NOTE**: "*IN_FILE*" is the PCAP file be anonymized.

**NOTE**: "*OUT_FILE*" is the file name for the result of anonymizing the input file.

### Generate CSV

For feature extraction, we have to distinguish between IEC104 and IEC61850.

IEC104 standard operates over TCP/IP (Transport Layer) and uses the tool CICFlowMeter for extracting data flows.

GOOSE and SV protocols from IEC61850 operates at the MAC (link layer). For that, we have employed the tool tshark for extracting specific fields from the packets.

A final step common for both protocols after the feature extraction is the *labeling*. An extra column, denoted as "*Label*", is appended to each CSV file. This column is designated to store the type of attack, or its absence, which is derived from the file name.

The label is derivated using the text following the last "**-**" symbol in the file name. As an example, the file *merged_anon_filtrado7dias-attackfree.pcap* will generate the label *attackfree*.

- Generate CSV for **IEC104**

    Feature extraction for IEC104 is performed with the following command:

```bash
    ./generatecsv_iec104.sh -i IN_FOLDER -o OUT_FOLDER
```

    **NOTE**: "*IN_FOLDER*" is the path to the folder with the PCAP files for extracting features.

    **NOTE**: "*OUT_FOLDER*" is the path to the folder to save the result CSV files.


- Generate CSV for **IEC61850**

    Feature extraction for IEC104 is performed with the following command:

```bash
    ./generatecsv_iec61850.sh -i IN_FOLDER -o OUT_FOLDER
```

    **NOTE**: "*IN_FOLDER*" is the path to the folder with the PCAP files for extracting features.

    **NOTE**: "*OUT_FOLDER*" is the path to the folder to save the result CSV files.
