---
date: 2026-01-02T14:55:18+09:00
draft: false
epoch: 1767333318
image: /favicon.png
iso8601: 2026-01-02T14:55:18+09:00
tags:
  - design-pattern
  - mediator
  - behavioral-pattern
title: Mediatorパターンの調査
---

# Mediatorパターンの調査ドキュメント

## 調査概要

- **調査日**: 2026-01-01
- **調査対象**: Mediatorパターン（仲介者パターン）
- **分類**: GoF（Gang of Four）デザインパターン / 振る舞いパターン（Behavioral Pattern）

## 1. 概要（Overview）

### 定義

Mediatorパターンとは、オブジェクト群の相互作用をカプセル化するオブジェクト（仲介者）を定義するデザインパターンである。複数のオブジェクトが互いに直接参照し合うのではなく、仲介者を通じて通信することで、疎結合を実現する。

### パターンの意図

- オブジェクト間の複雑な相互作用を中央集権化する
- オブジェクト同士が直接参照し合うことによる密結合を避ける
- 相互作用のロジックを一箇所に集約し、保守性を向上させる

### 構造

Mediatorパターンは以下の要素で構成される：

- **Mediator（仲介者インターフェース）**: 同僚オブジェクト間の通信メソッドを定義
- **ConcreteMediator（具体的な仲介者）**: 実際に同僚オブジェクト間の調整を行う実装
- **Colleague（同僚オブジェクト）**: 仲介者を通じてのみ他のオブジェクトと通信するコンポーネント

```
┌──────────────────┐
│   Colleague A    │───┐
└──────────────────┘   │
                       ▼
                 ┌──────────┐
                 │ Mediator │
                 └──────────┘
                       ▲
┌──────────────────┐   │
│   Colleague B    │───┘
└──────────────────┘
```

## 2. 用途（Use Cases）

### 適用場面

Mediatorパターンは以下のような場面で有効：

1. **GUIダイアログボックス**
   - ボタン、テキストフィールド、チェックボックスなどのUI要素が互いに影響し合う場合
   - 例：あるチェックボックスがオフのとき、特定のボタンを無効化する

2. **チャットアプリケーション**
   - ユーザー同士が直接通信せず、チャットルーム（仲介者）を経由してメッセージをやり取りする

3. **航空管制システム**
   - 飛行機同士が直接通信せず、管制塔（仲介者）を介して調整する

4. **ワークフローエンジン**
   - プロセスの各ステップが仲介者を通じて協調動作する

5. **複雑なイベント駆動システム**
   - 多数のイベント発生源とリスナーが存在し、それらの関係が複雑な場合

### 利用シナリオの具体例

- 複数のオブジェクト間に複雑で保守が困難な相互作用がある
- オブジェクト間の直接通信が密結合を引き起こし、保守性が低下している
- オブジェクトを異なるコンテキストで再利用したいが、通信ロジックが内部に埋め込まれている
- 相互作用のルールが頻繁に変更される可能性があり、中央で管理したい

## 3. サンプルコード

### Python実装例：チャットルーム

```python
# Mediator Interface
class ChatRoomMediator:
    def show_message(self, user, message):
        pass

# Concrete Mediator
class ChatRoom(ChatRoomMediator):
    def show_message(self, user, message):
        from datetime import datetime
        time = datetime.now().strftime("%H:%M:%S")
        sender = user.get_name()
        print(f"[{time}] {sender}: {message}")

# Colleague
class User:
    def __init__(self, name, mediator):
        self.name = name
        self.mediator = mediator
    
    def get_name(self):
        return self.name
    
    def send_message(self, message):
        self.mediator.show_message(self, message)

# 使用例
if __name__ == "__main__":
    chat_room = ChatRoom()
    
    alice = User("Alice", chat_room)
    bob = User("Bob", chat_room)
    
    alice.send_message("こんにちは、Bob!")
    bob.send_message("やあ、Alice!")
```

### Java実装例：チャットルーム

```java
// Mediator
class ChatRoom {
    public static void showMessage(User user, String message) {
        System.out.println(new java.util.Date() 
            + " [" + user.getName() + "] : " + message);
    }
}

// Colleague
class User {
    private String name;
    
    public User(String name) {
        this.name = name;
    }
    
    public String getName() {
        return name;
    }
    
    public void sendMessage(String message) {
        ChatRoom.showMessage(this, message);
    }
}

// 使用例
public class MediatorPatternDemo {
    public static void main(String[] args) {
        User robert = new User("Robert");
        User john = new User("John");
        
        robert.sendMessage("Hi! John!");
        john.sendMessage("Hello! Robert!");
    }
}
```

### C++実装例：簡易的な仲介者

```cpp
#include <iostream>
#include <string>
#include <vector>

class Mediator; // 前方宣言

class Colleague {
public:
    Colleague(Mediator* m, std::string n) 
        : mediator(m), name(n) {}
    
    void send(const std::string& msg);
    void receive(const std::string& msg);
    std::string getName() { return name; }

private:
    Mediator* mediator;
    std::string name;
};

class Mediator {
public:
    void addUser(Colleague* user) {
        users.push_back(user);
    }
    
    void relay(std::string from, std::string msg) {
        for (auto user : users) {
            if (user->getName() != from) {
                user->receive(msg);
            }
        }
    }

private:
    std::vector<Colleague*> users;
};

void Colleague::send(const std::string& msg) {
    mediator->relay(name, msg);
}

void Colleague::receive(const std::string& msg) {
    std::cout << name << " received: " << msg << std::endl;
}

// 使用例
int main() {
    Mediator mediator;
    Colleague alice(&mediator, "Alice");
    Colleague bob(&mediator, "Bob");
    
    mediator.addUser(&alice);
    mediator.addUser(&bob);
    
    alice.send("Hello Bob");
    bob.send("Hi Alice");
    
    return 0;
}
```

