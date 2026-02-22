---
title: "Emulator-based Bayesian calibration of CISNET colorectal cancer models"
collection: talks
type: "Poster and oral presentation"
permalink: /talks/2022-01-01-emulator-based-bayesian-calibration-of-cisnet-colorectal-cancer-models
venue: "Society for Medical Decision Making Annual Meeting"
date: 2022-01-01
location: "Seattle, WA, USA"
excerpt: "To calibrate Cancer Intervention and Surveillance Modeling Network (CISNET)’s SimCRC, MISCAN-Colon, and CRC-SPIN simulation models of the natural history colorectal cancer (CRC) with an emulator-based Bayesian algorithm and internally validate the model-predicted outcomes to calibration targets."
slidesurl: "/files/talks/2022-01-01-emulator-based-bayesian-calibration-of-cisnet-colorectal-cancer-models.pdf"
---
Finalist in the Lee B. Lusted Student Prize Competition.

**Brief summary**: To calibrate Cancer Intervention and Surveillance Modeling Network (CISNET)’s SimCRC, MISCAN-Colon, and CRC-SPIN simulation models of the natural history colorectal cancer (CRC) with an emulator-based Bayesian algorithm and internally validate the model-predicted outcomes to calibration targets.

## Abstract

**Objective**: To calibrate Cancer Intervention and Surveillance Modeling Network (CISNET)'s SimCRC, MISCAN-Colon, and CRC-SPIN simulation models of the natural history of colorectal cancer (CRC) with an emulator-based Bayesian algorithm and internally validate model-predicted outcomes against calibration targets.

**Methods**: We used Latin hypercube sampling to generate up to 50,000 parameter sets for each CISNET-CRC model and trained multilayer perceptron artificial neural networks (ANN) as emulators using the corresponding input-output samples. The ANN emulators were implemented in a probabilistic programming framework and calibrated using Hamiltonian Monte Carlo to estimate joint posterior parameter distributions. Internal validation compared posterior model outputs against calibration targets.

**Results**: The optimal ANN architectures differed across models, and total training plus calibration time was 7.3 hours for SimCRC, 4.0 hours for MISCAN-Colon, and 0.66 hours for CRC-SPIN. Mean posterior model outputs fell within the 95% confidence intervals of most calibration targets across the three models.

**Conclusions**: ANN emulators provide a practical way to reduce computational burden and complexity in Bayesian calibration of individual-level policy simulation models such as the CISNET CRC models.
