use ascension::models::{Position, Direction};

fn calc_next_position(mut position: Position, direction: Direction) -> Position {
    match direction {
        Direction::None(()) => { position },
        Direction::Left(()) => {
            assert(position.vec.x > 0_u32, 'Cannot move off the board');
            position.vec.x -= 1;
            position
        },
        Direction::Right(()) => {
            assert(position.vec.x < 10_u32, 'Cannot move off the board');
            position.vec.x += 1;
            position
        },
        Direction::Up(()) => {
            assert(position.vec.y > 0_u32, 'Cannot move off the board');
            position.vec.y -= 1;
            position
        },
        Direction::Down(()) => {
            assert(position.vec.y < 10_u32, 'Cannot move off the board');
            position.vec.y += 1;
            position
        },
    }
}
