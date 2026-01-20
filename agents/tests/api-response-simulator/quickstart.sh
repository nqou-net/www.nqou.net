#!/bin/bash
# API Response Simulator - クイックスタートスクリプト

echo "=== PerlとMooでAPIレスポンスシミュレーター ==="
echo ""

# Dockerが利用可能かチェック
if command -v docker &> /dev/null; then
    echo "🐳 Dockerが見つかりました"
    echo ""
    echo "以下のコマンドで実行できます:"
    echo ""
    echo "  # Docker imageをビルド"
    echo "  docker build -t api-simulator ."
    echo ""
    echo "  # 第8回（最終版）を実行"
    echo "  docker run api-simulator"
    echo ""
    echo "  # 第1回を実行"
    echo "  docker run api-simulator perl 01/mock_api.pl"
    echo ""
    echo "  # テストを実行"
    echo "  docker run api-simulator perl 08/t/01_basic.t"
    echo ""
else
    echo "⚠️  Dockerが見つかりません"
    echo ""
    echo "ローカルで実行するには、以下のモジュールが必要です:"
    echo ""
    echo "  cpanm Moo JSON Time::HiRes Test::More"
    echo ""
    echo "または、システムパッケージ (Debian/Ubuntu):"
    echo ""
    echo "  sudo apt-get install libmoo-perl libjson-perl"
    echo ""
fi

echo ""
echo "📁 ディレクトリ構造:"
tree -L 2 -I 'lib' . 2>/dev/null || find . -maxdepth 2 -type f -name '*.pl' -o -name '*.t' | sort

echo ""
echo "📖 詳細は README.md と detailed_review.md を参照してください"
