use ascension::models::{Direction, GameSession, PieceType, Square, Vec2};

// define the interface
#[starknet::interface]
trait IActions<TContractState> {
    fn spawn_game(self: @TContractState, game_id: usize, start_time: felt252);
    fn spawn(self: @TContractState, game_id: usize);
    fn move(self: @TContractState, direction: Direction, game_id: usize);
}

// dojo decorator
#[dojo::contract]
mod actions {
    use starknet::{ContractAddress, get_caller_address};
    use ascension::models::{
        Position, Moves, Direction, Vec2, GameSession, PieceType, Square, HealthPoints, RangePoints,
        ActionPoints, Alive
    };
    use ascension::utils::calc_next_position;
    use super::IActions;
    use debug::PrintTrait;

    // declaring custom event struct
    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        Moved: Moved,
    }

    // declaring custom event struct
    #[derive(Drop, starknet::Event)]
    struct Moved {
        player: ContractAddress,
        direction: Direction
    }

    // impl: implement functions specified in trait
    #[external(v0)]
    impl ActionsImpl of IActions<ContractState> {
        fn spawn_game(self: @ContractState, game_id: usize, start_time: felt252) {
            // Access the world dispatcher for reading.
            let world = self.world_dispatcher.read();
            set!(
                world,
                (GameSession {
                    game_id: game_id,
                    is_live: false,
                    start_time: start_time,
                    players: 1,
                    is_won: false
                })
            );

            // set all cells of (11x11) grid to be of Type None
            let mut i: usize = 0;
            loop {
                if i > 11 {
                    break;
                }
                let mut j: usize = 0;
                loop {
                    if j > 11 {
                        break;
                    }
                    // set!(world, (Square { game_id: game_id, x: i, y: j, piece: PieceType::None },));
                    set!(
                        world,
                        (Square {
                            game_id: game_id, vec: Vec2 { x: i, y: j }, piece: PieceType::None
                        }),
                    );
                    j += 1;
                };
                i += 1;
            }
        }

        // ContractState is defined by system decorator expansion
        fn spawn(self: @ContractState, game_id: usize) {
            // Available spawn coordinates
            let mut spawn_locations = ArrayTrait::<Vec2>::new();
            spawn_locations.append(Vec2 { x: 0, y: 0 });
            spawn_locations.append(Vec2 { x: 0, y: 5 });
            spawn_locations.append(Vec2 { x: 0, y: 10 });
            spawn_locations.append(Vec2 { x: 5, y: 0 });
            spawn_locations.append(Vec2 { x: 5, y: 10 });
            spawn_locations.append(Vec2 { x: 10, y: 0 });
            spawn_locations.append(Vec2 { x: 10, y: 5 });
            spawn_locations.append(Vec2 { x: 10, y: 10 });

            // Access the world dispatcher for reading.
            let world = self.world_dispatcher.read();

            // Get the address of the current caller, possibly the player's address.
            let player = get_caller_address();

            let mut i: usize = 0;
            loop {
                if i == spawn_locations.len() {
                    break;
                }
                // check whether each of the coordinates is occupied
                let square = get!(world, (game_id, *spawn_locations.at(i)), Square);
                if square.piece == PieceType::None {
                    // if not occupied, spawn the player at that coordinate\
                    set!(
                        world,
                        (
                            Position { player, game_id, vec: square.vec },
                            Square { game_id: game_id, vec: square.vec, piece: PieceType::Player },
                        )
                    );
                    break;
                }
                i += 1;
            };

            // Update the world state with the new data.
            set!(
                world,
                (
                    HealthPoints { player, hp: 3 },
                    RangePoints { player, rp: 2 },
                    Alive { player, is_alive: true },
                    ActionPoints { player, ap: 3 },
                )
            );
        }

        // Implementation of the move function for the ContractState struct.
        fn move(self: @ContractState, direction: Direction, game_id: usize) {
            let world = self.world_dispatcher.read();
            let player = get_caller_address();

            // Retrieve the player's current position and moves data from the world.
            let mut position = get!(world, (player, game_id), Position);
            let mut action_points = get!(world, player, ActionPoints);

            // Calculate the player's next position based on the provided direction.
            let new_position = calc_next_position(position, direction);
            let new_action_points = action_points.ap - 1;

            // Update the world state with the new moves data and position.
            set!(
                world,
                (
                    Position { player, game_id, vec: new_position.vec },
                    ActionPoints { player, ap: new_action_points },
                    Square {
                        game_id: game_id, vec: position.vec, piece: PieceType::None
                    }, // old square
                    Square {
                        game_id: game_id, vec: new_position.vec, piece: PieceType::Player
                    }, // new square
                )
            );

            // Emit an event to the world to notify about the player's move.
            emit!(world, Moved { player, direction });
        }
    }
}

