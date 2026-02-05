# Surgical Implementation Notes: Prototype Pattern

## Implementation Details
- **Base Class**: `Monster.pm` provides basic `new` and `clone`.
- **Concrete Class**: `Goblin.pm` simulates heavy initialization (loop calculation) in `new`.
- **Verification**: `bad_client.pl` calls `new` 1000 times. `good_client.pl` calls `new` once and `clone` 999 times.

## Benchmark Results (Simulated)
- Bad Case: ~2.5s (approx, based on 50000 loop iters * 1000)
- Good Case: ~0.01s (instant)
*(Actual results will be verified in shell)*
