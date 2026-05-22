function [add_id, best_res] = cover_select_add_law_(y_c, act_id_check, lawAx, lawBx, tol_query, tol_hit, model)

    nLaw = numel(lawAx);
    nxi  = model.nxi;

    add_id       = [];
    best_res     = inf;
    best_add_res = inf;
    cnt_hit      = 0;

    in_check = false(nLaw, 1);
    in_check(act_id_check) = true;

    if model.isBounded
        for i = 1:nLaw
            res = max(lawAx{i} * y_c - lawBx{i} - tol_query);

            if res < best_res
                best_res = res;
            end

            if res <= tol_hit
                cnt_hit = cnt_hit + 1;

                if ~in_check(i) && res < best_add_res
                    add_id       = i;
                    best_add_res = res;
                end
            end
        end
    else
        xi_c  = y_c(1:nxi);
        tau_c = y_c(end);

        for i = 1:nLaw
            res = max(lawAx{i} * xi_c - lawBx{i} * tau_c - tol_query);

            if res < best_res
                best_res = res;
            end

            if res <= tol_hit
                cnt_hit = cnt_hit + 1;

                if ~in_check(i) && res < best_add_res
                    add_id       = i;
                    best_add_res = res;
                end
            end
        end
    end

    if cnt_hit == 0
        error('cover_select_add_law_:NoFullHit', ...
            'No full law hits the MIP witness. best_res = %.3e.', best_res);
    end

    if isempty(add_id)
        error('cover_select_add_law_:NumericalConflict', ...
            'MIP witness is already covered by existing active laws. best_res=%.3e, tol_hit=%.3e.', best_res, tol_hit);
    end
end