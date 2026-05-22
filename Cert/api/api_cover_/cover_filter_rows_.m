function [row_id, M_id] = cover_filter_rows_(act_id, lawAx, lawBx, tol_query, tol_sep, bigM_guard, model)
    row_id = cell(numel(act_id), 1);
    M_id = cell(numel(act_id), 1);

    for k = 1:numel(act_id)
        I = act_id(k);

        if model.isBounded
            A = lawAx{I};
            d = lawBx{I} + tol_query;
        else
            A = [lawAx{I}, -lawBx{I}];
            d = tol_query * ones(size(A, 1), 1);
        end

        mk = size(A, 1);
        rows = zeros(mk, 1);
        M = zeros(mk, 1);
        cnt = 0;

        for ell = 1:mk
            a = A(ell, :).';
            U = model.opMaxRow{a} - d(ell);

            if U <= tol_sep
                continue;
            end

            L = -model.opMaxRow{-a} - d(ell);

            cnt = cnt + 1;
            rows(cnt) = ell;
            M(cnt) = max(tol_sep - L, 0) + bigM_guard;
        end

        row_id{k} = rows(1:cnt);
        M_id{k} = M(1:cnt);
    end
end