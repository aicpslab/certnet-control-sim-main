function act_id_check = cover_reduce_active_by_data_(act_id, X, lawAx, lawBx, tol_query, ops)
    nact = numel(act_id);
    N = size(X, 2);
    H = false(N, nact);

    for k = 1:nact
        I = act_id(k);
        H(:, k) = all(lawAx{I} * X <= lawBx{I} + tol_query, 1).';
    end

    z = binvar(nact, 1);
    diag_reduce = optimize(sparse(double(H)) * z >= 1, sum(z), ops);

    if diag_reduce.problem ~= 0
        error('api_complete_active_id_cover_xi_:ReduceFailed', 'Initial set-cover MIP failed. problem=%d, info=%s', diag_reduce.problem, diag_reduce.info);
    end

    act_id_check = act_id(value(z) > 0.5);
end