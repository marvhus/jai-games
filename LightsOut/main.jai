WIDTH         :s32: 960;
HEIGHT        :s32: 720;
SQUARE_WIDTH  :s32: WIDTH / 5;
SQUARE_HEIGHT :s32: HEIGHT / 5;
MARGIN        :s32: 5;

update :: (board: *Board, dt: float) {
    if IsMouseButtonPressed(MOUSE_BUTTON_LEFT) {
        click_pos := GetMousePosition();
        x := cast(u8) floor(click_pos.x / SQUARE_WIDTH);
        y := cast(u8) floor(click_pos.y / SQUARE_HEIGHT);
        toggle_around(board, x, y);
    }

    if IsKeyPressed(KEY_R) || IsMouseButtonPressed(MOUSE_BUTTON_RIGHT) {
        reset_board(board);
    }
}

draw :: (board: Board) {
    draw_square :: (x: s32, y: s32, state: bool) {
        DrawRectangle(
            SQUARE_WIDTH  * x + MARGIN / 2,
            SQUARE_HEIGHT * y + MARGIN / 2,
            SQUARE_WIDTH  - MARGIN,
            SQUARE_HEIGHT - MARGIN,
            ifx state then BLUE else WHITE
        );
    }

    BeginDrawing();
    defer EndDrawing();

    ClearBackground(BLACK);

    for y: 0..4 {
        for x: 0..4 {
            state := board_get(board, xx x, xx y);
            draw_square(cast(s32) x, cast(s32) y, state);
        }
    }
}

main :: () {
    SetConfigFlags(xx 0); // No flags
    InitWindow(WIDTH, HEIGHT, "Lights Out");
    defer CloseWindow();
    SetTargetFPS(60);

    board: Board;
    reset_board(*board);

    while !WindowShouldClose() {
        update(*board, GetFrameTime());
        draw(board);
        reset_temporary_storage();
    }
}

Board :: struct {
    data: u32;
}

board_get :: (board: Board, idx: u8) -> bool {
    val := (board.data >> idx) & 0b1;
    return val == 1;
}
board_get :: (board: Board, x: u8, y: u8) -> bool {
    idx := coord_to_idx(x, y);
    return board_get(board, idx);
}

toggle :: (board: *Board, idx: u8) {
    mask := cast(u32) 1 << idx;
    board.data = board.data ^ mask;
}
toggle :: (board: *Board, x: u8, y: u8) {
    idx := coord_to_idx(x, y);
    toggle(board, idx);
}
toggle_around :: (board: *Board, x: u8, y: u8) {
                  toggle(board, x,     y    );
    if y < 4 then toggle(board, x,     y + 1);
    if y > 0 then toggle(board, x,     y - 1);
    if x < 4 then toggle(board, x + 1, y    );
    if x > 0 then toggle(board, x - 1, y    );
}

reset_board :: (board: *Board) {
    // Make random actually random (pseudo random)
    now_ms :u64= xx to_milliseconds(current_time_consensus());
    random_seed(now_ms);

    moves := random_get() % 10 + 7;

    board.data = 0;
    toggled := Board.{0};
    // Do random moves from an empty board so that it's solvable.
    for 0..moves-1 {
        idx := cast(u8) (random_get() % 25);
        // Don't click a square twice.
        while board_get(toggled, idx) {
            idx += 1;
            idx %= 25;
        }
        toggle(*toggled, idx);
        x, y := idx_to_coord(idx);
        toggle_around(board, x, y);
    }
}

coord_to_idx :: (x: u8, y: u8) -> u8 {
    return y * 5 + x;
}
idx_to_coord :: (idx: u8) -> u8, u8 {
    x := idx % 5;
    y := idx / 5;
    return x, y;
}

normalized_coordinate :: (decimal: float, size: s32) -> s32 {
    return xx (size * decimal);
}

#import "Math";
#import "Basic";
#import "Random";
#import "Raylib";