## 4. 利点（Advantages）

### 主な利点

1. **疎結合の実現**
   - 同僚オブジェクトは仲介者のみを知っており、他の同僚オブジェクトを直接参照しない
   - システムがモジュール化され、変更、テスト、拡張が容易になる

2. **通信ロジックの中央集権化**
   - 相互作用のロジックが一箇所（仲介者）に集約される
   - 管理や更新が容易になる

3. **複雑な相互作用の簡素化**
   - オブジェクト間の複雑な依存関係の網を避けられる
   - 相互作用のルールが仲介者で管理され、追跡しやすい

4. **再利用性の向上**
   - 同僚オブジェクトは通信ロジックを内部に持たないため、異なるコンテキストで再利用しやすい

5. **単一責任原則の促進**
   - 各コンポーネントは自身の核となるロジックに集中でき、オブジェクト間通信の責任は仲介者に委譲される

6. **新しいコンポーネントの追加が容易**
   - 新しい同僚オブジェクトを追加する際、仲介者とのインターフェースのみを考慮すればよい

## 5. 欠点（Disadvantages）

### 主な欠点

1. **仲介者の複雑化**
   - 多くの責任を仲介者に集中させると、仲介者自体が非常に複雑になる可能性がある
   - "神オブジェクト（God Object）"になるリスク
   - モジュール性の原則に違反する可能性

2. **単一障害点（Single Point of Failure）**
   - すべての通信が仲介者を経由するため、仲介者に障害が発生するとシステム全体の相互作用が停止する

3. **不必要な複雑さの追加**
   - オブジェクト間の相互作用がシンプルな場合、仲介者の導入は不要なオーバーヘッドとなる

4. **仲介者への結合**
   - 同僚オブジェクト同士の結合は減るが、すべての同僚オブジェクトが仲介者のインターフェースに依存する
   - 仲介者の変更がすべての依存コンポーネントに影響を及ぼす可能性

5. **パフォーマンスの懸念**
   - 仲介者が大量のトラフィックを処理する必要がある場合、ボトルネックになる可能性
   - リアルタイム性が重要なシステムでは性能劣化の原因となりうる

### 使用を避けるべき場面

- オブジェクト間の相互作用がシンプルで、直接的な関係が問題にならない場合
- パフォーマンスが重要で、仲介者がボトルネックになる可能性がある場合
- オブジェクト間の相互作用が非常に特殊化されており、一般化が困難な場合

## 6. 比較・関連パターン

### Observerパターンとの比較

- **Observer**: 一対多の依存関係。Subject（主体）の変更が複数のObserverに通知される
- **Mediator**: 多対多の相互作用を中央集権化。オブジェクト間の双方向通信を調整

### Facadeパターンとの比較

- **Facade**: サブシステムへの統一インターフェースを提供（単方向）
- **Mediator**: オブジェクト間の双方向通信を仲介

### Chain of Responsibilityパターンとの関連

- 両者とも通信の流れを管理するが、Mediatorは中央集権的、Chain of Responsibilityは連鎖的

## 7. 実装上の注意点

1. **仲介者の肥大化を防ぐ**
   - 仲介者が多くの責任を持ちすぎないよう設計する
   - 必要に応じて複数の仲介者に分割することを検討

2. **インターフェースの設計**
   - 仲介者のインターフェースは明確で、将来の拡張を考慮したものにする

3. **同僚オブジェクトの独立性**
   - 同僚オブジェクトは仲介者以外との依存関係を最小限にする

4. **テスタビリティ**
   - 仲介者をモック化しやすいよう、インターフェースを定義する

## 8. 参考資料

### オンラインリソース

- [Mediator Design Pattern - GeeksforGeeks](https://www.geeksforgeeks.org/system-design/mediator-design-pattern/)
- [Mediator pattern - Wikipedia](https://en.wikipedia.org/wiki/Mediator_pattern)
- [Mediator - Refactoring Guru](https://refactoring.guru/design-patterns/mediator)
- [The Mediator Design Pattern in Java | Baeldung](https://www.baeldung.com/java-mediator-pattern)
- [Mediator Pattern Consequences - GoF Pattern](https://www.gofpattern.com/design-patterns/module6/benefits-pitfalls-mediatorPattern.php)
- [Mediator Design Pattern - Devonblog](https://devonblog.com/software-development/mediator-design-pattern/)

### 書籍

- "Design Patterns: Elements of Reusable Object-Oriented Software" by Gang of Four (GoF)
  - ASIN: 0201633612
  - 邦訳: "オブジェクト指向における再利用のためのデザインパターン" (ASIN: 4797311126)

## 9. まとめ

Mediatorパターンは、複数のオブジェクト間の複雑な相互作用を管理するための強力なツールである。疎結合を実現し、保守性と拡張性を向上させるが、仲介者自体が複雑になりすぎないよう注意が必要である。

### 適用の判断基準

- ✅ 複雑なオブジェクト間通信がある
- ✅ 密結合が問題になっている
- ✅ 通信ルールが頻繁に変更される
- ❌ 相互作用がシンプル
- ❌ パフォーマンスが最重要
- ❌ 仲介者が過度に複雑になる懸念

---

**調査完了日**: 2026-01-01
**信頼度**: 高（複数の信頼できるソースから情報を収集）
