use v5.36;
use utf8;
use open qw(:std :utf8);

# Patient's Code: "Mixed Factories in One Huge Class"
# 症状: 職業ごとの装備生成ロジックが1つのメソッドに詰め込まれている。
# リスク: 新しい職業を追加するたびにこのメソッドを修正する必要があり、
#        別の職業のロジックを壊すリスクがある（Open/Closed Principle違反）。

package Game::Bad::EquipmentManager;

sub new($class) { bless {}, $class }

sub create_equipment($self, $job_type) {
    my $equipment = {};

    # 共通処理のつもりで書いたが、実は職業ごとに微妙に違うので if が増殖
    if ($job_type eq 'Warrior') {
        $equipment->{weapon} = 'Mighty Sword';
        $equipment->{armor}  = 'Heavy Plate';
        $equipment->{skill}  = 'Slash';
    }
    elsif ($job_type eq 'Mage') {
        $equipment->{weapon} = 'Old Staff';
        $equipment->{armor}  = 'Silk Robe';
        $equipment->{skill}  = 'Fireball';
    }
    elsif ($job_type eq 'Thief') {
        $equipment->{weapon} = 'Dagger';
        $equipment->{armor}  = 'Leather Mail';

        # BUG: コピペミスで Mage のスキルを上書きしてしまう恐れがあったり、
        # ここに共通処理を書くと Warrior に影響したりする。
        $equipment->{skill} = 'Steal';
    }
    else {
        die "Unknown job type: $job_type";
    }

    # 苦し紛れの共通処理
    $equipment->{bgm} = 'Battle_Theme_v1.mp3';

    return $equipment;
}

package main;

# Client Code
my $manager = Game::Bad::EquipmentManager->new;

say "--- Character Creation ---";
for my $job (qw(Warrior Mage Thief)) {
    my $eq = $manager->create_equipment($job);
    say "[$job] Weapon: $eq->{weapon}, Armor: $eq->{armor}, Skill: $eq->{skill}";
}
