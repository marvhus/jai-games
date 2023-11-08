WIDTH              :: 960;
HEIGHT             :: 720;
BALL_RADIUS        :: 0.020;
PADDLE_WIDTH       :: 0.025;
PADDLE_HEIGHT      :: 0.250;
PADDLE_OFFSET      :: 0.025;
PADDLE_SPEED       :: 1.200;
DEFAULT_BALL_SPEED :: 0.25;
MAX_BALL_SPEED     :: 2.0;
EPSILON            :: 0.0001;

State :: enum {
    IDLE;
    RUNNING;
}
Movable_Thing :: struct {
    using pos: Vector2;
    move_dir: Vector2;
    speed: float;
}
Game_Data :: struct {
    p1, p2, ball: Movable_Thing;
    state: State;
    p1_score: u32;
    p2_score: u32;
}

normalized_coordinate :: (decimal: float, size: s32) -> s32 {
    return xx (size * decimal);
}

draw :: (using data: Game_Data) {
    draw_player :: (position: Vector2) {
        DrawRectangle(
            normalized_coordinate(position.x - PADDLE_WIDTH  / 2, WIDTH),
            normalized_coordinate(position.y - PADDLE_HEIGHT / 2, HEIGHT),
            normalized_coordinate(PADDLE_WIDTH,  WIDTH),
            normalized_coordinate(PADDLE_HEIGHT, HEIGHT),
            WHITE
        );
    }

    BeginDrawing();
    defer EndDrawing();

    ClearBackground(BLACK);

    // Draw player paddles
    draw_player(p1.pos);
    draw_player(p2.pos);

    // Draw ball
    DrawRectangle(
        normalized_coordinate(ball.x - BALL_RADIUS / 2, WIDTH),
        normalized_coordinate(ball.y - BALL_RADIUS / 2, HEIGHT),
        normalized_coordinate(BALL_RADIUS, WIDTH),
        normalized_coordinate(BALL_RADIUS, WIDTH),
        WHITE
    );

    // Draw the score
    DrawText(to_c_string(tprint("%", p1_score)), 10, 10, 24, WHITE);
    DrawText(to_c_string(tprint("%", p2_score)), 10, 35, 24, WHITE);
}

update :: (using data: *Game_Data, dt: float) {
    if data.state == {
        case .IDLE;    update_idle(data, dt);
        case .RUNNING; update_running(data, dt);
    }
}
update_idle :: (using data: *Game_Data, dt: float) {
    if IsKeyPressed(KEY_SPACE) then state = .RUNNING;
}
update_running :: (using data: *Game_Data, dt: float) {
    update_player :: (using player: *Movable_Thing, dir: int, dt: float) {
        if dir == 0 {
            player.move_dir = .{0, 0};
            return;
        }
        move_dir.y = pos.y + dir * speed * dt;
        // Don't move player outside of the screen.
        if move_dir.y - PADDLE_HEIGHT / 2 <= 0 {
            pos.y = 0 + PADDLE_HEIGHT / 2;
            move_dir.y = 0;
        } else
        if move_dir.y + PADDLE_HEIGHT / 2 >= 1 {
            pos.y = 1 - PADDLE_HEIGHT / 2;
            move_dir.y = 0;
        } else {
            pos.y = move_dir.y;
        }
    }
    is_colliding :: (ball: Vector2, player: Vector2) -> bool {
        // Inverted not colliding check
        return !((player.x + PADDLE_WIDTH  / 2) < (ball.x - BALL_RADIUS / 2)
            ||   (player.x - PADDLE_WIDTH  / 2) > (ball.x + BALL_RADIUS / 2)
            ||   (player.y + PADDLE_HEIGHT / 2) < (ball.y - BALL_RADIUS / 2)
            ||   (player.y - PADDLE_HEIGHT / 2) > (ball.y + BALL_RADIUS / 2));
    }

    // Update player 1
    p1_dir := cast(int) IsKeyDown(KEY_S) - xx IsKeyDown(KEY_W);
    update_player(*p1, p1_dir, dt);

    // Update player 2
    p2_dir := cast(int) IsKeyDown(KEY_DOWN) - xx IsKeyDown(KEY_UP);
    update_player(*p2, p2_dir, dt);

    // Update Ball
    new_ball_pos := ball.pos + ball.move_dir * ball.speed * dt;
    if is_colliding(new_ball_pos, p1.pos) {
        // Check if collising with player 1
        ball.move_dir.x *= -1;
        ball.move_dir.y = p1.move_dir.y / 2 * -1;
        if ball.speed < MAX_BALL_SPEED - EPSILON {
            log("%\n", ball.speed);
            ball.speed *= 1.1;
            if ball.speed >= MAX_BALL_SPEED - EPSILON then ball.speed = MAX_BALL_SPEED;
        }
    } else
    if is_colliding(new_ball_pos, p2.pos) {
        // Check if colliding with player 2
        ball.move_dir.x *= -1;
        ball.move_dir.y = p2.move_dir.y / 2 * -1;
        if ball.speed < MAX_BALL_SPEED - EPSILON {
            log("%\n", ball.speed);
            ball.speed *= 1.1;
            if ball.speed >= MAX_BALL_SPEED - EPSILON then ball.speed = MAX_BALL_SPEED;
        }
    } else
    if new_ball_pos.y - BALL_RADIUS <= 0
    || new_ball_pos.y + BALL_RADIUS >= 1 {
        // Check if colliding with wall
        ball.move_dir.y *= -1;
    }
    // Now actually update the ball position (based on the checks above).
    ball.pos += ball.move_dir * ball.speed * dt;

    // I'mma just check here if a player scored and reset the state in case that happened.
    if ball.pos.x - BALL_RADIUS <= 0 {
        reset_state(data);
        p2_score += 1;
    } else
    if ball.pos.x + BALL_RADIUS >= 1 {
        reset_state(data);
        p1_score += 1;
    }
}

// Doesn't reset score for now
reset_state :: (using data: *Game_Data) {
    p1    = Movable_Thing.{Vector2.{0 + PADDLE_OFFSET, 0.5}, Vector2.{0, 0}, PADDLE_SPEED};
    p2    = Movable_Thing.{Vector2.{1 - PADDLE_OFFSET, 0.5}, Vector2.{0, 0}, PADDLE_SPEED};
    ball  = Movable_Thing.{Vector2.{0.5, 0.5}, Vector2.{1, 0}, DEFAULT_BALL_SPEED};
    state = .IDLE;
}

main :: () {
    SetConfigFlags(xx 0);
    InitWindow(WIDTH, HEIGHT, "pong");
    defer CloseWindow();
    SetTargetFPS(60);

    data: Game_Data;
    reset_state(*data);

    while !WindowShouldClose() {
        update(*data, GetFrameTime());
        draw(data);
        reset_temporary_storage();
    }
}

#import "Basic";
#import "Raylib";
#import "Math";