#[cfg(test)]
mod tests {
    use starknet::{class_hash::Felt252TryIntoClassHash, testing};
    use debug::PrintTrait;
    use dojo::world::{IWorldDispatcher, IWorldDispatcherTrait};
    use dojo::test_utils::{spawn_test_world, deploy_contract};
    use ascension::models::{position, moves, health_points, range_points, action_points, alive};
    use ascension::models::{
        Position, Moves, Direction, Vec2, GameSession, PieceType, Square, HealthPoints, RangePoints,
        ActionPoints, Alive
    };
    use super::{actions, IActionsDispatcher, IActionsDispatcherTrait};

    #[test]
    #[available_gas(3000000000000000)]
    fn test_spawn_game() {
        let caller = starknet::contract_address_const::<0x0>();
        let mut models = array![position::TEST_CLASS_HASH];
        let world = spawn_test_world(models);
        // deploy systems contract
        let contract_address = world
            .deploy_contract('salt', actions::TEST_CLASS_HASH.try_into().unwrap());
        let actions_system = IActionsDispatcher { contract_address };
        // spawn new game session
        actions_system.spawn_game(123456, 1699744590);
        // check the GameSession was created correctly
        let game_session = get!(world, 123456, GameSession);
        assert(game_session.start_time == 1699744590, 'start time is wrong');
        // Check a selection of cells to make sure their piece is None
        let square = get!(world, (123456, Vec2 { x: 0, y: 0 }), Square);
        assert(square.piece == PieceType::None, 'piece is wrong');
    }

    #[test]
    #[available_gas(3000000000000000)]
    fn test_spawn() {
        let caller = starknet::contract_address_const::<0x0>();
        let caller_2 = starknet::contract_address_const::<0x1>();
        let mut models = array![
            position::TEST_CLASS_HASH,
            health_points::TEST_CLASS_HASH,
            range_points::TEST_CLASS_HASH,
            alive::TEST_CLASS_HASH
        ];
        let world = spawn_test_world(models);
        // deploy systems contract
        let contract_address = world
            .deploy_contract('salt', actions::TEST_CLASS_HASH.try_into().unwrap());
        let actions_system = IActionsDispatcher { contract_address };

        let game_id = 123456;
        actions_system.spawn_game(game_id, 1699744590);

        // Spawn two different players then check their start positions are correct
        testing::set_contract_address(caller);
        actions_system.spawn(game_id);
        testing::set_contract_address(caller_2);
        actions_system.spawn(game_id);
        let position = get!(world, (caller, game_id), Position);
        assert(position.vec.x == 0, 'position x is wrong');
        assert(position.vec.y == 0, 'position y is wrong');
        let position = get!(world, (caller_2, game_id), Position);
        assert(position.vec.x == 0, 'position x is wrong');
        assert(position.vec.y == 5, 'position y is wrong');

        // check other player stats are initialised correctly
        let health_points = get!(world, caller, HealthPoints);
        assert(health_points.hp == 3, 'health points should equal 3');
        let range_points = get!(world, caller, RangePoints);
        assert(range_points.rp == 2, 'range points should equal 2');
        let alive = get!(world, caller, Alive);
        assert(alive.is_alive == true, 'alive should be true');
        let action_points = get!(world, caller, ActionPoints);
        assert(action_points.ap == 3, 'action points should equal 3');
    }

    #[test]
    #[available_gas(3000000000000000)]
    fn test_move() {
        // set up world
        let mut models = array![position::TEST_CLASS_HASH, moves::TEST_CLASS_HASH];
        let world = spawn_test_world(models);
        let contract_address = world
            .deploy_contract('salt', actions::TEST_CLASS_HASH.try_into().unwrap());
        let actions_system = IActionsDispatcher { contract_address };

        // spawn game and player
        let caller = starknet::contract_address_const::<0x0>();
        let game_id = 123456;
        actions_system.spawn_game(game_id, 1699744590);
        actions_system.spawn(game_id);

        let position = get!(world, (caller, game_id), Position);
        assert(position.vec.x == 0, 'position x is wrong');
        assert(position.vec.y == 0, 'position y is wrong');

        // player is at (0,0) so should not be able to move left
        actions_system.move(Direction::Left, game_id);
        let new_position = get!(world, (caller, game_id), Position);
        assert(new_position.vec.x == 0, 'position x is wrong');
        assert(new_position.vec.y == 0, 'position y is wrong');

        // call move with direction right and check new position
        actions_system.move(Direction::Right, game_id);
        let new_position = get!(world, (caller, game_id), Position);
        assert(new_position.vec.x == 1, 'position x is wrong');
        assert(new_position.vec.y == 0, 'position y is wrong');
    }
}
