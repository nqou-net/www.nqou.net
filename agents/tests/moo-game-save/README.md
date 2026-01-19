# Moo Game Save Test Suite

This directory contains test files for the "Mooを使ってゲームのセーブ機能を作ってみよう" (Building a Game Save System with Moo) series.

## Series Overview

A 10-episode tutorial series teaching the Memento design pattern through building an RPG save/load system in Perl with Moo.

## Episodes

### Episode 01: プレイヤーの状態を管理しよう
- **Location**: `01/`
- **Content**: Basic Player class with HP, gold, position attributes
- **Tests**: Player creation, damage, gold earning, movement

### Episode 02: ゲームオーバーで最初から？状態保存の必要性
- **Location**: `02/`
- **Content**: Introduction to state saving, reference copy trap (shallow copy problem)
- **Tests**: Simple variable copying, shallow copy issues, deep copy solutions

### Episode 03: 状態をまとめて保存しよう（スナップショット）
- **Location**: `03/`
- **Content**: PlayerSnapshot class with immutable (`is => 'ro'`) attributes
- **Tests**: Snapshot creation, immutability, independence from Player changes

### Episode 04: 保存した状態から復元しよう
- **Location**: `04/`
- **Content**: `restore_from_snapshot` method for state restoration
- **Tests**: Save/restore cycles, game over scenarios, data preservation

### Episode 05: セーブデータを管理しよう（履歴機能）
- **Location**: `05/`
- **Content**: GameManager class for managing multiple save slots
- **Tests**: Multiple save slots, slot selection, save/load validation

### Episode 06: オートセーブを追加しよう
- **Location**: `06/`
- **Content**: Auto-save functionality with `auto_save` flag and `try_auto_save` method
- **Tests**: Auto-save toggle, conditional saves, boss/area auto-saves

### Episode 07: セーブデータを守ろう（カプセル化）
- **Location**: `07/`
- **Content**: Verification of data protection and encapsulation principles
- **Tests**: Immutability enforcement, data integrity, encapsulation verification

### Episode 08: セーブスロット管理
- **Location**: `08/`
- **Content**: Multiple save slot management and slot information display
- **Tests**: Independent slots, slot selection, save listing

### Episode 09: 完成したRPG
- **Location**: `09/`
- **Content**: Complete playable RPG integration with all features
- **Tests**: Full game scenarios, branching paths, error handling

### Episode 10: Mementoパターン
- **Location**: `10/`
- **Content**: Memento design pattern explanation and structure
- **Tests**: Pattern roles (Originator/Memento/Caretaker), benefits, comparisons

## Running Tests

Run tests for a specific episode:
```bash
cd 05
perl -Ilib t/*.t
```

Run all tests:
```bash
for ep in 02 03 04 05 06 07 08 09 10; do
    echo "=== Episode $ep ==="
    perl -Iagents/tests/moo-game-save/$ep/lib \
         agents/tests/moo-game-save/$ep/t/*.t
done
```

## Code Structure

Each episode contains:
- `lib/` - Perl modules (Player.pm, PlayerSnapshot.pm, GameManager.pm)
- `t/` - Test files using Test::More
- Optional demo scripts (`.pl` files) showing usage

## Key Concepts Demonstrated

1. **State Management**: Managing game state with objects
2. **Immutability**: Using `is => 'ro'` for read-only snapshots
3. **Deep Copy**: Proper array/hash copying to avoid reference sharing
4. **Encapsulation**: Hiding implementation details behind methods
5. **Memento Pattern**: Three roles - Originator, Memento, Caretaker
6. **Auto-save**: Conditional save triggers for game events
7. **Multi-slot Management**: Managing multiple independent save points

## Dependencies

- Perl v5.36 or later
- Moo (for object system)
- Test::More (for tests)

## Pattern Evolution

- **Episodes 02-03**: Problem → Snapshot solution
- **Episodes 04-05**: Restoration → Multi-slot management
- **Episodes 06-07**: Auto-save → Data protection
- **Episodes 08-09**: Complete integration
- **Episode 10**: Pattern theory and design principles

All tests verify both functionality and design pattern adherence.
