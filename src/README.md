# Source Code

| Folder | Description |
|--------|-------------|
| **connectors** | Interfaces for external protocol integrations (Aave, Morpho, Chainlink, etc.) |
| **constants** | Protocol-wide constants for precision, configuration flags, and protocol logic |
| **dummy** | Mock contracts for testing and development without external dependencies |
| **elements** | Core infrastructure contracts implementing modular architecture and upgradability |
| **errors** | Interface definitions for all custom errors used throughout the protocol |
| **events** | Interface definitions for all events emitted throughout the protocol |
| **facades** | Public interface contracts providing routing logic for the modular architecture |
| **ghost** | Alternative protocol implementations including specialized DeFi integrations |
| **interfaces** | All interface definitions for the LTV protocol including connectors, reads, and writes |
| **math** | Core mathematical libraries and abstractions for complex financial calculations |
| **modifiers** | Reusable access control and validation logic for authorization and whitelist enforcement |
| **public** | Core business logic implementations organized into read and write operations |
| **state_reader** | Read-only state access utilities for querying protocol state without modifications |
| **state_transition** | State modification utilities for write operations that change protocol state |
| **states** | Core state management containing fundamental state structures and data models |
| **structs** | Data structure definitions including custom types, storage layouts, and data models |
| **utils** | Utility functions including error handling and data processing helpers |
