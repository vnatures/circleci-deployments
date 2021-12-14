# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

- Current development changes [ to be moved to release ]

## [1.3.4] - 2020-12-12

### Added

- 1.3.1 invalidate-and-sync-s3: adds optional sync-args params

## [1.3.3] - 2020-12-01

### Added - breaking change (needs to add slack credentials context to the job)

- 1.3.1 invalidate-and-sync-s3: adds slack notify
- 1.3.2 push-docker-image: adds optional checkout-repo parameter param
- 1.3.3 push-docker-image: adds checkout step conditionally

## [1.3.0] - 2021-11-18

### Added

- bump slack orb
- adds custom template for slack success notify

## [1.2.0] - 2020-08-26

### Added

- deploy-docker-image: add suffix parameter to task-definition name and service
- deploy-docker-image: add env-variables string parameter to task-definition container's environment variables

## [1.1.0] - 2021-02-07

### Changed

- push-docker-image job : enables to provide additional docker wrapper on the base image

## [1.0.9] - 2020-12-20

### Added

- adds command to run remote repo bash script

## [1.0.0] - 2020-12-09

### Added

- Initial Release

[1.0.0]: GITHUB TAG URL
