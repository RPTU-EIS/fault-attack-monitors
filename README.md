# fault-attack-monitors
This repository contains hardware monitors for different RISC-V processors against fault attacks. The monitors aim on protecting against an attacker controlling an unprivileged (user) process and injecting faults at the same time.

Covered attack scenarios are: read-out of protected data, modification of protected data stored in memory or internal (CSR) registers and illegal privilege escalation.

The monitors are designed for the Ibex core (version from August 2021), the RI5CY core (as used in the Pulp project) and Ariane v4.1.2.
