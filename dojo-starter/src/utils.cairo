use ascension::models::{Position, Direction};

fn calc_next_position(mut position: Position, direction: Direction) -> Position {
    match direction {
        Direction::None(()) => { position },
        Direction::Left(()) => {
            if (position.vec.x > 0) {
                position.vec.x -= 1;
            }
            position
        },
        Direction::Right(()) => {
            if (position.vec.x < 10) {
                position.vec.x += 1;
            }
            position
        },
        Direction::Up(()) => {
            if (position.vec.y > 0) {
                position.vec.y -= 1;
            }
            position
        },
        Direction::Down(()) => {
            if (position.vec.y < 10) {
                position.vec.y += 1;
            }
            position
        },
    }
}
