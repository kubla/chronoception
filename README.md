# Chronoception

Chronoception is an Apple Watch app that measures and trains your sense of elapsed time. It treats chronoception as a trainable sense, similar to interoception, and gives you simple on-wrist tools to practice and track improvement.

So far, this repository contains product docs and an interactive mockup. Docs include the product specification, mode and metric definitions, and HealthKit integration details for Chronoception v1.

## Web Demo

An interactive web-based demo of the app is included in this repository.
It simulates the Apple Watch UI and demonstrates Challenge, Fear, and Passive modes. View it here: [[`web-demo/`](web-demo/)
](https://kubla.github.io/chronoception/web-demo/)

## Documents

- [`docs/PRD.md`](docs/PRD.md)  
  High level product requirements, goals, ICPs, and use cases.

- [`docs/ModesAndMetrics.md`](docs/ModesAndMetrics.md)  
  Detailed specifications for Challenge, Fear, and Passive modes, including state machines and metric definitions.

- [`docs/HealthKitSpec.md`](docs/HealthKitSpec.md)  
  HealthKit write behavior, Mindful Session metadata schema, and permission handling.

## High level

Chronoception is designed for two primary audiences:

1. Quantified self enthusiasts who want to run experiments on time perception and learning.
2. Meditation practitioners who want to meditate on chronoception as a sense gate, and occasionally calibrate that practice against objective time.

- Platform: Apple Watch
- Modes:
  - Passive Training Mode, giving you a sense of the passage of time with haptics
  - Challenge Mode
  - Fear Mode (high arousal variant of Challenge Mode)
  - Stats on Challenge Mode accuracy and rate of improvement 
- Logs: Mindfulness minutes to Apple Health with rich metadata, to enable deeper off-watch analysis
