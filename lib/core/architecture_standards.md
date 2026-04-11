# Pragmatic Clean Architecture Standards

This document defines the architectural standards for the `li_curriculum_table` project to ensure consistency, maintainability, and reduced boilerplate.

## Layers

### 1. Domain Layer (Entities & Repositories Interfaces)
- **Entities**: Use `@freezed` for immutable data models. Include `fromJson`/`toJson` if needed.
- **Repositories**: Define abstract classes for data access.
- **Use Cases**: *Optional*. Only create Use Cases if the logic is complex or involves multiple repositories. For simple CRUD, calling Repository methods directly from the Notifier is preferred.

### 2. Data Layer (Data Sources & Repository Implementations)
- **Data Sources**: Internal logic for fetching data (HTTP, Secure Storage, etc.).
- **Repository Implementations**: Map data source models to domain entities.

### 3. Presentation Layer (State & UI)
- **State**: Use `@freezed` for UI state (e.g., `TimetableUiState`).
- **Controllers/Notifiers**: Use `@riverpod` class-based notifiers. Use `ref.watch` to inject dependencies.
- **Providers**: Use `@riverpod` annotations for all providers.

## Boilerplate Reduction Rules
- Always use **Riverpod Generator** (`@riverpod`).
- Favor **Functional Providers** for simple read-only data (e.g., repository instances).
- Avoid "Provider Hell" by grouping related providers in a single file per feature.

## Naming Conventions
- Providers: `nameProvider` (generated automatically).
- State: `FeatureUiState`.
- Controller: `FeatureController`.

## Code Generation
Run `dart run build_runner build` after modifying any `@riverpod` or `@freezed` classes.
