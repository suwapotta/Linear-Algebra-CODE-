clc; clear;

% --- 1. USER INPUT ---
disp("Enter data as arrays (e.g., [20, 30, 25])");
supply = input("Supply array: ");
demand = input("Demand array: ");
cost = input("Cost Matrix (e.g., [8 6; 9 12]): ");

% --- 2. BALANCE THE PROBLEM ---
sum_s = sum(supply);
sum_d = sum(demand);

if sum_s > sum_d
    demand(end+1) = sum_s - sum_d;
    cost(:, end+1) = 0;
end

if sum_d > sum_s
    supply(end+1) = sum_d - sum_s;
    cost(end+1, :) = 0;
end

m = length(supply);
n = length(demand);
alloc = zeros(m, n);

% --- 3. NORTHWEST CORNER METHOD ---
i = 1; j = 1;
epsilon = 1e-6;

while i <= m && j <= n
    qty = min(supply(i), demand(j));

    if qty == 0
        alloc(i, j) = epsilon;
    end
    if qty > 0
        alloc(i, j) = qty;
    end

    supply(i) = supply(i) - qty;
    demand(j) = demand(j) - qty;

    if supply(i) == 0 && demand(j) == 0 && (i < m && j < n)
        i = i + 1;
        continue;
    end

    if supply(i) == 0
        i = i + 1;
        continue;
    end

    if demand(j) == 0
        j = j + 1;
        continue;
    end

    % Catch-all (should only trigger at the very end of the matrix)
    i = i + 1;
    j = j + 1;
end

% --- 4. MODI METHOD ---
iteration = 1;

while true
    % A. Calculate Potentials (u, v)
    u = NaN(m, 1);
    v = NaN(1, n);
    u(1) = 0;

    while any(isnan(u)) || any(isnan(v))
        for r = 1:m
            for c = 1:n
                if alloc(r, c) == 0
                    continue;
                end

                if ~isnan(u(r)) && isnan(v(c))
                    v(c) = cost(r, c) - u(r);
                end

                if isnan(u(r)) && ~isnan(v(c))
                    u(r) = cost(r, c) - v(c);
                end
            end
        end
    end

    % B. Calculate Reduced Costs (Deltas)
    deltas = cost - (u + v);
    deltas(alloc > 0) = inf;

    [min_delta, linear_idx] = min(deltas(:));
    [ent_i, ent_j] = ind2sub([m, n], linear_idx);

    % C. Optimality Check
    if min_delta >= -1e-9
        alloc(alloc == epsilon) = 0; % Clean up the dummy epsilons
        final_cost = sum(sum(alloc .* cost));

        printf("\n=> OPTIMAL SOLUTION REACHED in %d iterations!\n", iteration);
        printf("Final Minimum Cost: %d\n", final_cost);
        disp("Final Allocation Matrix:");
        disp(alloc);
        break;
    end

    % D. Loop Finding (Graph Trimming)
    loop_mask = (alloc > 0);
    loop_mask(ent_i, ent_j) = true;

    while true
        r_counts = sum(loop_mask, 2);
        c_counts = sum(loop_mask, 1);

        bad_rows = (r_counts == 1);
        bad_cols = (c_counts == 1);

        if ~any(bad_rows) && ~any(bad_cols)
            break;
        end

        loop_mask(bad_rows, :) = false;
        loop_mask(:, bad_cols) = false;
    end

    % E. Trace Path & Shift Allocations
    path_r = []; path_c = [];
    curr_r = ent_i; curr_c = ent_j;
    nodes_in_loop = nnz(loop_mask);

    for step = 1:nodes_in_loop
        path_r = [path_r; curr_r];
        path_c = [path_c; curr_c];
        loop_mask(curr_r, curr_c) = false;

        if mod(step, 2) == 1
            curr_c = find(loop_mask(curr_r, :), 1);
            continue;
        end

        if mod(step, 2) == 0
            curr_r = find(loop_mask(:, curr_c), 1);
        end
    end

    % Find the bottleneck value
    minus_idx = 2:2:length(path_r);
    lin_indices = sub2ind([m, n], path_r(minus_idx), path_c(minus_idx));
    shift_val = min(alloc(lin_indices));

    % Shift the values (+, -, +, -)
    for k = 1:length(path_r)
        if mod(k, 2) == 1
            alloc(path_r(k), path_c(k)) = alloc(path_r(k), path_c(k)) + shift_val;
            continue;
        end

        if mod(k, 2) == 0
            alloc(path_r(k), path_c(k)) = alloc(path_r(k), path_c(k)) - shift_val;
        end
    end

    iteration = iteration + 1;
end
