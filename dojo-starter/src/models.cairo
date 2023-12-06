use starknet::ContractAddress;
use debug::PrintTrait;

#[derive(Serde, Copy, Drop, Introspect)]
enum Direction {
    None: (),
    Left: (),
    Right: (),
    Up: (),
    Down: (),
}

#[derive(Model, Drop, Serde)]
struct Square {
    #[key]
    game_id: usize,
    #[key]
    vec: Vec2,
    piece: PieceType,
}

#[derive(Serde, Drop, Copy, PartialEq, Introspect)]
enum PieceType {
    Player: (),
    None: ()
}

#[derive(Model, Drop, Serde, Copy)]
struct GameSession {
    #[key]
    game_id: usize,
    is_live: bool,
    start_time: felt252,
    players: u8,
    is_won: bool
}

#[derive(Copy, Drop, Serde, Introspect)]
struct Vec2 {
    x: u32,
    y: u32
}

#[derive(Model, Copy, Drop, Serde)]
struct Position {
    #[key]
    player: ContractAddress,
    #[key]
    game_id: usize,
    vec: Vec2,
}

#[derive(Model, Copy, Drop, Serde)]
struct HealthPoints {
    #[key]
    player: ContractAddress,
    hp: u8,
}

#[derive(Model, Copy, Drop, Serde)]
struct RangePoints {
    #[key]
    player: ContractAddress,
    rp: u8,
}

#[derive(Model, Copy, Drop, Serde)]
struct ActionPoints {
    #[key]
    player: ContractAddress,
    ap: u8,
}

#[derive(Model, Copy, Drop, Serde)]
struct Alive {
    #[key]
    player: ContractAddress,
    is_alive: bool,
}

// Print implementations
impl Vec2PrintImpl of PrintTrait<Vec2> {
    fn print(self: Vec2) {
        'x: '.print();
        self.x.print();
        'y: '.print();
        self.y.print();
    }
}

impl PieceTypePrintImpl of PrintTrait<PieceType> {
    fn print(self: PieceType) {
        match self {
            PieceType::Player(()) => 'Player'.print(),
            PieceType::None(()) => 'None'.print()
        }
    }
}
