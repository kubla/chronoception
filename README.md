# Chronoception

Chronoception is an Apple Watch app that measures and trains your sense of elapsed time. It treats chronoception as a trainable sense, similar to interoception, and gives you simple on-wrist tools to practice and track improvement.

This repository contains the product specification, mode and metric definitions, and HealthKit integration details for Chronoception v1.

## Web Demo

An interactive web-based demo of the app is included in this repository.
It simulates the Apple Watch UI and demonstrates Challenge, Fear, and Passive modes.

- View the source in [`web-demo/`](web-demo/)

## Documents

- [`docs/PRD.md`](docs/PRD.md)  
  High level product requirements, goals, ICPs, and use cases.

- [`docs/ModesAndMetrics.md`](docs/ModesAndMetrics.md)  
  Detailed specifications for Challenge, Fear, and Passive modes, including state machines and metric definitions.

- [`docs/HealthKitSpec.md`](docs/HealthKitSpec.md)  
  HealthKit write behavior, Mindful Session metadata schema, and permission handling.

## High level

- Platform: Apple Watch only for v1  
- Modes:
  - Challenge Mode
  - Fear Mode (high arousal variant of Challenge)
  - Passive Training Mode
- Logs: Mindfulness minutes to Apple Health with rich metadata, to enable deeper off-watch analysis.

Chronoception is designed for two primary audiences:

1. Quantified self enthusiasts who want to run experiments on time perception and learning.
2. Meditation practitioners who want to meditate on chronoception as a sense gate, and occasionally calibrate that practice against objective time.
