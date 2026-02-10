# Plot Outline: Factory Method Pattern

## I. 導入 (Admission) - 往診

### 状況設定
深夜のスタートアップオフィス。緊急アラートが鳴り響く中、患者（CTO）がSlackの障害報告を見つめている。kintone連携モジュールのリリース直後、なぜかSalesforce連携まで動かなくなった。

### 患者の心理状態
「また連携系の障害だ…。もう何度目だ。新しい連携先を追加するたび、どこかが壊れる。接続コードはメインロジックに直書きしてあるから、毎回全テストが必要で…。でも今さら設計からやり直す余裕なんてない」

### ドクター登場
オフィスのドアが静かに開き、黒い往診鞄を持った長身の男とパステルカラーの白衣を着た若い女性が入ってくる。

- 患者：「どちら様ですか…？」
- ナナコ：「初めまして。私はナナコ。こちらはドクターです。お困りのコード、拝見しに参りました」
- ドクター：（モニターを一瞥）「…癒着」
- 患者：「は？」

## II. 検査 (Examination) - 触診

### 問題特定
ドクターがIDEを開き、接続コードを見る。`DataSyncService.pm`を開くと、巨大なif-elsif-elseのチェーンが目に入る。

```perl
# Before: DataSyncService.pm
sub sync_data($self, $target, $data) {
    if ($target eq 'salesforce') {
        my $client = SalesforceClient->new(
            api_key => $ENV{SF_API_KEY},
            endpoint => $ENV{SF_ENDPOINT},
        );
        $client->push_records($data);
    }
    elsif ($target eq 'kintone') {
        my $client = KintoneClient->new(
            token => $ENV{KINTONE_TOKEN},
            app_id => $ENV{KINTONE_APP_ID},
        );
        $client->upsert($data);
    }
    elsif ($target eq 'slack') {
        # ...以下続く
    }
    # 新規連携先を追加するたび、ここに分岐が増える
}
```

### ドクターの反応
- ドクター：（マウスで分岐の長さをスクロールしながら）「…生成と利用。混在」
- ナナコ：「先生がおっしゃっているのは、『何を作るか』と『どう使うか』が同じ場所に書かれていますね、という意味です。臓器と神経が絡まり合っているような状態でしょうか」
- 患者：「そ、それで…治せるんですか？」
- ドクター：「癒着分離」

### 患者の反応
「癒着分離…？手術ってこと？僕のコードを…切る？」

## III. 処置 (Surgery) - 癒着分離手術

### 手術方針
ドクターが黙々とキーボードを叩き始める。ナナコが横で解説する。

- ナナコ：「まず、接続先ごとのクライアント生成を『工場』に切り出します。DataSyncServiceは『何を同期するか』だけに集中できるようになります」

### コード変換

**Step 1: 抽象クライアントRoleの定義**
```perl
# lib/Role/SyncClient.pm
package Role::SyncClient {
    use Moo::Role;
    requires 'sync';
}
```

**Step 2: 具象クライアントの実装**
```perl
# lib/SyncClient/Salesforce.pm
package SyncClient::Salesforce {
    use Moo;
    with 'Role::SyncClient';
    
    has api_key  => (is => 'ro', required => 1);
    has endpoint => (is => 'ro', required => 1);
    
    sub sync($self, $data) {
        # Salesforce固有の同期処理
        ...
    }
}
```

**Step 3: 工場クラス（Factory Method）**
```perl
# lib/SyncClientFactory.pm
package SyncClientFactory {
    use Moo;
    
    sub create($self, $target) {
        my $class = "SyncClient::" . ucfirst($target);
        eval "require $class" or die "Unknown target: $target";
        return $class->new($self->_config_for($target)->%*);
    }
    
    sub _config_for($self, $target) {
        state $configs = {
            salesforce => { api_key => $ENV{SF_API_KEY}, endpoint => $ENV{SF_ENDPOINT} },
            kintone    => { token => $ENV{KINTONE_TOKEN}, app_id => $ENV{KINTONE_APP_ID} },
            # 新規追加はここに設定を足すだけ
        };
        return $configs->{$target} // {};
    }
}
```

**Step 4: メインロジックの浄化**
```perl
# lib/DataSyncService.pm (After)
package DataSyncService {
    use Moo;
    
    has factory => (
        is => 'ro',
        default => sub { SyncClientFactory->new },
    );
    
    sub sync_data($self, $target, $data) {
        my $client = $self->factory->create($target);
        $client->sync($data);
    }
}
```

### カタルシスポイント
- ナナコ：「できました。DataSyncServiceから条件分岐が消えましたね」
- 患者：「え…あの100行以上あったif-elseが…たった3行に？」
- ドクター：「…分離完了」

## IV. 予後 (Prognosis) - 術後経過

### 改善確認
テストを実行すると、すべてグリーン。新しい連携先を追加するときは、`SyncClient::NewTarget.pm`を作成し、工場の設定に1行追加するだけ。

- ナナコ：「これで新しい連携先が増えても、既存のコードに触れる必要がなくなります」
- 患者：「本当だ…既存のテストに影響が出ない…」

### 勘違いシーン
ドクターが鞄から小さなメモを取り出し、患者のデスクに置く。

- 患者：（これは…連絡先？もしかして、また困ったときに相談していいってこと？）
- ナナコ：「それ、設計パターンの参考書籍リストです。先生のおすすめだそうです」
- 患者：「あ、ああ…そうですよね」（赤面）

### 別れ
- ドクター：（すでにドアに向かいながら）「…リハビリは自力で」
- ナナコ：「今後は新しい接続先が増えても、工場に任せてください。メインロジックは、もう臓器移植のリスクを背負わなくて済みます」
- 患者：「ありがとうございます…！」

ドアが閉まる。患者は新しいコードを眺めながら、明日からの開発がずっと楽になることを確信する。

---

# メモ: 勘違いシーン配置

- **配置**: IV. 予後（定石通り）
- **トリガー**: ドクターがメモを渡す
- **誤解内容**: 連絡先と勘違い（実は参考書籍リスト）
- **オチ**: ナナコの淡々とした訂正で患者が赤面
