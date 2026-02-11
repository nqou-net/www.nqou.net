package DocumentTemplate;
use v5.36;

# === 議事録テンプレート ===
package DocumentTemplate::Minutes;
use v5.36;

sub new_template($class, %args) {
    return {
        type       => '議事録',
        department => $args{department} // '開発部',
        author     => $args{author}     // '未設定',
        date       => $args{date}       // '2025-01-01',
        version    => '1.0',

        # 共通メタデータ（全テンプレートにコピペ）
        metadata => {
            company      => '株式会社テックソリューション',
            division     => $args{department} // '開発部',
            fiscal_year  => '2025',
            confidential => 1,
        },
        sections => [{title => '出席者', content => ''}, {title => '議題', content => ''}, {title => '決定事項', content => ''}, {title => '次回予定', content => ''},],
    };
}

1;

# === 日報テンプレート ===
package DocumentTemplate::DailyReport;
use v5.36;

sub new_template($class, %args) {
    return {
        type       => '日報',
        department => $args{department} // '開発部',
        author     => $args{author}     // '未設定',
        date       => $args{date}       // '2025-01-01',
        version    => '1.0',

        # 共通メタデータ（全テンプレートにコピペ）
        metadata => {
            company      => '株式会社テックソリューション',
            division     => $args{department} // '開発部',
            fiscal_year  => '2025',
            confidential => 1,
        },
        sections =>
            [{title => '本日の作業', content => ''}, {title => '進捗状況', content => ''}, {title => '課題・問題', content => ''}, {title => '明日の予定', content => ''},],
    };
}

1;

# === 障害報告書テンプレート ===
package DocumentTemplate::IncidentReport;
use v5.36;

sub new_template($class, %args) {
    return {
        type       => '障害報告書',
        department => $args{department} // '開発部',
        author     => $args{author}     // '未設定',
        date       => $args{date}       // '2025-01-01',
        version    => '1.0',

        # 共通メタデータ（全テンプレートにコピペ）
        metadata => {
            company      => '株式会社テックソリューション',
            division     => $args{department} // '開発部',
            fiscal_year  => '2025',
            confidential => 1,
        },
        sections => [
            {title => '障害概要',  content => ''},
            {title => '影響範囲',  content => ''},
            {title => '原因分析',  content => ''},
            {title => '対応内容',  content => ''},
            {title => '再発防止策', content => ''},
        ],
    };
}

1;

# === 週報テンプレート ===
# TODO: 他の14種類も同じ構造で作る必要がある……
#       時間がなくて全部は書けないけど、全部同じパターンだから大丈夫（多分）
package DocumentTemplate::WeeklyReport;
use v5.36;

sub new_template($class, %args) {
    return {
        type       => '週報',
        department => $args{department} // '開発部',
        author     => $args{author}     // '未設定',
        date       => $args{date}       // '2025-01-01',
        version    => '1.0',

        # 共通メタデータ（全テンプレートにコピペ） ← 4回目のコピペ
        metadata => {
            company      => '株式会社テックソリューション',
            division     => $args{department} // '開発部',
            fiscal_year  => '2025',
            confidential => 1,
        },
        sections => [{title => '今週の実績', content => ''}, {title => '来週の計画', content => ''}, {title => '課題・リスク', content => ''},],
    };
}

1;
