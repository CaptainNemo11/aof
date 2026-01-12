module day10 #(
    parameter int MAX_LIGHTS = 16,
    parameter int MAX_BUTTONS = 16
)(
    input logic clk,
    input logic rst,
    input logic start,
    input logic [$clog2(MAX_LIGHTS+1)-1:0] i_n_lights,
    input logic [$clog2(MAX_BUTTONS+1)-1:0] i_n_buttons,
    
    input logic [MAX_BUTTONS:0] i_matrix [MAX_LIGHTS],
    output logic [31:0] o_min_presses,
    output logic done
);

logic [MAX_BUTTONS:0] rows [MAX_LIGHTS];
logic [MAX_BUTTONS-1:0] is_pivot;
logic [$clog2(MAX_BUTTONS)-1:0] pivot_cols [MAX_BUTTONS];
logic [$clog2(MAX_BUTTONS):0] n_pivots;

logic [MAX_BUTTONS-1:0] x0;
logic [MAX_BUTTONS-1:0] nullspace [MAX_BUTTONS];
logic [$clog2(MAX_BUTTONS):0] n_free;

logic [MAX_BUTTONS-1:0] combination_mask;
logic [MAX_BUTTONS-1:0] current_sol;
logic [$clog2(MAX_BUTTONS+1)-1:0] min_weight;

logic [$clog2(MAX_BUTTONS):0] comp_idx;

enum logic[3:0] {
    IDLE,
    GAUSS_ELIM,
    INIT_X0,         
    COMPUTE_X0,
    BUILD_FREE_LIST,
    COMPUTE_BASIS,
    SEARCH_XOR,
    SEARCH_COUNT,
    DONE_STATE
} state;

logic [$clog2(MAX_BUTTONS):0] col;
logic [$clog2(MAX_LIGHTS):0] pivot_row, scan_row, elim_row, pivot;
logic pivot_found;
logic [MAX_BUTTONS:0] idx_mask;
logic [$clog2(MAX_BUTTONS)-1:0] free_cols [MAX_BUTTONS];

enum logic[2:0]{G_IDLE, G_PIVOT_INIT, G_FIND_PIVOT, G_SWAP, G_ELIM_INIT, G_ELIM_ROW, G_NEXT_COL, G_DONE} g_state;

assign  idx_mask = 1 << (i_n_buttons - col);


