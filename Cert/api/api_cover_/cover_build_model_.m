function model = cover_build_model_(self, ops)
    [nxi, nu] = deal(self.nxi, self.nu);

    if self.sc.isBounded
        xi_s = sdpvar(nxi, 1);
        u_s  = sdpvar(nu, 1);
        y_s  = xi_s;

        Cs = self.S * xi_s + self.G * u_s <= self.b;

        ny = nxi;
        y_lb = zeros(ny, 1);
        y_ub = zeros(ny, 1);

        for j = 1:ny
            diag_lb = optimize(Cs, y_s(j), ops);
            if diag_lb.problem ~= 0
                error('cover_build_model_:BoundLB', 'Failed to compute bounded y_lb(%d). problem=%d, info=%s', j, diag_lb.problem, diag_lb.info);
            end
            y_lb(j) = value(y_s(j));

            diag_ub = optimize(Cs, -y_s(j), ops);
            if diag_ub.problem ~= 0
                error('cover_build_model_:BoundUB', 'Failed to compute bounded y_ub(%d). problem=%d, info=%s', j, diag_ub.problem, diag_ub.info);
            end
            y_ub(j) = value(y_s(j));
        end

        p = sdpvar(ny, 1);
        r = p' * y_s;
        opMaxRow = optimizer(Cs, -r, ops, p, r);

        model.isBounded = true;
        model.tag = 'CoverB';
        model.nxi = nxi;
        model.nu = nu;
        model.ny = ny;
        model.y_s = y_s;
        model.Cs = Cs;
        model.q = [];
        model.y_lb = y_lb;
        model.y_ub = y_ub;
        model.opMaxRow = opMaxRow;

        return;
    end

    %% ===== unbounded Xi: build slice from projected Xi, not from joint (xi,u) =====
    Pjoint = Polyhedron('A', [self.S, self.G], 'b', self.b);
    Pxi = Pjoint.projection(1:nxi).minHRep();

    if Pxi.isEmptySet
        error('cover_build_model_:EmptyXi', 'Projected Xi is empty.');
    end

    Axi = Pxi.A;
    bxi = Pxi.b(:);

    if isempty(Axi)
        error('cover_build_model_:FreeXi', 'Projected Xi has no H-representation rows. A compact normalized slice cannot be built.');
    end

    mxi = size(Axi, 1);

    gam = sdpvar(mxi, 1);
    mu = sdpvar(1, 1);
    alpha = sdpvar(1, 1);

    Cq = [
        gam >= alpha
        mu >= alpha
        alpha >= 0
        sum(gam) + mu == 1
    ];

    diag_q = optimize(Cq, -alpha, ops);

    if diag_q.problem ~= 0 || value(alpha) <= self.cfg.act.cover_slice_tol
        error('cover_build_model_:BadXiSlice', ...
            'Failed to compute a valid Xi-slice vector. problem=%d, info=%s, alpha=%.3e', ...
            diag_q.problem, diag_q.info, value(alpha));
    end

    q = [-Axi' * value(gam); bxi' * value(gam) + value(mu)];

    xi_s = sdpvar(nxi, 1);
    tau_s = sdpvar(1, 1);
    u_s = sdpvar(nu, 1);
    y_s = [xi_s; tau_s];

    Cs = [
        self.S * xi_s + self.G * u_s <= self.b * tau_s
        tau_s >= 0
        q' * y_s == 1
    ];

    ny = nxi + 1;
    y_lb = zeros(ny, 1);
    y_ub = zeros(ny, 1);

    for j = 1:ny
        diag_lb = optimize(Cs, y_s(j), ops);
        if diag_lb.problem ~= 0
            error('cover_build_model_:SliceLB', 'Failed to compute y_lb(%d). problem=%d, info=%s', j, diag_lb.problem, diag_lb.info);
        end
        y_lb(j) = value(y_s(j));

        diag_ub = optimize(Cs, -y_s(j), ops);
        if diag_ub.problem ~= 0
            error('cover_build_model_:SliceUB', 'Failed to compute y_ub(%d). problem=%d, info=%s', j, diag_ub.problem, diag_ub.info);
        end
        y_ub(j) = value(y_s(j));
    end

    if any(~isfinite(y_lb)) || any(~isfinite(y_ub))
        error('cover_build_model_:UnboundedSlice', 'The normalized Xi-slice is not bounded. Xi may contain lineality.');
    end

    p = sdpvar(ny, 1);
    r = p' * y_s;
    opMaxRow = optimizer(Cs, -r, ops, p, r);

    model.isBounded = false;
    model.tag = 'CoverU';
    model.nxi = nxi;
    model.nu = nu;
    model.ny = ny;
    model.y_s = y_s;
    model.Cs = Cs;
    model.q = q;
    model.y_lb = y_lb;
    model.y_ub = y_ub;
    model.opMaxRow = opMaxRow;
end