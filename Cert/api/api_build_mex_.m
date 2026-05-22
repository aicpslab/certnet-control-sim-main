function api_build_mex_(self)
% api_build_mex_
%
% Build persistent MEX runtime for the complete certified policy.
%
% Online MEX path:
%   scaled xi, eta
%     -> network forward
%     -> active-law query
%     -> optional fallback-law query
%     -> softmax executor
%     -> scaled u
%
% Scaling convention:
%   MATLAB boundary handles physical <-> scaled coordinates.
%   MEX receives scaled inputs and returns scaled output.
%
% Writes:
%   self.deploy
%   self.mex_id
%   self.mex_ready

    if self.mex_ready
        cert_policy_mex('clear', self.mex_id);
        self.mex_ready = false;
        self.mex_id = [];
    end

    self.deploy = local_make_deploy_(self);

    self.mex_id = cert_policy_mex('init', self.deploy);
    self.mex_ready = true;
end


%% ========================================================================
%  Make deploy package
% =========================================================================
function deploy = local_make_deploy_(self)

    deploy = struct();

    deploy.nxi  = self.nxi;
    deploy.neta = self.neta;
    deploy.nx   = self.nxi + self.neta;
    deploy.nu   = self.nu;

    if isempty(self.R)
        deploy.nR = 0;
    else
        deploy.nR = size(self.R, 2);
    end

    status = char(self.cover_status);

    if isempty(status)
        status = 'unknown';
    end

    cover_certified = strcmp(status, 'certified');
    cover_use_fallback = ~cover_certified && self.cfg.act.use_fallback_on_timeout;

    deploy.cover = struct();
    deploy.cover.status = status;
    deploy.cover.certified = double(cover_certified);
    deploy.cover.use_fallback = double(cover_use_fallback);

    if cover_use_fallback
        fallback_id = setdiff(1:numel(self.law), self.act_id, 'stable');
    else
        fallback_id = [];
    end

    deploy.query = local_pack_query_(self);
    deploy.geom = local_pack_geom_(self, self.act_id);
    deploy.fallback_geom = local_pack_geom_(self, fallback_id);
    deploy.net = local_pack_net_(self);
    deploy.R = local_pack_R_(self);
end


%% ========================================================================
%  Query parameters
% =========================================================================
function query = local_pack_query_(self)

    query = struct();

    query.tol_query = double(self.cfg.act.tol_query);
    query.nThread = double(self.cfg.query.nThread);
    query.parallel_threshold = double(self.cfg.query.parallel_threshold);
end


%% ========================================================================
%  Geometry package
% =========================================================================
function geom = local_pack_geom_(self, act_id)

    law = self.law;
    act_id = act_id(:).';

    nAct = numel(act_id);
    nxi  = self.nxi;
    nu   = self.nu;

    nRow = zeros(nAct, 1);

    for k = 1:nAct
        I = act_id(k);
        nRow(k) = size(law{I}.Ax, 1);
    end

    rowPtr = zeros(nAct + 1, 1);
    rowPtr(1) = 1;

    for k = 1:nAct
        rowPtr(k + 1) = rowPtr(k) + nRow(k);
    end

    totalRow = rowPtr(end) - 1;

    A_data = zeros(totalRow, nxi);
    b_data = zeros(totalRow, 1);

    M_data = zeros(nAct, nu, nxi);
    c_data = zeros(nAct, nu);

    for k = 1:nAct
        I = act_id(k);

        r0 = rowPtr(k);
        r1 = rowPtr(k + 1) - 1;

        A_data(r0:r1, :) = double(law{I}.Ax);
        b_data(r0:r1) = double(law{I}.bx(:));

        M_data(k, :, :) = double(law{I}.M);
        c_data(k, :) = double(law{I}.b(:)).';
    end

    geom = struct();

    geom.nAct = double(nAct);
    geom.nRow = double(nRow);
    geom.rowPtr = double(rowPtr);

    geom.A_data = double(A_data);
    geom.b_data = double(b_data);

    geom.M_data = double(M_data);
    geom.c_data = double(c_data);

    geom.act_id = double(act_id(:));
end


%% ========================================================================
%  R package
% =========================================================================
function R = local_pack_R_(self)

    if isempty(self.R)
        R = zeros(self.nu, 0);
    else
        R = double(self.R);
    end
end


%% ========================================================================
%  Network package
% =========================================================================
function netp = local_pack_net_(self)

    net = self.net;
    cfg = self.cfg_net;

    hidden = cfg.hidden(:).';
    nLayer = numel(hidden);

    if isempty(self.R)
        nR = 0;
    else
        nR = size(self.R, 2);
    end

    netp = struct();

    netp.nLayer = double(nLayer);
    netp.hidden = double(hidden(:));
    netp.activation = char(cfg.activation);
    netp.g_min = double(cfg.g_min);

    netp.W = cell(nLayer, 1);
    netp.b = cell(nLayer, 1);

    for i = 1:nLayer
        fc_name = ['fc' num2str(i)];

        W = local_get_learnable_(net, fc_name, 'Weights');
        b = local_get_learnable_(net, fc_name, 'Bias');

        netp.W{i} = double(W);
        netp.b{i} = double(b(:));
    end

    %% ===== tbar head =====
    W_tbar = local_get_learnable_(net, 'fc_tbar', 'Weights');
    b_tbar = local_get_learnable_(net, 'fc_tbar', 'Bias');

    netp.W_tbar = double(W_tbar);
    netp.b_tbar = double(b_tbar(:));

    %% ===== g head =====
    W_g = local_get_learnable_(net, 'fc_g', 'Weights');
    b_g = local_get_learnable_(net, 'fc_g', 'Bias');

    netp.W_g = double(W_g);
    netp.b_g = double(b_g(:));

    %% ===== rho head =====
    if nR > 0
        W_rho = local_get_learnable_(net, 'fc_rho', 'Weights');
        b_rho = local_get_learnable_(net, 'fc_rho', 'Bias');

        netp.W_rho = double(W_rho);
        netp.b_rho = double(b_rho(:));
    else
        netp.W_rho = zeros(0, 0);
        netp.b_rho = zeros(0, 1);
    end
end


%% ========================================================================
%  Read dlnetwork learnable parameter
% =========================================================================
function val = local_get_learnable_(net, layer_name, param_name)

    T = net.Learnables;

    layer_name = string(layer_name);
    param_name = string(param_name);

    idx = find(T.Layer == layer_name & T.Parameter == param_name, 1);

    val = T.Value{idx};
    val = gather(extractdata(val));
end