always_ff @(posedge clk or posedge rst) begin
    if (rst) begin
        state <= IDLE;
        o_min_presses <= 0;
        x0 <= 0;
        current_sol <= 0;
    end else begin
        case (state)
            IDLE: begin
                if (start) begin
                    for (int i = 0; i < MAX_LIGHTS; i++)
                        if(i < i_n_lights) begin
                            rows[i] <= i_matrix[i];
                        end else begin
                            rows[i] <=0;
                        end
                    
                    col <= 0;
                    pivot_row <= 0;
                    is_pivot <= 0;
                    n_pivots <= 0;
                    x0 <= 0;  
                    combination_mask <= 0;
                    n_free <= 0;

                    g_state <= G_PIVOT_INIT;
                    state <= GAUSS_ELIM;
                end
            end
            
            GAUSS_ELIM: begin
                case (g_state)
                    G_PIVOT_INIT: begin
                        pivot_found <= 0;
                        scan_row <= pivot_row;
                        g_state <= G_FIND_PIVOT;
                    end
                    
                    G_FIND_PIVOT: begin
                        if ((rows[scan_row] & idx_mask) && !pivot_found) begin
                            pivot_found <= 1;
                            pivot <= scan_row;
                            g_state <= G_SWAP;
                        end else if (scan_row >= i_n_lights - 1) begin
                            g_state <= G_NEXT_COL;
                        end else begin
                            scan_row <= scan_row + 1;
                        end
                    end
                    
                    G_SWAP: begin
                        if (pivot_row != pivot) begin
                            rows[pivot_row] <= rows[pivot];
                            rows[pivot] <= rows[pivot_row];
                        end
                        g_state <= G_ELIM_INIT;
                    end
                    
                    G_ELIM_INIT: begin
                        elim_row <= 0;
                        g_state <= G_ELIM_ROW;
                    end
                    
                    G_ELIM_ROW: begin
                        if (elim_row != pivot_row && (rows[elim_row] & idx_mask))
                            rows[elim_row] <= rows[elim_row] ^ rows[pivot_row];
                        
                        if (elim_row >= i_n_lights - 1)
                            g_state <= G_NEXT_COL;
                        else
                            elim_row <= elim_row + 1;
                    end
                    
                    G_NEXT_COL: begin
                        if (pivot_found) begin
                            is_pivot[col] <= 1;
                            pivot_cols[n_pivots] <= col;
                            n_pivots <= n_pivots + 1;
                            pivot_row <= pivot_row + 1;
                        end
                        
                        if (col >= i_n_buttons - 1) begin
                            g_state <= G_DONE;  
                        end else begin
                            col <= col + 1;
                            g_state <= G_PIVOT_INIT;
                        end
                    end
                    G_DONE: begin
                        comp_idx <= 0;
                        state <= INIT_X0;
                    end
                endcase
            end
            
            INIT_X0: begin
                x0 <= 0;
                comp_idx <= 0;
                state <= COMPUTE_X0;
            end
            
            COMPUTE_X0: begin
                if (comp_idx < n_pivots) begin
                    if (rows[comp_idx] & 1) begin
                        x0[i_n_buttons - 1 - pivot_cols[comp_idx]] <= 1;
                    end
                    comp_idx <= comp_idx + 1;
                end else begin
                    comp_idx <= 0;
                    n_free <= 0;
                    for (int i = 0; i < MAX_BUTTONS; i++)
                        nullspace[i] <= 0;
                    state <= BUILD_FREE_LIST;
                end
            end
            
            BUILD_FREE_LIST: begin
                if (comp_idx < i_n_buttons) begin
                    if (!is_pivot[comp_idx]) begin
                        nullspace[n_free] <= 1 << (i_n_buttons - 1 - comp_idx);
                        n_free <= n_free + 1;
                        free_cols[n_free] <= comp_idx;

                    end
                    comp_idx <= comp_idx + 1;
                end else begin
                    comp_idx <= 0;
                    state <= COMPUTE_BASIS;
                end
            end
            
            COMPUTE_BASIS: begin
                if (comp_idx < n_pivots) begin
                    for (int basis_idx = 0; basis_idx < MAX_BUTTONS; basis_idx++) begin
                        if (basis_idx < n_free) begin
                            if ((rows[comp_idx] >> (i_n_buttons - free_cols[basis_idx])) & 1'b1) begin
                                nullspace[basis_idx][i_n_buttons - 1 - pivot_cols[comp_idx]] <= 1;
                            end
                        end
                    end
                    comp_idx <= comp_idx + 1;
                end else begin
                    combination_mask <= 0;
                    min_weight <= MAX_BUTTONS;
                    comp_idx <= 0;
                    state <= SEARCH_XOR;
                end
            end
            
            SEARCH_XOR: begin
                if (comp_idx == 0) begin
                    current_sol <= x0;
                    comp_idx <= comp_idx + 1;
                end else if (comp_idx <= n_free) begin
                    if (combination_mask[comp_idx - 1]) begin
                        current_sol <= current_sol ^ nullspace[comp_idx - 1];
                    end
                    comp_idx <= comp_idx + 1;
                end else begin
                    state <= SEARCH_COUNT;
                end
            end
            
            SEARCH_COUNT: begin
                automatic logic [$clog2(MAX_BUTTONS+1)-1:0] weight;
                weight = 0;
                for (int i = 0; i < MAX_BUTTONS; i++) begin
                    if (i < i_n_buttons && current_sol[i])
                        weight = weight + 1;
                end
                
                if (weight < min_weight)
                    min_weight <= weight;
                
                if (combination_mask >= (1 << n_free)) begin
                    o_min_presses <= o_min_presses+ min_weight;
                    state <= DONE_STATE;
                end else begin
                    combination_mask <= combination_mask + 1;
                    comp_idx <= 0;
                    state <= SEARCH_XOR;
                end
            end
            
            DONE_STATE: begin
                state <= IDLE;
            end
        endcase
    end
end

assign done = (state == DONE_STATE);


endmodule