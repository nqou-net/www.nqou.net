# Patient Profile
- Name: 限界突破のゲームクリエイター (26)
- Role: インディーゲーム開発サークルのリードプログラマー
- Personality: 情熱的で「物量こそ正義」と信じている。最適化は後回しにするタイプ。深夜テンションでコードを書くことが多い。
- First Person: 「俺」
- Background: 初の本格RTS（リアルタイムストラテジー）「軍団大戦争」を開発中。画面を埋め尽くす1万体の兵士を描画したいが、兵士を100体出した時点でメモリ警告が出てクラッシュする。
- Main Complaint: 「たった1万体です！ 最新のPCなら余裕のはずなのに、なんでメモリが足りなくなるんですか！？」

# Medical Chart
- Symptom: 全ての兵士（インスタンス）が、共通の「グラフィックデータ」や「基本ステータス」を個別に保持している。肥満細胞が大量増殖して血管を詰まらせている状態。
- Metaphor: 「本来なら教科書（共有データ）を一冊置いてみんなで読めばいいのに、兵士全員に辞書並みの厚さの教科書を個別に配布して、リュック（メモリ）をパンクさせている」
- Diagnosis: 重度インスタンス肥大症（Massive Object Bloating due to Redundant State）
- Cure: Flyweight Patternによる「共有状態（Intrinsic State）の分離」と「参照渡し（Extrinsic Stateの注入）」。教科書の回収と共有本棚の設置。
