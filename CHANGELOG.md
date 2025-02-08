# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Changed

- Upgrade to stable Rust 1.84.0.
- Upgrade widestring dependency to 1.1.0.
- Replace deprecated winapi dependency with windows-sys.

### Security

- [RUSTSEC-2020-0016](https://rustsec.org/advisories/RUSTSEC-2020-0016) Replace
ws crate with tungstenite and mio.

## [0.1.0] - 2023-09-12

### Added

- Textractor WebSocket extension.
