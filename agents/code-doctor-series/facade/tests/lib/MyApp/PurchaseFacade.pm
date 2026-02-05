package MyApp::PurchaseFacade;
use v5.36;
use External::ComplexSystem;

sub new ($class) {
    return bless {}, $class;
}

sub purchase_item ($self, $user, $item_name) {

    # 複雑な手順を隠蔽（カプセル化）する

    my $system = External::ComplexSystem->new;
    $system->initialize_subsystem();

    # デフォルト設定もここで吸収
    $system->set_config_param("timeout", 30);
    $system->set_config_param("mode",    "strict");

    my $token = $system->authenticate_user($user);
    $system->establish_connection($token);

    my $tx = $system->create_transaction();
    $tx->add_item($item_name);
    $tx->commit();

    return 1;
}

1;
