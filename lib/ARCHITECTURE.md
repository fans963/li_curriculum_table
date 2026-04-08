# Timetable App Architecture (Riverpod)

## Goals

- Decouple UI, business logic, and infrastructure.
- Keep dependencies one-way: `presentation -> application -> domain <- data`.
- Make platform-specific crawler behavior replaceable without touching UI.

## Directory Structure

- `lib/main.dart`
  - App entrypoint (`ProviderScope`).
- `lib/app/`
  - Global app composition and theme.
- `lib/core/`
  - Cross-cutting constants/config.
- `lib/features/timetable/domain/`
  - Pure business entities, repository contracts, and mapping services.
- `lib/features/timetable/data/`
  - Repository implementations and external adapters (existing crawler client wrapper).
- `lib/features/timetable/presentation/`
  - Riverpod state/controller/providers and UI pages.

## Layer Responsibilities

### Domain

- `entities/`: `CourseRow`, `CourseOccurrence`, `TimetableData`.
- `repositories/`: `TimetableRepository` interface.
- `usecases/`: `FetchTimetableUseCase`.
- `services/`: course time parsing + schedule mapping.

Rules:
- No framework dependencies except simple value types.
- No Dio/HTTP/plugin calls.

### Data

- `TimetableRepositoryImpl` converts external crawler result to domain models.
- Uses existing `PachongClient` as infrastructure adapter.

Rules:
- Implements domain repository contracts.
- Handles shape conversion and integration details.

### Presentation

- `TimetableController` (`Notifier`) manages fetch flow and UI state.
- `timetable_providers.dart` wires dependency graph.
- `TimetableComparePage` renders state and dispatches user actions.

Rules:
- No direct use of crawler client.
- All actions go through controller/usecase.

## Riverpod Graph

- `pachongClientProvider`
- `timetableRepositoryProvider`
- `fetchTimetableUseCaseProvider`
- `timetableControllerProvider`

`ProviderScope` is created in `main.dart`.

## Extension Guide

1. Add new capability in `domain` first (entity + repository contract + use case).
2. Implement contract in `data`.
3. Expose through provider and controller.
4. Keep page widgets dumb (read state + trigger intent).

## Testing Strategy

- Domain service tests for time parsing/mapping.
- Controller tests with fake repository.
- Data repository tests with mocked `PachongClient`.

## Existing Infra Note

Current crawler/network/OCR internals are still in `lib/src/table_getter/` and are treated as infrastructure. Future steps can move them under `features/timetable/data/datasources/` without changing presentation contracts.
