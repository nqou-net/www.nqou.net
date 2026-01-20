#!/bin/bash

echo "=== PerlとMooでAPIレスポンスシミュレーター 構文検証 ==="
echo ""

for episode in 01 02 03 04 05 06 07 08; do
    echo "【第${episode}回】"
    
    # mock_api.plの検証
    if [ -f "$episode/mock_api.pl" ]; then
        # ファイルのライン数と主要構造を表示
        lines=$(wc -l < "$episode/mock_api.pl")
        packages=$(grep -c '^package ' "$episode/mock_api.pl" || echo 0)
        subs=$(grep -c '^\s*sub ' "$episode/mock_api.pl" || echo 0)
        
        echo "  ✓ ファイル存在: mock_api.pl"
        echo "    - 総行数: ${lines}"
        echo "    - パッケージ数: ${packages}"
        echo "    - サブルーチン数: ${subs}"
    fi
    
    # テストファイルの検証
    if [ -f "$episode/t/01_basic.t" ]; then
        test_lines=$(wc -l < "$episode/t/01_basic.t")
        tests=$(grep -c 'ok(' "$episode/t/01_basic.t" || echo 0)
        
        echo "  ✓ テストファイル: t/01_basic.t"
        echo "    - 総行数: ${test_lines}"
        echo "    - テスト数: 約${tests}個"
    fi
    
    echo ""
done

echo "=== Perl構文の主要パターン確認 ==="
echo ""

# シグネチャ構文の使用確認
echo "【シグネチャ構文の使用状況】"
for episode in 01 02 03 04 05 06 07 08; do
    count=$(grep -cE '^\s*sub [a-z_]+\(\$self' "$episode/mock_api.pl" 2>/dev/null || echo 0)
    if [ "$count" -gt 0 ]; then
        echo "  第${episode}回: ${count}箇所でシグネチャ使用"
    fi
done

echo ""
echo "【JSONの使用状況】"
for episode in 01 02 03 04 05 06 07 08; do
    has_json=$(grep -c 'use JSON' "$episode/mock_api.pl" 2>/dev/null || echo 0)
    json_true=$(grep -c 'JSON::true' "$episode/mock_api.pl" 2>/dev/null || echo 0)
    json_false=$(grep -c 'JSON::false' "$episode/mock_api.pl" 2>/dev/null || echo 0)
    if [ $has_json -gt 0 ]; then
        echo "  第${episode}回: JSON::true=${json_true}, JSON::false=${json_false}"
    fi
done

echo ""
echo "【Role/継承パターンの導入状況】"
for episode in 01 02 03 04 05 06 07 08; do
    has_role=$(grep -c 'use Moo::Role' "$episode/mock_api.pl" 2>/dev/null || echo 0)
    has_with=$(grep -c "with '" "$episode/mock_api.pl" 2>/dev/null || echo 0)
    has_extends=$(grep -c "extends '" "$episode/mock_api.pl" 2>/dev/null || echo 0)
    
    if [ $has_role -gt 0 ] || [ $has_with -gt 0 ] || [ $has_extends -gt 0 ]; then
        echo -n "  第${episode}回: "
        [ $has_role -gt 0 ] && echo -n "Role定義あり "
        [ $has_with -gt 0 ] && echo -n "with=${has_with} "
        [ $has_extends -gt 0 ] && echo -n "extends=${has_extends} "
        echo ""
    fi
done

echo ""
echo "=== 各回で実装されているシナリオ ==="
for episode in 01 02 03 04 05 06 07 08; do
    echo "【第${episode}回】"
    grep 'package.*Scenario' "$episode/mock_api.pl" 2>/dev/null | sed 's/package //; s/ {//' | sed 's/^/  - /'
    echo ""
done
