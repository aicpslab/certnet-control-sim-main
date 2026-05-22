classdef Cert < handle
    properties
        %% ===== internal scaled hard-constraint model =====
        G
        S
        b
        sc

        %% ===== dimensions =====
        nxi
        nu
        neta

        %% ===== configuration =====
        cfg
        cfg_net

        %% ===== certified library and coverage state =====
        law
        R
        act_id = []
        cover_status = ''

        %% ===== packed deployment data =====
        deploy = struct()

        %% ===== neural proposer =====
        net = []
        net_hist = []

        %% ===== MEX runtime =====
        mex_ready = false
        mex_id = []
    end

    methods
        function self = Cert(G, b, S, X, Y, cfg, cfg_net)
            %% ===== empty constructor =====
            if nargin == 0
                return;
            end

            %% ===== default options =====
            if nargin < 6 || isempty(cfg)
                cfg = struct();
            end

            if nargin < 7 || isempty(cfg_net)
                cfg_net = struct();
            end

            %% ===== configuration and scaled problem construction =====
            api_set_cfg_(self, G, b, S, X, Y, cfg);
            self.cfg_net = api_set_cfg_net_(cfg_net);

            api_build_(self, G, b, S, X, Y, self.cfg);

            %% ===== full certified affine-law library =====
            api_build_law_(self);

            %% ===== scale training data =====
            Xs = X;
            Xs(1:self.nxi, :) = self.sc.forward_xi(X(1:self.nxi, :));

            if self.neta > 0
                ie = self.nxi + (1:self.neta);
                Xs(ie, :) = self.sc.forward_eta(X(ie, :));
            end

            Ys = self.sc.forward_u(Y);

            %% ===== active-library construction and coverage completion =====
            [act_id, ~] = api_build_active_id_(self, Xs, Ys);
            [act_id, cover_status] = api_complete_active_id_cover_xi_(self, act_id, Xs);

            self.act_id = act_id;
            self.cover_status = cover_status;

            %% ===== neural proposer training =====
            [self.net, hist] = api_train_(self, Xs, Ys);
            self.net_hist = hist;

            %% ===== MEX deployment =====
            api_build_mex_(self);
        end


        function [u, info] = cert_forward(self, xi, eta)
            %% ===== default auxiliary input =====
            if nargin < 3
                eta = [];
            end

            %% ===== initialize MEX runtime if needed =====
            if ~self.mex_ready
                api_build_mex_(self);
            end

            %% ===== scale input =====
            xi_s = self.sc.forward_xi(xi);
            xi_s = double(xi_s(:));

            if self.neta > 0
                eta_s = self.sc.forward_eta(eta);
                eta_s = double(eta_s(:));

                if nargout > 1
                    [u_s, info] = cert_policy_mex('eval', self.mex_id, xi_s, eta_s);
                else
                    u_s = cert_policy_mex('eval', self.mex_id, xi_s, eta_s);
                end
            else
                if nargout > 1
                    [u_s, info] = cert_policy_mex('eval', self.mex_id, xi_s);
                else
                    u_s = cert_policy_mex('eval', self.mex_id, xi_s);
                end
            end

            %% ===== unscale output =====
            u = self.sc.backward_u(u_s);
        end


        function clear_mex(self)
            %% ===== release persistent MEX runtime =====
            if self.mex_ready
                cert_policy_mex('clear', self.mex_id);

                self.mex_ready = false;
                self.mex_id = [];
            end
        end


        function delete(self)
            %% ===== destructor =====
            self.clear_mex();
        end
    end
end