---
title: "Singletonパターン完全ガイド：実装からアンチパターン回避まで【2025年版】"
draft: true
tags:
  - singleton-pattern
  - design-patterns
  - dependency-injection
description: "Singletonパターンの実装方法を5言語で解説。スレッドセーフな実装、DIコンテナとの比較、テスタビリティ問題への対処法まで実務で使える知識を網羅。GoFデザインパターンの定番を現代的視点で学ぶ"
---

[@nqounet](https://x.com/nqounet)です。

デザインパターンの中でも最も有名で、かつ最も議論を呼ぶパターンの一つが「Singleton（シングルトン）パターン」です。

1994年にGoF（Gang of Four）によって提唱されて以来、30年以上にわたって使われ続ける一方で、「アンチパターンだ」という批判も少なくありません。

本記事では、Singletonパターンの基礎から実装、そして現代的な使い方まで、実務で役立つ知識を包括的に解説します。

## Singletonパターンとは？基本概念を理解する

Singletonパターンは、クラスのインスタンスが必ず1つだけ存在することを保証し、そのインスタンスへのグローバルなアクセスポイントを提供するデザインパターンです。

### GoFデザインパターンにおける定義

GoF（Gang of Four）の書籍『Design Patterns: Elements of Reusable Object-Oriented Software』（1994年）では、Singletonパターンは「生成パターン（Creational Patterns）」の一つとして分類されています。

生成パターンは、オブジェクトの生成メカニズムに関するパターンで、システムがどのようにオブジェクトを作成・構成・表現するかの柔軟性を提供します。

Singletonパターンの目的は以下の2点です。

- クラスのインスタンスが1つしか存在しないことを保証する
- そのインスタンスへのグローバルなアクセスポイントを提供する

### 3つの構成要素（プライベートコンストラクタ・静的変数・アクセスメソッド）

Singletonパターンの実装には、以下の3つの要素が必要です。

**プライベートコンストラクタ**

外部からのインスタンス化を防ぐため、コンストラクタを`private`（または言語によっては非公開）にする

**静的インスタンス変数**

唯一のインスタンスを保持するための静的変数（クラス変数）

**静的アクセスメソッド**

唯一のインスタンスを取得するための公開された静的メソッド（通常は`getInstance()`という名前）

この3つの要素により、クラスの外部からは必ず同じインスタンスにアクセスすることになります。

### なぜ「唯一のインスタンス」が必要なのか

「唯一のインスタンス」が必要な理由は、主に以下の3つです。

**リソースの一元管理**

データベース接続プールやファイルハンドラなど、システム全体で統一して管理すべきリソースがある

**状態の共有**

アプリケーション全体で共有すべき設定情報やキャッシュデータがある

**整合性の保証**

複数のインスタンスが存在すると、状態の不整合やリソースの競合が発生する可能性がある

ただし、この「唯一性の保証」が本当に必要かどうかは、慎重に検討する必要があります。後述しますが、安易なSingletonの使用は様々な問題を引き起こす可能性があります。

## Singletonパターンが必要な5つの典型的シーン

Singletonパターンが適用される典型的なシーンを見ていきましょう。

### ロギングシステム：アプリケーション全体で統一したログ管理

アプリケーション全体でログ出力先や形式を統一する必要がある場合、Singletonパターンが使われることがあります。

**メリット**

- ログ設定を一元管理できる
- ファイルハンドラなどのリソースを共有できる
- アプリケーションのどこからでも同じロガーにアクセスできる

**注意点**

現代では、DIコンテナやロギングフレームワーク（Log4j、SLF4J、Serilogなど）を使う方が推奨される

### 設定管理：グローバルな設定情報への一元アクセス

アプリケーション設定（config.json、application.propertiesなど）をメモリに読み込み、全体で共有する場合です。

**メリット**

- 設定ファイルの読み込みを1回だけ実行できる
- 設定値へのアクセスが高速である
- 設定の一貫性が保たれる

**注意点**

環境変数やDIコンテナの設定管理機能を使う方が、テスタビリティと保守性が向上する

### データベース接続プール：リソースの効率的管理

データベース接続を使い回すための接続プールを管理する場合です。

**メリット**

- 接続リソースを効率的に管理できる
- 接続数の制限を確実に守れる
- パフォーマンスが向上する

**注意点**

現代のORMやフレームワーク（Spring JDBC、Entity Framework、Active Recordなど）は、接続プール管理機能を内蔵している

### スレッドプール・キャッシュマネージャー

スレッドプールやメモリキャッシュのように、システムリソースを管理する場合です。

**適用例**

- `java.util.concurrent.ExecutorService`を使ったスレッドプール管理
- Redisクライアントの接続管理
- メモリキャッシュ（Caffeine、Guavaなど）の管理

**現代的アプローチ**

これらも通常はDIコンテナで管理し、必要なコンポーネントに注入する方が望ましい

### 使用を避けるべき場面【重要】

以下の場合、Singletonパターンの使用は避けるべきです。

**ビジネスロジックを持つクラス**

テスタビリティが著しく低下する

**状態を頻繁に変更するクラス**

マルチスレッド環境で競合状態が発生しやすい

**異なる設定で複数インスタンスが必要になる可能性がある場合**

後から要件変更に対応できなくなる

**分散システムやマイクロサービスアーキテクチャ**

単一プロセス内でしか唯一性が保証されないため、分散環境では機能しない

**テストで異なる状態を使いたい場合**

テストの独立性が失われる

## 5言語で学ぶ実装パターン【コピペOK】

Singletonパターンの実装を、5つのプログラミング言語で見ていきましょう。

### Java：Enum実装が最強の理由（Joshua Bloch推奨）

Javaでは、複数の実装方法がありますが、**Enum実装が最も推奨されます**。

#### Enum実装（推奨）

```java
public enum DatabaseConnection {
    INSTANCE;
    
    private Connection connection;
    
    DatabaseConnection() {
        // 初期化処理
        this.connection = createConnection();
    }
    
    public Connection getConnection() {
        return connection;
    }
    
    private Connection createConnection() {
        // データベース接続を作成
        return DriverManager.getConnection("jdbc:...");
    }
}

// 使用例
Connection conn = DatabaseConnection.INSTANCE.getConnection();
```

**Enum実装のメリット**

- シリアライゼーションに対して安全である
- リフレクション攻撃に対して安全である
- スレッドセーフである（JVMが保証）
- コードが簡潔である

Joshua Bloch（『Effective Java』著者）は、「単一要素のenumはSingletonを実装する最良の方法」と述べています。

#### Double-Checked Locking実装

遅延初期化が必要な場合の実装です。

```java
public class ConfigManager {
    private static volatile ConfigManager instance;
    private Properties config;
    
    private ConfigManager() {
        // 設定ファイルを読み込む
        this.config = loadConfig();
    }
    
    public static ConfigManager getInstance() {
        if (instance == null) {  // 1st check
            synchronized (ConfigManager.class) {
                if (instance == null) {  // 2nd check
                    instance = new ConfigManager();
                }
            }
        }
        return instance;
    }
    
    private Properties loadConfig() {
        Properties props = new Properties();
        // ファイル読み込み処理
        return props;
    }
}
```

**重要**: `volatile`キーワードは必須です。これがないと、マルチスレッド環境で不完全なオブジェクトが参照される可能性があります。

### Python：Metaclassとデコレータ実装

Pythonでは、メタクラスを使う方法とデコレータを使う方法があります。

#### Metaclass実装

```python
class SingletonMeta(type):
    _instances = {}
    
    def __call__(cls, *args, **kwargs):
        if cls not in cls._instances:
            cls._instances[cls] = super().__call__(*args, **kwargs)
        return cls._instances[cls]

class Logger(metaclass=SingletonMeta):
    def __init__(self):
        self.log_file = "app.log"
    
    def log(self, message):
        with open(self.log_file, 'a') as f:
            f.write(f"{message}\n")

# 使用例
logger1 = Logger()
logger2 = Logger()
print(logger1 is logger2)  # True
```

#### デコレータ実装

```python
def singleton(cls):
    instances = {}
    
    def get_instance(*args, **kwargs):
        if cls not in instances:
            instances[cls] = cls(*args, **kwargs)
        return instances[cls]
    
    return get_instance

@singleton
class ConfigManager:
    def __init__(self):
        self.settings = self._load_settings()
    
    def _load_settings(self):
        return {"debug": True, "timeout": 30}

# 使用例
config1 = ConfigManager()
config2 = ConfigManager()
print(config1 is config2)  # True
```

デコレータ実装の方がシンプルで読みやすいため、一般的にはこちらが推奨されます。

### C#：Lazy&lt;T&gt;を使ったモダンな実装

C#では、`Lazy<T>`を使った実装が最もモダンで安全です。

```csharp
public sealed class ConfigurationManager
{
    private static readonly Lazy<ConfigurationManager> _instance =
        new Lazy<ConfigurationManager>(() => new ConfigurationManager());
    
    private Dictionary<string, string> _settings;
    
    private ConfigurationManager()
    {
        // 設定を読み込む
        _settings = LoadSettings();
    }
    
    public static ConfigurationManager Instance => _instance.Value;
    
    private Dictionary<string, string> LoadSettings()
    {
        return new Dictionary<string, string>
        {
            { "AppName", "MyApp" },
            { "Version", "1.0.0" }
        };
    }
    
    public string GetSetting(string key)
    {
        return _settings.ContainsKey(key) ? _settings[key] : null;
    }
}

// 使用例
var config = ConfigurationManager.Instance;
string appName = config.GetSetting("AppName");
```

**Lazy&lt;T&gt;のメリット**

- スレッドセーフである（デフォルトでロックベース）
- 遅延初期化が自動的に行われる
- コードが簡潔で読みやすい
- .NET Framework 4.0以降で使用可能

### JavaScript/TypeScript：クロージャとクラス実装

JavaScriptでは、クロージャを使った実装とクラスを使った実装があります。

#### クロージャ実装（JavaScript）

```javascript
const Logger = (function() {
    let instance;
    
    function createInstance() {
        return {
            logFile: 'app.log',
            log(message) {
                console.log(`[LOG] ${message}`);
                // ファイル書き込み処理
            }
        };
    }
    
    return {
        getInstance() {
            if (!instance) {
                instance = createInstance();
            }
            return instance;
        }
    };
})();

// 使用例
const logger1 = Logger.getInstance();
const logger2 = Logger.getInstance();
console.log(logger1 === logger2);  // true
```

#### クラス実装（TypeScript）

```typescript
class ConfigurationManager {
    private static instance: ConfigurationManager;
    private settings: Map<string, any>;
    
    private constructor() {
        this.settings = new Map();
        this.loadSettings();
    }
    
    public static getInstance(): ConfigurationManager {
        if (!ConfigurationManager.instance) {
            ConfigurationManager.instance = new ConfigurationManager();
        }
        return ConfigurationManager.instance;
    }
    
    private loadSettings(): void {
        this.settings.set('appName', 'MyApp');
        this.settings.set('version', '1.0.0');
    }
    
    public getSetting(key: string): any {
        return this.settings.get(key);
    }
}

// 使用例
const config1 = ConfigurationManager.getInstance();
const config2 = ConfigurationManager.getInstance();
console.log(config1 === config2);  // true
```

TypeScript実装では、`private constructor`により外部からのインスタンス化を防いでいます。

### Perl：Mooを使った実装

Perlでは、Mooモジュールを使って簡潔にSingletonを実装できます。

```perl
package ConfigManager {
    use Moo;
    use MooX::Singleton;
    
    has 'config' => (
        is => 'ro',
        default => sub { 
            return { debug => 1, timeout => 30 };
        }
    );
    
    sub get_setting {
        my ($self, $key) = @_;
        return $self->config->{$key};
    }
}

# 使用例
use ConfigManager;

my $config1 = ConfigManager->instance;
my $config2 = ConfigManager->instance;

print $config1->get_setting('debug');  # 1
print $config1 == $config2 ? "同一" : "異なる";  # 同一
```

`MooX::Singleton`を使うことで、シンプルにSingletonパターンを実装できます。

### 実装比較表：どの手法を選ぶべきか

| 言語 | 推奨実装 | スレッドセーフ | 遅延初期化 | 実装の複雑さ |
|------|---------|--------------|----------|------------|
| **Java** | Enum | ✓ | × | 低 |
| **Python** | デコレータ | △ | ✓ | 低 |
| **C#** | Lazy&lt;T&gt; | ✓ | ✓ | 低 |
| **JavaScript** | クロージャ | × | ✓ | 中 |
| **TypeScript** | クラス | × | ✓ | 中 |
| **Perl** | MooX::Singleton | △ | ✓ | 低 |

**選択基準**

- **スレッドセーフが必須**: Java Enum、C# Lazy&lt;T&gt;
- **シンプルさ重視**: Python デコレータ、Perl MooX::Singleton
- **遅延初期化が必要**: C# Lazy&lt;T&gt;、Python、JavaScript

## スレッドセーフティの罠と対策

マルチスレッド環境でのSingletonパターンの実装は、慎重に行う必要があります。

### マルチスレッド環境での問題点

Singletonパターンをマルチスレッド環境で使う際の主な問題は、以下の通りです。

**複数インスタンスの生成**

複数スレッドが同時に`getInstance()`を呼び出すと、複数のインスタンスが生成される可能性がある

**不完全なオブジェクトの参照**

あるスレッドが初期化中のオブジェクトを、別のスレッドが参照してしまう可能性がある

**デッドロック**

不適切な同期処理により、デッドロックが発生する可能性がある

### Double-Checked Lockingパターン（volatileの重要性）

Double-Checked Lockingパターンは、遅延初期化とスレッドセーフティを両立させるパターンです。

```java
public class Singleton {
    // volatileは必須！
    private static volatile Singleton instance;
    
    private Singleton() {}
    
    public static Singleton getInstance() {
        if (instance == null) {           // 1st check (ロック不要)
            synchronized (Singleton.class) {
                if (instance == null) {   // 2nd check (ロック内)
                    instance = new Singleton();
                }
            }
        }
        return instance;
    }
}
```

**volatileが必要な理由**

Javaのメモリモデルでは、`volatile`なしでは以下の問題が発生する可能性があります。

- コンパイラの最適化により、命令の並び替えが行われる
- CPUキャッシュにより、他のスレッドから変更が見えない
- オブジェクトの部分的に初期化された状態が見える

`volatile`キーワードを付けることで、以下が保証されます。

- 書き込みは即座にメインメモリに反映される
- 読み込みは常にメインメモリから行われる
- 命令の並び替えが制限される

### 言語別のスレッドセーフな実装ベストプラクティス

各言語でのスレッドセーフな実装のベストプラクティスをまとめます。

**Java**

Enum実装を使う（JVMがスレッドセーフを保証）

**Python**

スレッドロックを使った実装

```python
import threading

class ThreadSafeSingleton:
    _instance = None
    _lock = threading.Lock()
    
    def __new__(cls):
        if cls._instance is None:
            with cls._lock:
                if cls._instance is None:
                    cls._instance = super().__new__(cls)
        return cls._instance
```

**C#**

`Lazy<T>`を使う（デフォルトでスレッドセーフ）

**JavaScript/TypeScript**

JavaScriptはシングルスレッドだが、非同期処理を考慮する

```typescript
class AsyncSafeSingleton {
    private static instance: AsyncSafeSingleton | null = null;
    private static initPromise: Promise<AsyncSafeSingleton> | null = null;
    
    private constructor() {}
    
    public static async getInstance(): Promise<AsyncSafeSingleton> {
        if (this.instance !== null) {
            return this.instance;
        }
        
        if (this.initPromise !== null) {
            return this.initPromise;
        }
        
        this.initPromise = (async () => {
            this.instance = new AsyncSafeSingleton();
            await this.instance.initialize();
            return this.instance;
        })();
        
        return this.initPromise;
    }
    
    private async initialize(): Promise<void> {
        // 非同期初期化処理
    }
}
```

## Spring/DIコンテナ時代のSingleton戦略

現代のフレームワークでは、DIコンテナがSingletonの管理を行います。

### 従来のSingletonパターン vs Spring Singleton Bean

Spring FrameworkにおけるSingleton Beanは、従来のSingletonパターンとは異なります。

**従来のSingletonパターン**

- クラスレベルで唯一性を保証する
- JVM全体で1つのインスタンス
- グローバルな静的メソッドでアクセス

**Spring Singleton Bean**

- DIコンテナ内で唯一性を保証する
- 1つのApplicationContext内で1つのインスタンス
- 依存性注入によりアクセス

```java
// 従来のSingleton
DatabaseConnection conn = DatabaseConnection.getInstance();

// Spring Singleton Bean
@Service
public class UserService {
    private final DatabaseConnection connection;
    
    @Autowired
    public UserService(DatabaseConnection connection) {
        this.connection = connection;  // DIコンテナが注入
    }
}
```

**Spring Singleton Beanのメリット**

- テスタビリティが高い（モックに置き換え可能）
- ライフサイクル管理が容易
- 設定の外部化が可能
- SOLID原則に準拠

### .NET Core/ASP.NET Coreでのライフタイム管理

.NET Coreでは、3種類のライフタイムが提供されています。

```csharp
public void ConfigureServices(IServiceCollection services)
{
    // Singleton: アプリケーション全体で1つ
    services.AddSingleton<IConfigurationManager, ConfigurationManager>();
    
    // Scoped: リクエストごとに1つ
    services.AddScoped<IUserRepository, UserRepository>();
    
    // Transient: 要求ごとに新しいインスタンス
    services.AddTransient<IEmailService, EmailService>();
}
```

**Singletonライフタイム**

アプリケーションの起動時に1度だけ作成され、アプリケーション終了まで保持される

**Scopedライフタイム**

HTTPリクエストごとに1つのインスタンスが作成され、リクエスト終了時に破棄される

**Transientライフタイム**

要求されるたびに新しいインスタンスが作成される

### 依存性注入（DI）で解決できる問題

DIコンテナを使うことで、従来のSingletonパターンの問題が解決されます。

**テスタビリティの向上**

```csharp
// テスト時はモックを注入できる
public class UserServiceTests
{
    [Fact]
    public void TestGetUser()
    {
        var mockRepo = new Mock<IUserRepository>();
        var service = new UserService(mockRepo.Object);
        
        // テスト実行
    }
}
```

**疎結合の実現**

インターフェースに依存することで、実装の差し替えが容易になる

**ライフサイクル管理の柔軟性**

設定ファイルでライフタイムを変更できる

**循環依存の検出**

DIコンテナが起動時に循環依存を検出してエラーを出す

## Singletonの「5つの欠点」と現実的な対処法

Singletonパターンには、いくつかの欠点があります。

### テスタビリティ問題：モック化の困難さ

Singletonパターンの最大の問題は、ユニットテストが困難になることです。

**問題の具体例**

```java
// テスト対象のクラス
public class UserService {
    public User getUser(int id) {
        // Singletonへの直接依存
        DatabaseConnection conn = DatabaseConnection.getInstance();
        return conn.query("SELECT * FROM users WHERE id = ?", id);
    }
}

// テストコード
@Test
public void testGetUser() {
    // 問題: DatabaseConnectionをモックに置き換えられない
    // 実際のデータベースへの接続が必要になってしまう
    UserService service = new UserService();
    User user = service.getUser(1);
    assertNotNull(user);
}
```

**対処法：依存性注入を使う**

```java
// 改善後
public class UserService {
    private final DatabaseConnection connection;
    
    // コンストラクタインジェクション
    public UserService(DatabaseConnection connection) {
        this.connection = connection;
    }
    
    public User getUser(int id) {
        return connection.query("SELECT * FROM users WHERE id = ?", id);
    }
}

// テストコード
@Test
public void testGetUser() {
    // モックを注入できる
    DatabaseConnection mockConn = mock(DatabaseConnection.class);
    when(mockConn.query(anyString(), eq(1)))
        .thenReturn(new User(1, "John"));
    
    UserService service = new UserService(mockConn);
    User user = service.getUser(1);
    
    assertEquals("John", user.getName());
}
```

### グローバル状態による保守性の低下

Singletonはグローバル状態を持つため、以下の問題が発生します。

**隠れた依存関係**

どのクラスがSingletonに依存しているか、コードを読まないと分からない

**予期しない副作用**

あるクラスがSingletonの状態を変更すると、他のクラスにも影響が及ぶ

**並行実行の困難さ**

テストを並列実行すると、Singletonの状態が競合する

**対処法**

- 状態を持たないようにする（ステートレス化）
- DIコンテナで管理し、明示的に依存関係を示す
- イミュータブルな設計を心がける

### SOLID原則違反（SRP・DIP）

Singletonパターンは、SOLID原則のうち2つに違反します。

**単一責任原則（SRP）違反**

Singletonクラスは、以下の2つの責任を持ってしまいます。

- 本来の業務ロジック
- 自身のインスタンス管理

これは「1つのクラスは1つの責任を持つべき」という原則に反します。

**依存性逆転原則（DIP）違反**

`getInstance()`を直接呼び出すことは、具体的な実装に依存することを意味します。

```java
// 悪い例：具体的な実装に依存
public class OrderService {
    public void process() {
        Logger logger = Logger.getInstance();  // 具体クラスに依存
        logger.log("Order processed");
    }
}

// 良い例：抽象に依存
public class OrderService {
    private final ILogger logger;
    
    public OrderService(ILogger logger) {  // インターフェースに依存
        this.logger = logger;
    }
    
    public void process() {
        logger.log("Order processed");
    }
}
```

### スケーラビリティの限界（分散システムでの課題）

Singletonパターンは、単一プロセス内でしか唯一性を保証できません。

**分散システムでの問題**

- 複数のサーバーインスタンスで動作する場合、各サーバーで別々のSingletonインスタンスが作られる
- マイクロサービスアーキテクチャでは、サービスごとに別のSingletonが存在する
- 水平スケーリング時に、状態の整合性が取れなくなる

**対処法は後述の「分散Singleton」セクションで解説します**

### 各問題への実践的対処法

各問題への実践的な対処法をまとめます。

**テスタビリティ問題**

依存性注入を使い、インターフェース経由でアクセスする

**グローバル状態問題**

状態を持たない設計にするか、DIコンテナで管理する

**SOLID違反問題**

Factoryパターン + DIを使い、生成責任を分離する

**スケーラビリティ問題**

分散キャッシュ（Redis）やサービスメッシュを使う

**並行性問題**

言語・フレームワークのスレッドセーフな機能を使う

## アンチパターンとしての批判を理解する

Singletonパターンは、しばしば「アンチパターン」として批判されます。

### Robert C. Martin（Uncle Bob）の視点

『Clean Code』の著者Robert C. Martin（Uncle Bob）は、Singletonパターンについて批判的な見解を示しています。

**Uncle Bobの主張**

- Singletonはグローバル変数を隠蔽した形に過ぎない
- テストの独立性を損なう
- 依存関係を隠蔽し、コードの理解を困難にする
- 変更に弱い設計を生む

彼は、「Singletonを使うくらいなら、素直にDIを使うべき」と述べています。

### いつSingletonは「悪」になるのか

Singletonパターンが「悪」とされるのは、以下の場合です。

**ビジネスロジックに使う場合**

ビジネスルールは変更される可能性が高く、Singletonは変更を困難にする

**状態を持つ場合**

状態を持つSingletonは、予期しない副作用を生む

**「唯一性」が本質的な要件でない場合**

単に「便利だから」という理由で使うと、後で問題になる

**テストで異なる状態が必要な場合**

テストの独立性が失われ、テストの信頼性が低下する

**分散システムで使う場合**

単一プロセス内でしか唯一性が保証されない

### Golden Hammerアンチパターン

「Golden Hammer（金の槌）」とは、「すべての問題を釘に見立てて、槌で叩こうとする」というアンチパターンです。

Singletonパターンも、「便利だから」という理由で多用されがちですが、これはGolden Hammerアンチパターンの典型例です。

**症状**

- すべてのユーティリティクラスをSingletonにする
- 「グローバルにアクセスできると便利」という理由だけで使う
- 設計の複雑さを隠蔽するために使う

**対策**

- 本当に唯一性が必要か、慎重に検討する
- DIコンテナの使用を検討する
- パターンは「問題を解決するため」に使うものであり、「使うこと」自体が目的ではない

## Singletonの代替手段【2025年推奨】

現代では、Singletonパターンの代替となる、より優れた手法が存在します。

### 依存性注入（DI）：第一選択

**依存性注入（Dependency Injection）**は、Singletonパターンの最良の代替手段です。

```java
// Spring Bootの例
@Configuration
public class AppConfig {
    @Bean
    @Scope("singleton")  // DIコンテナが管理するSingleton
    public DatabaseConnection databaseConnection() {
        return new DatabaseConnection();
    }
}

@Service
public class UserService {
    private final DatabaseConnection connection;
    
    @Autowired  // DIコンテナが自動注入
    public UserService(DatabaseConnection connection) {
        this.connection = connection;
    }
}
```

**DIのメリット**

- テスタビリティが高い
- 依存関係が明示的
- ライフサイクル管理が柔軟
- SOLID原則に準拠

### Factoryパターン + DI

Factoryパターンとの組み合わせで、より柔軟な設計が可能です。

```java
public interface ConnectionFactory {
    Connection createConnection();
}

@Component
public class DatabaseConnectionFactory implements ConnectionFactory {
    @Override
    public Connection createConnection() {
        // 接続を作成
        return new DatabaseConnection();
    }
}

@Service
public class UserRepository {
    private final ConnectionFactory factory;
    
    @Autowired
    public UserRepository(ConnectionFactory factory) {
        this.factory = factory;
    }
    
    public User findById(int id) {
        try (Connection conn = factory.createConnection()) {
            // クエリ実行
        }
    }
}
```

### 分散Singleton（Redis・Etcd・Kubernetes）

分散システムでは、外部のストアを使ってSingleton的な動作を実現します。

**Redisを使った分散ロック**

```python
import redis
from contextlib import contextmanager

class DistributedSingleton:
    def __init__(self):
        self.redis_client = redis.Redis(host='localhost', port=6379)
        self.lock_key = 'singleton:lock'
        self.lock_timeout = 10  # seconds
    
    @contextmanager
    def acquire_lock(self):
        # 分散ロックを取得
        lock_acquired = self.redis_client.set(
            self.lock_key, 
            'locked', 
            nx=True,  # キーが存在しない場合のみ設定
            ex=self.lock_timeout
        )
        
        try:
            if lock_acquired:
                yield True
            else:
                yield False
        finally:
            if lock_acquired:
                self.redis_client.delete(self.lock_key)
    
    def get_instance(self):
        with self.acquire_lock() as acquired:
            if acquired:
                # 唯一のインスタンスを取得・作成
                instance_key = 'singleton:instance'
                instance = self.redis_client.get(instance_key)
                if not instance:
                    instance = self._create_instance()
                    self.redis_client.set(instance_key, instance)
                return instance
            else:
                raise Exception("Could not acquire lock")
```

**Kubernetesでのサービス管理**

```yaml
apiVersion: v1
kind: Service
metadata:
  name: config-service
spec:
  selector:
    app: config-manager
  ports:
  - protocol: TCP
    port: 80
    targetPort: 8080
  type: ClusterIP
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: config-manager
spec:
  replicas: 1  # Singleton的な動作を実現
  selector:
    matchLabels:
      app: config-manager
  template:
    metadata:
      labels:
        app: config-manager
    spec:
      containers:
      - name: config-manager
        image: config-manager:latest
```

### Monostateパターン

Monostate（別名：Borg）パターンは、Singletonの代替となるパターンです。

```python
class MonostateConfig:
    _shared_state = {}
    
    def __init__(self):
        self.__dict__ = self._shared_state
        if not hasattr(self, 'initialized'):
            self.settings = {}
            self.initialized = True
    
    def set(self, key, value):
        self.settings[key] = value
    
    def get(self, key):
        return self.settings.get(key)

# 使用例
config1 = MonostateConfig()
config1.set('debug', True)

config2 = MonostateConfig()
print(config2.get('debug'))  # True

print(config1 is config2)  # False（異なるインスタンス）
print(config1.settings is config2.settings)  # True（状態は共有）
```

**Monostateのメリット**

- 透過的である（通常のクラスと同じように使える）
- サブクラス化が可能
- 多態性が使える

**Monostateのデメリット**

- グローバル状態の問題は残る
- メモリ効率が若干悪い

### 選択基準フローチャート

どの手法を選ぶべきか、フローチャートで示します。

```
開始
  ↓
唯一性が本当に必要か？
  ├─ No → 通常のクラスを使う
  └─ Yes
      ↓
    DIコンテナを使っているか？
      ├─ Yes → DIコンテナで管理（推奨）
      └─ No
          ↓
        分散システムか？
          ├─ Yes → 分散Singleton（Redis等）
          └─ No
              ↓
            テストのしやすさが重要か？
              ├─ Yes → DIを導入する
              └─ No
                  ↓
                Singletonパターンを慎重に使う
                （Enum実装やLazy<T>を推奨）
```

## まとめ：Singletonを使う前に確認すべきチェックリスト

Singletonパターンを使う前に、以下のチェックリストを確認しましょう。

**使用判断チェックリスト**

- [ ] 本当に「唯一のインスタンス」が必要か？
- [ ] DIコンテナでの管理は検討したか？
- [ ] テストのしやすさは十分か？
- [ ] 将来的に複数インスタンスが必要になる可能性はないか？
- [ ] 分散システムで使う予定はないか？
- [ ] グローバル状態の問題を理解しているか？
- [ ] スレッドセーフな実装になっているか？

**2025年のベストプラクティス**

1. **DIコンテナを第一選択とする**: Spring、.NET Core、Google GuiceなどのDIコンテナを使う
2. **状態を持たない設計を心がける**: ステートレスなサービスにする
3. **インターフェースに依存する**: 具体的な実装ではなく、抽象に依存する
4. **テスタビリティを最優先する**: テストしやすい設計を心がける
5. **分散システムでは外部ストアを使う**: Redis、Etcd、Consulなどを活用する

**次に学ぶべきデザインパターン**

Singletonパターンを学んだ次は、以下のパターンを学ぶことをお勧めします。

**Factoryパターン**

オブジェクト生成の責任を分離する

**Strategyパターン**

アルゴリズムをカプセル化し、実行時に切り替え可能にする

{{< linkcard "/2025/12/30/164012/" >}}

**Observerパターン**

イベント駆動システムの基礎となるパターン

**Dependency Injection**

パターンというよりは設計原則だが、現代のソフトウェア開発では必須

関連記事として、Mooを使ったオブジェクト指向プログラミングのシリーズもご覧ください。

{{< linkcard "/2021/10/31/191008/" >}}

また、TDD（テスト駆動開発）の実践例として、値オブジェクトの設計についても解説しています。

{{< linkcard "/2025/12/25/234500/" >}}

---

Singletonパターンは、適切に使えば有用なパターンですが、安易な使用は多くの問題を引き起こします。

2025年の現代では、DIコンテナを使った管理が推奨されます。パターンは「問題を解決するため」に使うものであり、使うこと自体が目的になってはいけません。

本記事が、皆さんのソフトウェア設計の一助となれば幸いです。
