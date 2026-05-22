function [status, y_c, problem, post_res] = cover_solve_mip_(act_id, row_id, M_id, lawAx, lawBx, tol_query, tol_sep, post_factor, ops, model)

    y = model.y_s;

    C = [
        model.Cs
        y >= model.y_lb
        y <= model.y_ub
    ];

    y_c = [];
    post_res = inf;

    for k = 1:numel(act_id)
        I = act_id(k);
        rows = row_id{k};
        M = M_id{k};

        if isempty(rows)
            status = 'certified';
            problem = 1;
            return;
        end

        nk = numel(rows);

        if model.isBounded
            A = lawAx{I}(rows, :);
            d = lawBx{I}(rows) + tol_query;
        else
            A = [lawAx{I}(rows, :), -lawBx{I}(rows)];
            d = tol_query * ones(nk, 1);
        end

        if nk == 1
            C = [C, A * y - d >= tol_sep];
        else
            z = binvar(nk, 1);
            C = [C, sum(z) == 1, A * y - d >= tol_sep - M .* (1 - z)];
        end
    end

    diagnostics = optimize(C, [], ops);

    problem = diagnostics.problem;

    if problem == 1
        status = 'certified';
        return;
    end

    info_low = lower(diagnostics.info);

    if problem == 3 || contains(info_low, 'time') || contains(info_low, 'limit') || contains(info_low, 'maximum')
        status = 'timeout';
        return;
    end

    if problem ~= 0
        status = 'failed';
        return;
    end

    y_c = value(y);

    for k = 1:numel(act_id)
        I = act_id(k);

        if model.isBounded
            res = max(lawAx{I} * y_c - lawBx{I} - tol_query);
        else
            res = max(lawAx{I} * y_c(1:model.nxi) - lawBx{I} * y_c(end) - tol_query);
        end

        post_res = min(post_res, res);
    end

    if post_res >= post_factor * tol_sep
        status = 'witness';
    else
        status = 'false_witness';
        y_c = [];
    end
end