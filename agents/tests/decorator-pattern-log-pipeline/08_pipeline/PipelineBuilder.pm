package PipelineBuilder;
use Moo;
use experimental qw(signatures);
use JSON::PP qw(decode_json);
use LogParser;
use Module::Load;

sub build ($self, $config_file, $log_file) {
    # 1. まず基本のパーサーを作る（一番芯の部分）
    my $processor = LogParser->new(filename => $log_file);

    # 2. JSON設定を読み込む
    open my $fh, '<', $config_file or die "Cannot open $config_file: $!";
    my $json_text = do { local $/; <$fh> };
    close $fh;
    
    my $steps = decode_json($json_text);

    # 3. 設定順にDecoratorを積み上げていく
    for my $step (@$steps) {
        my $module = $step->{module};
        my $args   = $step->{args} || {};

        # モジュールを動的にロード（use $module と同じ）
        load $module;

        # Decoratorで現在のprocessorを包み込み、新しいprocessorにする
        $processor = $module->new(
            wrapped => $processor,
            %$args,
        );
    }

    return $processor;
}

1;
