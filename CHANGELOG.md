# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [1.3.4] - 2022-12-15

### Changed

- Move intranet index from public search to internal search

## [1.3.3] - 2022-12-15

### Changed

- Fix cors errors when using the search API

### Added

- Add intranet index to internal search calls

## [1.3.2] - 2022-12-05

### Added

- Added internal search upstream endpoint.

### Changed

- Reroute requests from `/searchapi` to `/internal-searchapi`, if `_oauth2_proxy` cookie is present.

## [1.3.1] - 2022-12-05

### Changed

- Revert changes of last release

## [1.3.0] - 2022-12-05

### Added

- Added internal search upstream endpoint.

### Changed

- Reroute requests from `/searchapi` to `/internal-searchapi`, if `_oauth2_proxy` cookie is present.

## [1.2.3] - 2022-12-02

### Changed

- Revert changes of last release

## [1.2.2] - 2022-12-02

### Added

- Added internal search upstream endpoint.

### Changed

- Reroute requests from `/searchapi` to `/internal-searchapi`, if `_oauth2_proxy` cookie is present.

## [1.2.1] - 2022-04-08

- Fixed deployment to reference image tag using the modified schema.

## [1.2.0] - 2022-04-08

- Added PodDisruptionBudget and pod anti-affinity config.
- Updated CircleCI configuration.

## [1.1.1] - 2022-03-24

### Added

- Added resolver entries to configuration

## [1.1.0] - 2021-12-13

### Changed

- Updated README information

[Unreleased]: https://github.com/giantswarm/docs-proxy/compare/v1.3.4...HEAD
[1.3.4]: https://github.com/giantswarm/docs-proxy/compare/v1.3.3...v1.3.4
[1.3.3]: https://github.com/giantswarm/docs-proxy/compare/v1.3.2...v1.3.3
[1.3.2]: https://github.com/giantswarm/docs-proxy/compare/v1.3.1...v1.3.2
[1.3.1]: https://github.com/giantswarm/docs-proxy/compare/v1.3.0...v1.3.1
[1.3.0]: https://github.com/giantswarm/docs-proxy/compare/v1.2.3...v1.3.0
[1.2.3]: https://github.com/giantswarm/docs-proxy/compare/v1.2.2...v1.2.3
[1.2.2]: https://github.com/giantswarm/docs-proxy/compare/v1.2.1...v1.2.2
[1.2.1]: https://github.com/giantswarm/docs-proxy/compare/v1.2.0...v1.2.1
[1.2.0]: https://github.com/giantswarm/docs-proxy/compare/v1.1.1...v1.2.0
[1.1.1]: https://github.com/giantswarm/docs-proxy/compare/v1.1.0...v1.1.1
[1.1.0]: https://github.com/giantswarm/docs-proxy/releases/tag/v1.1.0
