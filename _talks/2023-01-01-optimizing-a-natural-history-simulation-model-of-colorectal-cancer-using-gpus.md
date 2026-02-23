---
title: "Optimizing a natural history simulation model of colorectal cancer using GPUs"
collection: talks
type: "Conference presentation"
permalink: /talks/2023-01-01-optimizing-a-natural-history-simulation-model-of-colorectal-cancer-using-gpus
venue: "Society for Medical Decision Making Annual Meeting"
date: 2023-01-01
location: "Philadelphia, PA, USA"
excerpt: "Individual-level simulation models are often used to assess the impact of various health policies by simulating disease development, but they tend to be computationally demanding."
slidesurl: "/files/talks/2023-01-01-optimizing-a-natural-history-simulation-model-of-colorectal-cancer-using-gpus.pdf"
---
## Abstract

**Purpose**

Individual-level simulation models are often used to assess the impact of various health policies by simulating disease development, but they tend to be computationally demanding. Modelers are continuously searching for ways to improve their efficiency. We demonstrate how we tested and optimized a simulation model of the natural history of colorectal cancer (CRC) using Polaris, a leading-edge computing system, as part of the lessons learned from the Argonne Leadership Computing Facility (ALCF) INCITE Hackathon 2023.

**Methods**

We implemented a simplified version of the simulation model of CRC (SimCRC) in R and Python, an individual-level discrete-event simulation model to inform screening and surveillance policies to reduce CRC mortality in the US population. The model was originally coded in R, and the different model sections were profiled to identify the most time-consuming parts. These modules were translated into Python for GPU acceleration. We used packages that support GPU processing, such as cudf and cupy, requiring NVIDIA graphic cards. We used the reticulate R package to integrate the GPU-based Python code into the main R model and to import and export the simulation inputs and outputs.

We compared the time performance of simulating the natural history of CRC for 10 million people using 1 CPU - 1 thread in R, 1 CPU- 1 thread in Python, and 4 GPUs in Python using one node of the Polaris system consisting of 32 AMD Zen 3 Cores, 512 GB of RAM, 4 NVIDIA A100 GPUs and 2 TB SSD.

**Results**

From the model profiling, we determined that the natural history and output wrangling modules were the most computationally time-consuming. These modules consumed more than 80% of the total simulation time when running them on CPU in R. One run of the natural history model for 10 million people took 220 seconds using 1 CPU in R; it went down to 131 seconds using 1-CPU in Python implementing an improved algorithm, and down to 6 seconds when using 4-GPUs in Python (See Figure 1).

**Conclusions**

We demonstrate how using GPU processing can significantly increase the efficiency of individual-level simulations. This can greatly reduce the computational burden and time when conducting model calibration, uncertainty quantification, and probabilistic sensitivity analysis.
